import {spawnSync} from 'node:child_process';
import {promises as fs} from 'node:fs';
import path from 'node:path';

const repoRoot = '/Users/xjodoin/git';
const dartdiffRoot = path.join(repoRoot, 'dartdiff');
const jsdiffRoot = path.join(repoRoot, 'jsdiff');
const tmpRoot = path.join(dartdiffRoot, '.parity-js');

async function ensureJsdiffBuilt() {
  const libesmIndex = path.join(jsdiffRoot, 'libesm', 'index.js');
  try {
    await fs.access(libesmIndex);
    return;
  } catch (_) {
    // continue
  }

  runOrThrow('corepack', ['prepare', 'yarn@4.12.0', '--activate']);
  runOrThrow('yarn', ['install'], {cwd: jsdiffRoot});
  runOrThrow('yarn', ['generate-esm'], {cwd: jsdiffRoot});
}

function runOrThrow(cmd, args, options = {}) {
  const result = spawnSync(cmd, args, {
    encoding: 'utf8',
    stdio: 'pipe',
    ...options,
  });

  if (result.status !== 0) {
    throw new Error(
      `${cmd} ${args.join(' ')} failed\nstdout:\n${result.stdout}\nstderr:\n${result.stderr}`,
    );
  }

  return result;
}

async function prepareTempWorkspace() {
  await fs.rm(tmpRoot, {recursive: true, force: true});
  await fs.mkdir(tmpRoot, {recursive: true});

  await fs.cp(path.join(jsdiffRoot, 'test'), path.join(tmpRoot, 'test'), {recursive: true});

  await fs.writeFile(
    path.join(tmpRoot, 'package.json'),
    JSON.stringify({name: 'parity-jsdiff-tests', type: 'module'}, null, 2),
  );

  const nodeModulesLink = path.join(tmpRoot, 'node_modules');
  try {
    await fs.symlink(path.join(jsdiffRoot, 'node_modules'), nodeModulesLink, 'junction');
  } catch (_) {
    // best effort
  }

  const indexTestPath = path.join(tmpRoot, 'test', 'index.js');
  let indexTest = await fs.readFile(indexTestPath, 'utf8');
  indexTest = indexTest.replace("from 'diff'", "from '../libesm/index.js'");
  await fs.writeFile(indexTestPath, indexTest);

  const patchCreatePath = path.join(tmpRoot, 'test', 'patch', 'create.js');
  let patchCreate = await fs.readFile(patchCreatePath, 'utf8');
  patchCreate = patchCreate.replace("from 'diff'", "from '../../libesm/diff/word.js'");
  await fs.writeFile(patchCreatePath, patchCreate);
}

async function writeWrappers() {
  const base = path.join(tmpRoot, 'libesm');

  const files = {
    '_bridge_helper.js': `
import {spawnSync} from 'node:child_process';
import {writeFileSync} from 'node:fs';
import {isDeepStrictEqual} from 'node:util';

const bridgePath = ${JSON.stringify(path.join(dartdiffRoot, 'tool', 'parity', 'dart_bridge.dart'))};

let compared = 0;
let skipped = 0;
let captured = 0;
let captureSkipped = 0;
const captureOut = process.env.DARTDIFF_CAPTURE_OUT ?? '';
const compareFns = new Set(
  (process.env.DARTDIFF_COMPARE_FUNCS ?? '')
    .split(',')
    .map((v) => v.trim())
    .filter(Boolean),
);

function hasFunction(value, seen = new Set()) {
  if (typeof value === 'function') return true;
  if (!value || typeof value !== 'object') return false;
  if (seen.has(value)) return false;
  seen.add(value);

  if (Array.isArray(value)) {
    return value.some((item) => hasFunction(item, seen));
  }

  return Object.values(value).some((item) => hasFunction(item, seen));
}

function isCircular(value, seen = new Set()) {
  if (!value || typeof value !== 'object') return false;
  if (seen.has(value)) return true;
  seen.add(value);

  if (Array.isArray(value)) {
    return value.some((item) => isCircular(item, seen));
  }

  return Object.values(value).some((item) => isCircular(item, seen));
}

function canonical(value) {
  if (value === undefined || value === null) return null;
  if (Array.isArray(value)) return value.map(canonical);
  if (value && typeof value === 'object') {
    const out = {};
    for (const [key, val] of Object.entries(value)) {
      const c = canonical(val);
      if (c !== null) out[key] = c;
    }
    return out;
  }
  return value;
}

function normalize(fnName, value) {
  if (fnName === 'applyPatch' && value === false) {
    return null;
  }
  return canonical(value);
}

function shouldSkip(fnName, args, options = {}) {
  if (options.alwaysSkip) return true;
  if (fnName === 'canonicalize' || fnName === 'applyPatches') return true;
  if (hasFunction(args)) return true;
  if (isCircular(args)) return true;

  const maybeOptions = args.find((arg) => arg && typeof arg === 'object' && !Array.isArray(arg));
  if (maybeOptions) {
    if (Object.prototype.hasOwnProperty.call(maybeOptions, 'callback')) return true;
    if (Object.prototype.hasOwnProperty.call(maybeOptions, 'comparator')) return true;
    if (Object.prototype.hasOwnProperty.call(maybeOptions, 'compareLine')) return true;
    if (Object.prototype.hasOwnProperty.call(maybeOptions, 'intlSegmenter')) return true;
    if (Object.prototype.hasOwnProperty.call(maybeOptions, 'stringifyReplacer')) return true;
  }

  return false;
}

function shouldCompare(fnName) {
  if (compareFns.size === 0) return false;
  return compareFns.has(fnName);
}

export function compareCall(fnName, args, jsResult, options = {}) {
  const skip = shouldSkip(fnName, args, options);
  if (captureOut) {
    if (skip) {
      captureSkipped += 1;
    } else {
      captured += 1;
      _capturedCalls.push({
        fn: fnName,
        args: canonical(args),
        expected: normalize(fnName, jsResult),
      });
    }
  }

  if (skip || !shouldCompare(fnName)) {
    skipped += 1;
    return;
  }

  const payload = JSON.stringify({fn: fnName, args});
  const proc = spawnSync('dart', ['run', bridgePath], {
    input: payload,
    encoding: 'utf8',
    maxBuffer: 20 * 1024 * 1024,
  });

  if (proc.status !== 0) {
    throw new Error(
      '[bridge process failed] ' + fnName + '\\n' +
      'stdout:\\n' + proc.stdout + '\\n' +
      'stderr:\\n' + proc.stderr,
    );
  }

  let response;
  try {
    response = JSON.parse(proc.stdout || '{}');
  } catch (err) {
    throw new Error('[bridge parse failed] ' + fnName + '\\n' + String(err) + '\\nraw:\\n' + proc.stdout);
  }

  if (!response.ok) {
    throw new Error('[bridge error] ' + fnName + '\\n' + response.error + '\\n' + (response.stack ?? ''));
  }

  const expected = normalize(fnName, jsResult);
  const actual = normalize(fnName, response.result);

  if (!isDeepStrictEqual(actual, expected)) {
    throw new Error(
      '[parity mismatch] ' + fnName + '\\n' +
      'args=' + JSON.stringify(canonical(args)) + '\\n' +
      'js=' + JSON.stringify(expected) + '\\n' +
      'dart=' + JSON.stringify(actual),
    );
  }

  compared += 1;
}

export function wrap(fnName, fn, options = {}) {
  return function wrapped(...args) {
    const jsResult = fn(...args);
    compareCall(fnName, args, jsResult, options);
    return jsResult;
  };
}

const _capturedCalls = [];

process.on('exit', () => {
  if (captureOut) {
    writeFileSync(captureOut, JSON.stringify({cases: _capturedCalls}, null, 2));
  }
  console.log('[parity] compared=' + compared + ' skipped=' + skipped);
  if (captureOut) {
    console.log('[capture] recorded=' + captured + ' skipped=' + captureSkipped + ' out=' + captureOut);
  }
});
`,

    'index.js': `export * from ${JSON.stringify(path.join(jsdiffRoot, 'libesm', 'index.js'))};\n`,

    'convert/dmp.js': `
import * as orig from ${JSON.stringify(path.join(jsdiffRoot, 'libesm', 'convert', 'dmp.js'))};
import {wrap} from '../_bridge_helper.js';

export const convertChangesToDMP = wrap('convertChangesToDMP', orig.convertChangesToDMP);
`,

    'convert/xml.js': `
import * as orig from ${JSON.stringify(path.join(jsdiffRoot, 'libesm', 'convert', 'xml.js'))};
import {wrap} from '../_bridge_helper.js';

export const convertChangesToXML = wrap('convertChangesToXML', orig.convertChangesToXML);
`,

    'diff/character.js': `
import * as orig from ${JSON.stringify(path.join(jsdiffRoot, 'libesm', 'diff', 'character.js'))};
import {wrap} from '../_bridge_helper.js';

export const characterDiff = orig.characterDiff;
export const diffChars = wrap('diffChars', orig.diffChars);
`,

    'diff/array.js': `
import * as orig from ${JSON.stringify(path.join(jsdiffRoot, 'libesm', 'diff', 'array.js'))};
import {wrap} from '../_bridge_helper.js';

export const arrayDiff = orig.arrayDiff;
export const diffArrays = wrap('diffArrays', orig.diffArrays);
`,

    'diff/css.js': `
import * as orig from ${JSON.stringify(path.join(jsdiffRoot, 'libesm', 'diff', 'css.js'))};
import {wrap} from '../_bridge_helper.js';

export const cssDiff = orig.cssDiff;
export const diffCss = wrap('diffCss', orig.diffCss);
`,

    'diff/line.js': `
import * as orig from ${JSON.stringify(path.join(jsdiffRoot, 'libesm', 'diff', 'line.js'))};
import {wrap} from '../_bridge_helper.js';

export const lineDiff = orig.lineDiff;
export const diffLines = wrap('diffLines', orig.diffLines);
export const diffTrimmedLines = wrap('diffTrimmedLines', orig.diffTrimmedLines);
`,

    'diff/sentence.js': `
import * as orig from ${JSON.stringify(path.join(jsdiffRoot, 'libesm', 'diff', 'sentence.js'))};
import {wrap, compareCall} from '../_bridge_helper.js';

export const sentenceDiff = new Proxy(orig.sentenceDiff, {
  get(target, prop, receiver) {
    if (prop === 'tokenize') {
      return (value, options) => {
        const jsResult = target.tokenize(value, options);
        compareCall('sentenceDiff.tokenize', [value, options], jsResult);
        return jsResult;
      };
    }
    return Reflect.get(target, prop, receiver);
  },
});

export const diffSentences = wrap('diffSentences', orig.diffSentences);
`,

    'diff/word.js': `
import * as orig from ${JSON.stringify(path.join(jsdiffRoot, 'libesm', 'diff', 'word.js'))};
import {wrap, compareCall} from '../_bridge_helper.js';

export const wordDiff = new Proxy(orig.wordDiff, {
  get(target, prop, receiver) {
    if (prop === 'tokenize') {
      return (value, options) => {
        const jsResult = target.tokenize(value, options);
        compareCall('wordDiff.tokenize', [value, options], jsResult);
        return jsResult;
      };
    }
    return Reflect.get(target, prop, receiver);
  },
});

export const wordsWithSpaceDiff = orig.wordsWithSpaceDiff;
export const diffWords = wrap('diffWords', orig.diffWords);
export const diffWordsWithSpace = wrap('diffWordsWithSpace', orig.diffWordsWithSpace);
`,

    'diff/json.js': `
import * as orig from ${JSON.stringify(path.join(jsdiffRoot, 'libesm', 'diff', 'json.js'))};
import {wrap} from '../_bridge_helper.js';

export const jsonDiff = orig.jsonDiff;
export const diffJson = wrap('diffJson', orig.diffJson);
export const canonicalize = wrap('canonicalize', orig.canonicalize, {alwaysSkip: true});
`,

    'patch/create.js': `
import * as orig from ${JSON.stringify(path.join(jsdiffRoot, 'libesm', 'patch', 'create.js'))};
import {wrap} from '../_bridge_helper.js';

export const INCLUDE_HEADERS = orig.INCLUDE_HEADERS;
export const FILE_HEADERS_ONLY = orig.FILE_HEADERS_ONLY;
export const OMIT_HEADERS = orig.OMIT_HEADERS;

export const structuredPatch = wrap('structuredPatch', orig.structuredPatch);
export const createTwoFilesPatch = wrap('createTwoFilesPatch', orig.createTwoFilesPatch);
export const createPatch = wrap('createPatch', orig.createPatch);
export const formatPatch = wrap('formatPatch', orig.formatPatch);
`,

    'patch/parse.js': `
import * as orig from ${JSON.stringify(path.join(jsdiffRoot, 'libesm', 'patch', 'parse.js'))};
import {wrap} from '../_bridge_helper.js';

export const parsePatch = wrap('parsePatch', orig.parsePatch);
`,

    'patch/reverse.js': `
import * as orig from ${JSON.stringify(path.join(jsdiffRoot, 'libesm', 'patch', 'reverse.js'))};
import {wrap} from '../_bridge_helper.js';

export const reversePatch = wrap('reversePatch', orig.reversePatch);
`,

    'patch/line-endings.js': `
import * as orig from ${JSON.stringify(path.join(jsdiffRoot, 'libesm', 'patch', 'line-endings.js'))};
import {wrap} from '../_bridge_helper.js';

export const unixToWin = wrap('unixToWin', orig.unixToWin);
export const winToUnix = wrap('winToUnix', orig.winToUnix);
export const isUnix = wrap('isUnix', orig.isUnix);
export const isWin = wrap('isWin', orig.isWin);
`,

    'patch/apply.js': `
import * as orig from ${JSON.stringify(path.join(jsdiffRoot, 'libesm', 'patch', 'apply.js'))};
import {wrap} from '../_bridge_helper.js';

export const applyPatch = wrap('applyPatch', orig.applyPatch);
export const applyPatches = wrap('applyPatches', orig.applyPatches, {alwaysSkip: true});
`,

    'util/string.js': `
import * as orig from ${JSON.stringify(path.join(jsdiffRoot, 'libesm', 'util', 'string.js'))};
import {wrap} from '../_bridge_helper.js';

export const longestCommonPrefix = wrap('longestCommonPrefix', orig.longestCommonPrefix);
export const longestCommonSuffix = wrap('longestCommonSuffix', orig.longestCommonSuffix);
export const replacePrefix = wrap('replacePrefix', orig.replacePrefix);
export const replaceSuffix = wrap('replaceSuffix', orig.replaceSuffix);
export const removePrefix = wrap('removePrefix', orig.removePrefix);
export const removeSuffix = wrap('removeSuffix', orig.removeSuffix);
export const maximumOverlap = wrap('maximumOverlap', orig.maximumOverlap);
export const leadingWs = wrap('leadingWs', orig.leadingWs);
export const trailingWs = wrap('trailingWs', orig.trailingWs);
`,
  };

  for (const [relativePath, content] of Object.entries(files)) {
    const absPath = path.join(base, relativePath);
    await fs.mkdir(path.dirname(absPath), {recursive: true});
    await fs.writeFile(absPath, content.trimStart());
  }
}

async function runMocha() {
  const mochaBin = path.join(jsdiffRoot, 'node_modules', 'mocha', 'bin', 'mocha.js');
  const result = spawnSync('node', [mochaBin, '--timeout', '30000', 'test/**/*.js'], {
    cwd: tmpRoot,
    encoding: 'utf8',
    env: {
      ...process.env,
      NODE_PATH: path.join(jsdiffRoot, 'node_modules'),
    },
    maxBuffer: 20 * 1024 * 1024,
  });

  process.stdout.write(result.stdout || '');
  process.stderr.write(result.stderr || '');

  if (result.status !== 0) {
    throw new Error(`Mocha failed with status ${result.status}`);
  }
}

async function main() {
  await ensureJsdiffBuilt();
  await prepareTempWorkspace();
  await writeWrappers();
  await runMocha();
}

main().catch((error) => {
  console.error(error.stack || String(error));
  process.exit(1);
});
