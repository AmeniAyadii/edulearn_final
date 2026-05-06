// lib/models/theme_settings.dart

class ThemeSettings {
  final bool isDarkMode;
  final DateTime? lastUpdated;
  
  ThemeSettings({
    required this.isDarkMode,
    this.lastUpdated,
  });
  
  Map<String, dynamic> toJson() => {
    'isDarkMode': isDarkMode,
    'lastUpdated': lastUpdated?.toIso8601String(),
  };
  
  factory ThemeSettings.fromJson(Map<String, dynamic> json) {
    return ThemeSettings(
      isDarkMode: json['isDarkMode'] ?? false,
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : null,
    );
  }
}