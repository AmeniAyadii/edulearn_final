// lib/services/language_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'app_language';
  static const List<String> supportedLocales = ['fr', 'en', 'ar'];
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String get _userId => _auth.currentUser?.uid ?? '';
  
  // Sauvegarder la langue dans Firestore et SharedPreferences
  Future<void> saveLanguage(String languageCode) async {
    // Sauvegarde locale
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    
    // Sauvegarde Cloud (si connecté)
    if (_userId.isNotEmpty) {
      try {
        await _firestore.collection('users').doc(_userId).set({
          'language': languageCode,
          'languageUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        debugPrint('✅ Langue sauvegardée dans Firestore: $languageCode');
      } catch (e) {
        debugPrint('❌ Erreur sauvegarde langue dans Firestore: $e');
      }
    }
  }
  
  // Charger la langue depuis Firestore ou SharedPreferences
  Future<String> getLanguage() async {
    // Priorité 1: Firestore (si connecté)
    if (_userId.isNotEmpty) {
      try {
        final doc = await _firestore.collection('users').doc(_userId).get();
        final data = doc.data();
        if (data != null && data.containsKey('language')) {
          final cloudLang = data['language'] as String;
          if (supportedLocales.contains(cloudLang)) {
            // Synchroniser avec SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_languageKey, cloudLang);
            return cloudLang;
          }
        }
      } catch (e) {
        debugPrint('❌ Erreur chargement langue depuis Firestore: $e');
      }
    }
    
    // Priorité 2: SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString(_languageKey);
    if (savedLang != null && supportedLocales.contains(savedLang)) {
      return savedLang;
    }
    
    // Priorité 3: Langue du système
    final systemLang = WidgetsBinding.instance.window.locale.languageCode;
    if (supportedLocales.contains(systemLang)) {
      return systemLang;
    }
    
    // Fallback: Français
    return 'fr';
  }
  
  // Écouter les changements de langue en temps réel (multi-appareils)
  Stream<String> watchLanguage() {
    if (_userId.isEmpty) return Stream.empty();
    
    return _firestore
        .collection('users')
        .doc(_userId)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          if (data != null && data.containsKey('language')) {
            return data['language'] as String;
          }
          return 'fr';
        });
  }
  
  // Obtenir le nom de la langue
  String getLanguageName(String code) {
    switch (code) {
      case 'fr': return 'Français';
      case 'en': return 'English';
      case 'ar': return 'العربية';
      default: return 'Français';
    }
  }
  
  // Obtenir le drapeau
  String getLanguageFlag(String code) {
    switch (code) {
      case 'fr': return '🇫🇷';
      case 'en': return '🇬🇧';
      case 'ar': return '🇸🇦';
      default: return '🇫🇷';
    }
  }
  
  // Changer la langue dans l'application
  Future<void> changeLanguage(BuildContext context, String languageCode) async {
    await saveLanguage(languageCode);
    
    // Mettre à jour la locale dans EasyLocalization
    await EasyLocalization.of(context)?.setLocale(Locale(languageCode));
    
    debugPrint('🔄 Langue changée: ${getLanguageName(languageCode)}');
  }
}