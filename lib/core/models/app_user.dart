import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final List<String> triggers;
  final String? gender;
  final DateTime? birthDate;
  final String? photoUrl;
  final bool? isDarkTheme;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.triggers,
    this.gender,
    this.birthDate,
    this.photoUrl,
    this.isDarkTheme,
  });

  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      triggers: List<String>.from(data['triggers'] ?? []),
      gender: data['gender'],
      birthDate: (data['birthDate'] != null && data['birthDate'] is Timestamp)
          ? (data['birthDate'] as Timestamp).toDate()
          : DateTime.now(),
      photoUrl: data['photoUrl'],
      isDarkTheme: data['isDarkTheme'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'triggers': triggers,
      if (gender != null) 'gender': gender,
      if (birthDate != null) 'birthDate': birthDate,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (isDarkTheme != null) 'isDarkTheme': isDarkTheme,
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    List<String>? triggers,
    String? gender,
    DateTime? birthDate,
    String? photoUrl,
    bool? isDarkTheme,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      triggers: triggers ?? this.triggers,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      photoUrl: photoUrl ?? this.photoUrl,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
    );
  }
}
