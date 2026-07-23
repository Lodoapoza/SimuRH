import 'dart:convert';

class Establishment {
  final String id;
  final String name;
  final String city;
  final String country;
  final String licenseStatus; // trial/active/expired
  final String licenseKey;
  final DateTime licenseStart;
  final DateTime licenseEnd;

  Establishment({
    required this.id,
    required this.name,
    required this.city,
    required this.country,
    required this.licenseStatus,
    required this.licenseKey,
    required this.licenseStart,
    required this.licenseEnd,
  });

  factory Establishment.fromJson(Map<String, dynamic> json) {
    return Establishment(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      licenseStatus: json['licenseStatus'] as String,
      licenseKey: json['licenseKey'] as String,
      licenseStart: DateTime.parse(json['licenseStart'] as String),
      licenseEnd: DateTime.parse(json['licenseEnd'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'country': country,
      'licenseStatus': licenseStatus,
      'licenseKey': licenseKey,
      'licenseStart': licenseStart.toIso8601String(),
      'licenseEnd': licenseEnd.toIso8601String(),
    };
  }
}