import 'color_override/index.dart';

export 'color_override/index.dart';

class ColorOverrideConfig {
  ProductFilterColor? productFilterColor;
  StockColor stockColor = StockColor();

  ColorOverrideConfig({
    this.productFilterColor,
    required this.stockColor,
  });

  ColorOverrideConfig.fromJson(dynamic json) {
    if (json['productFilterColor'] != null) {
      productFilterColor =
          ProductFilterColor.fromJson(json['productFilterColor']);
    }
    if (json['stockColor'] != null) {
      stockColor = StockColor.fromJson(json['stockColor']);
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map['productFilterColor'] = productFilterColor?.toJson();
    map['stockColor'] = stockColor.toJson();
    map.removeWhere((key, value) => value == null);
    return map;
  }
}
