class CategoryConfig {
  final bool enableLargeCategories;

  const CategoryConfig({
    required this.enableLargeCategories,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryConfig &&
          runtimeType == other.runtimeType &&
          enableLargeCategories == other.enableLargeCategories);

  @override
  int get hashCode => enableLargeCategories.hashCode;

  @override
  String toString() {
    return 'CategoryConfig{ enableLargeCategories: $enableLargeCategories,}';
  }

  CategoryConfig copyWith({
    bool? enableLargeCategories,
  }) {
    return CategoryConfig(
      enableLargeCategories:
          enableLargeCategories ?? this.enableLargeCategories,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableLargeCategories': enableLargeCategories,
    };
  }

  factory CategoryConfig.fromJson(Map<String, dynamic> map) {
    return CategoryConfig(
      enableLargeCategories: map['enableLargeCategories'] ?? false,
    );
  }
}
