class Site {
  final String id;
  final String name;
  final String location;
  final String userId;

  Site({
    required this.id,
    required this.name,
    required this.location,
    required this.userId,
  });

  // Supabase se jab data aayega (JSON), usko Dart me badalne ke liye
  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'] ?? '',
      name: json['name'] ?? 'No Name',
      location: json['location'] ?? 'No Location',
      userId: json['user_id'] ?? '',
    );
  }

  // Wapis Supabase bhejne ke liye
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'user_id': userId,
    };
  }
}