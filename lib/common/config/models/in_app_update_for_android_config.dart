class InAppUpdateForAndroidConfig {
  final bool enable;
  final TypeUpdate typeUpdate;

  const InAppUpdateForAndroidConfig({
    required this.enable,
    required this.typeUpdate,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['enable'] = enable;
    data['typeUpdate'] = typeUpdate.name;
    return data;
  }

  factory InAppUpdateForAndroidConfig.fromJson(Map<String, dynamic> json) {
    return InAppUpdateForAndroidConfig(
      enable: json['enable'] ?? false,
      typeUpdate: '${json['typeUpdate']}'.toTypeUpdate(),
    );
  }
}

enum TypeUpdate {
  immediate,
  flexible,
}

extension on String {
  TypeUpdate toTypeUpdate() {
    switch (this) {
      case 'immediate':
        return TypeUpdate.immediate;
      case 'flexible':
      default:
        return TypeUpdate.flexible;
    }
  }
}
