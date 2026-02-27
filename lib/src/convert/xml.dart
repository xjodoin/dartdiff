import '../models/change.dart';

String convertChangesToXml(List<Change<String>> changes) {
  final ret = StringBuffer();

  for (final change in changes) {
    if (change.added) {
      ret.write('<ins>');
    } else if (change.removed) {
      ret.write('<del>');
    }

    ret.write(_escapeHtml(change.value));

    if (change.added) {
      ret.write('</ins>');
    } else if (change.removed) {
      ret.write('</del>');
    }
  }

  return ret.toString();
}

String convertChangesToXML(List<Change<String>> changes) {
  return convertChangesToXml(changes);
}

String _escapeHtml(String s) {
  return s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
