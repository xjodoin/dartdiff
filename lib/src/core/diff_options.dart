class DiffComputationOptions<TokenT> {
  const DiffComputationOptions({
    this.oneChangePerToken = false,
    this.ignoreCase = false,
    this.timeout,
    this.maxEditLength,
    this.comparator,
    this.extras = const {},
  });

  final bool oneChangePerToken;
  final bool ignoreCase;
  final int? timeout;
  final int? maxEditLength;
  final bool Function(TokenT left, TokenT right)? comparator;
  final Map<String, Object?> extras;

  T? extra<T>(String key) => extras[key] as T?;

  DiffComputationOptions<TokenT> copyWith({
    bool? oneChangePerToken,
    bool? ignoreCase,
    int? timeout,
    int? maxEditLength,
    bool Function(TokenT left, TokenT right)? comparator,
    Map<String, Object?>? extras,
  }) {
    return DiffComputationOptions<TokenT>(
      oneChangePerToken: oneChangePerToken ?? this.oneChangePerToken,
      ignoreCase: ignoreCase ?? this.ignoreCase,
      timeout: timeout ?? this.timeout,
      maxEditLength: maxEditLength ?? this.maxEditLength,
      comparator: comparator ?? this.comparator,
      extras: extras ?? this.extras,
    );
  }
}
