class FilterAttribute {
  int? id;
  String? slug;
  String? name;

  FilterAttribute.fromJson(Map<String, dynamic> parsedJson) {
    id = parsedJson['id'];
    slug = parsedJson['slug'];
    name = parsedJson['name'];
  }
}

class SubAttribute {
  int? id;
  String? name;

  SubAttribute.fromJson(Map<String, dynamic> parsedJson) {
    id = parsedJson['id'];
    name = parsedJson['name'];
  }

  @override
  String toString() {
    return '[id: $id ===== name: $name]';
  }
}
