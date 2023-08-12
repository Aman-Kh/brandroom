// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ForgetPasswordResponse {
  ForgetPasswordResponse({
    required this.data,
    required this.message,
  });

  final Data? data;
  final String? message;

  ForgetPasswordResponse copyWith({
    Data? data,
    String? message,
  }) {
    return ForgetPasswordResponse(
      data: data ?? this.data,
      message: message ?? this.message,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'data': data?.toMap(),
      'message': message,
    };
  }

  factory ForgetPasswordResponse.fromMap(Map<String, dynamic> map) {
    return ForgetPasswordResponse(
      data: map['data'] != null
          ? Data.fromMap(map['data'] as Map<String, dynamic>)
          : null,
      message: map['message'] != null ? map['message'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ForgetPasswordResponse.fromJson(String source) =>
      ForgetPasswordResponse.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'ForgetPasswordResponse(data: $data, message: $message)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ForgetPasswordResponse &&
        other.data == data &&
        other.message == message;
  }

  @override
  int get hashCode => data.hashCode ^ message.hashCode;
}

class Data {
  Data({
    required this.status,
  });

  final int? status;

  Data copyWith({
    int? status,
  }) {
    return Data(
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'status': status,
    };
  }

  factory Data.fromMap(Map<String, dynamic> map) {
    return Data(
      status: map['status'] != null ? map['status'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Data.fromJson(String source) =>
      Data.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Data(status: $status)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Data && other.status == status;
  }

  @override
  int get hashCode => status.hashCode;
}

// ForgetLoginResponseModel forgetLoginResponseJson(String str) =>
//     ForgetLoginResponseModel.fromJson(json.decode(str));

// class ForgetLoginResponseModel {
//   ForgetLoginResponseModel({
//     required this.message,
//     required this.data,
//   });
//   late final String message;
//   late final String? data;

//   ForgetLoginResponseModel.fromJson(Map<String, dynamic> json) {
//     message = json['message'];
//     data = json['data'];
//   }

//   Map<String, dynamic> toJson() {
//     final data = <String, dynamic>{};
//     data['message'] = message;
//     data['data'] = data;
//     return data;
//   }
// }
