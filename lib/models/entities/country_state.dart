class CountryState {
  String? id;
  String? code;
  String? name;
  CountryState({this.id, this.code, this.name});

  CountryState.fromConfig(dynamic parsedJson) {
    if (parsedJson is Map) {
      id = parsedJson['code'];
      code = parsedJson['code'];
      name = parsedJson['name'];
    }
    if (parsedJson is String) {
      id = parsedJson;
      code = parsedJson;
      name = parsedJson;
    }
  }

  CountryState.fromMagentoJson(Map<String, dynamic> parsedJson) {
    id = parsedJson['id'];
    code = parsedJson['code'];
    name = parsedJson['name'];
  }

  CountryState.fromOpencartJson(Map<String, dynamic> parsedJson) {
    id = parsedJson['zone_id'];
    code = parsedJson['code'];
    name = parsedJson['name'];
  }

  CountryState.fromPrestashop(Map<String, dynamic> parsedJson) {
    id = parsedJson['id'].toString();
    name = parsedJson['name'];
    code = parsedJson['iso_code'];
  }

  CountryState.fromWooJson(Map<String, dynamic> parsedJson) {
    id = parsedJson['code'];
    code = parsedJson['code'];
    name = parsedJson['name'];
  }

  CountryState.fromBigCommerceJson(Map<String, dynamic> parsedJson) {
    id = parsedJson['code'];
    code = parsedJson['code'];
    name = parsedJson['name'];
  }
}
