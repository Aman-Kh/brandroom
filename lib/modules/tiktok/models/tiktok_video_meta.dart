class TikTokVideoMeta {
  int? width;
  int? height;
  int? ratio;
  int? duration;

  TikTokVideoMeta({this.width, this.height, this.ratio, this.duration});

  TikTokVideoMeta.fromJson(Map<String, dynamic> json) {
    width = json['width'];
    height = json['height'];
    ratio = json['ratio'];
    duration = json['duration'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['width'] = width;
    data['height'] = height;
    data['ratio'] = ratio;
    data['duration'] = duration;
    return data;
  }
}
