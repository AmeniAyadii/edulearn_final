import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();
  
  final List<Map<String, dynamic>> _events = [];
  
  Future<void> logEvent(String eventName, Map<String, dynamic>? parameters) async {
    final event = {
      'name': eventName,
      'timestamp': DateTime.now().toIso8601String(),
      'parameters': parameters ?? {},
    };
    
    _events.add(event);
    
    // Sauvegarder dans SharedPreferences pour analyse ultérieure
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_event', event.toString());
    
    // Log pour debug
    print('Analytics Event: $eventName ${parameters ?? {}}');
    
    // Simuler l'envoi à un serveur
    _sendToServer(event);
  }
  
  Future<void> logScreenView(String screenName) async {
    await logEvent('screen_view', {'screen_name': screenName});
  }
  
  Future<void> logError(String errorCode, String errorMessage) async {
    await logEvent('error', {
      'error_code': errorCode,
      'error_message': errorMessage,
    });
  }
  
  Future<void> _sendToServer(Map<String, dynamic> event) async {
    // Ici vous implémenteriez l'envoi réel à votre backend
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  List<Map<String, dynamic>> getEvents() => List.unmodifiable(_events);
  
  void clearEvents() {
    _events.clear();
  }
}