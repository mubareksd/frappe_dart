import 'dart:convert';

class Message {
  Message({this.value, this.description});

  factory Message.fromMap(Map<String, dynamic> data) => Message(
        value: data['value'] as String?,
        description: data['description'] as String?,
      );

  /// `dart:convert`
  ///
  /// Parses the string and returns the resulting Json object as [Message].
  factory Message.fromJson(String data) {
    return Message.fromMap(json.decode(data) as Map<String, dynamic>);
  }
  String? value;
  String? description;

  Map<String, dynamic> toMap() => {
        'value': value,
        'description': description,
      };

  /// `dart:convert`
  ///
  /// Converts [Message] to a JSON string.
  String toJson() => json.encode(toMap());
}
