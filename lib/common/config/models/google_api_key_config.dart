class GoogleApiKeyConfig {
  final String android;
  final String ios;
  final String web;

  const GoogleApiKeyConfig({
    required this.android,
    required this.ios,
    required this.web,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoogleApiKeyConfig &&
          runtimeType == other.runtimeType &&
          android == other.android &&
          ios == other.ios &&
          web == other.web);

  @override
  int get hashCode => android.hashCode ^ ios.hashCode ^ web.hashCode;

  bool get isEmpty => android.isEmpty && ios.isEmpty && web.isEmpty;

  bool get isNotEmpty => !isEmpty;

  @override
  String toString() {
    return 'GoogleApiKeyConfig{ android: $android, ios: $ios, web: $web }';
  }

  GoogleApiKeyConfig copyWith({
    String? android,
    String? ios,
    String? web,
  }) {
    return GoogleApiKeyConfig(
      android: android ?? this.android,
      ios: ios ?? this.ios,
      web: web ?? this.web,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'android': android,
      'ios': ios,
      'web': web,
    };
  }

  factory GoogleApiKeyConfig.fromMap(Map map) {
    return GoogleApiKeyConfig(
      android: '${map['android']}',
      ios: '${map['ios']}',
      web: '${map['web']}',
    );
  }
}
