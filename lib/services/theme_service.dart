// lib/services/theme_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/theme_settings.dart';

class ThemeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String get _userId => _auth.currentUser?.uid ?? '';
  
  // Sauvegarder le thème dans Firestore
  Future<void> saveThemePreference(bool isDarkMode) async {
    if (_userId.isEmpty) return;
    
    try {
      final userRef = _firestore.collection('users').doc(_userId);
      await userRef.set({
        'themeSettings': {
          'isDarkMode': isDarkMode,
          'lastUpdated': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
      
      debugPrint('✅ Thème sauvegardé dans Firestore: ${isDarkMode ? "Sombre" : "Clair"}');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde thème: $e');
    }
  }
  
  // Charger le thème depuis Firestore
  Future<ThemeSettings?> getThemePreference() async {
    if (_userId.isEmpty) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      final data = doc.data();
      
      if (data != null && data.containsKey('themeSettings')) {
        final themeData = data['themeSettings'];
        return ThemeSettings(
          isDarkMode: themeData['isDarkMode'] ?? false,
          lastUpdated: (themeData['lastUpdated'] as Timestamp?)?.toDate(),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement thème: $e');
    }
    
    return null;
  }
  
  // Écouter les changements de thème en temps réel
  Stream<ThemeSettings?> watchThemePreference() {
    if (_userId.isEmpty) return Stream.value(null);
    
    return _firestore
        .collection('users')
        .doc(_userId)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          if (data != null && data.containsKey('themeSettings')) {
            final themeData = data['themeSettings'];
            return ThemeSettings(
              isDarkMode: themeData['isDarkMode'] ?? false,
              lastUpdated: (themeData['lastUpdated'] as Timestamp?)?.toDate(),
            );
          }
          return null;
        });
  }
}