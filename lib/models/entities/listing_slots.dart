import 'dart:convert';

class ListingSlots {
  List<List<dynamic>> timeSlots = [];

  ListingSlots.fromJson(String? slot) {
    if (slot != null && slot.isNotEmpty) {
      try {
        var json = jsonDecode(slot);
        for (var item in json) {
          var list = <dynamic>[];
          for (var timeSlot in item) {
            list.add(timeSlot.split('|')[0]);
          }
          timeSlots.add(list);
        }
      } catch (e) {
        return;
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {'timeSlots': timeSlots};
  }
}
