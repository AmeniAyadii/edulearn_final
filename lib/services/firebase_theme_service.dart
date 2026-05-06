import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class FirebaseThemeService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Sauvegarder le thème dans Firebase
  static Future<void> saveTheme(String userId, bool isDarkMode) async {
    try {
      await _database
          .ref()
          .child('users/$userId/theme')
          .set({
            'isDarkMode': isDarkMode,
            'updatedAt': DateTime.now().toIso8601String(),
          });
      print("✅ Thème sauvegardé: ${isDarkMode ? 'Sombre' : 'Clair'}");
    } catch (e) {
      print("❌ Erreur sauvegarde thème: $e");
    }
  }
  
  // Charger le thème depuis Firebase
  static Future<bool?> loadTheme(String userId) async {
    try {
      final snapshot = await _database
          .ref()
          .child('users/$userId/theme/isDarkMode')
          .get();
      
      if (snapshot.exists && snapshot.value != null) {
        print("✅ Thème chargé: ${snapshot.value}");
        return snapshot.value as bool;
      }
      return null;
    } catch (e) {
      print("❌ Erreur chargement thème: $e");
      return null;
    }
  }
  
  // Écouter les changements en temps réel
  static Stream<bool?> listenThemeChanges(String userId) {
    return _database
        .ref()
        .child('users/$userId/theme/isDarkMode')
        .onValue
        .map((event) => event.snapshot.value as bool?);
  }
  
  // Synchroniser avec tous les appareils
  static Future<void> syncThemeAcrossDevices(String userId, bool isDarkMode) async {
    await saveTheme(userId, isDarkMode);
  }
}