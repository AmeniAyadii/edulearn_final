import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  Child? _currentChild;  // ← AJOUTER CETTE LIGNE
  List<Child> _children = [];  // ← AJOUTER CETTE LIGNE
  bool _isLoading = false;
  
  // Getters
  User? get user => _user;
  Child? get currentChild => _currentChild;  // ← AJOUTER CETTE LIGNE
  List<Child> get children => _children;  // ← AJOUTER CETTE LIGNE
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  
  // ... Gardez tout votre code existant ...
  
  // Méthode pour définir l'enfant actif
  void setCurrentChild(Child child) {
    _currentChild = child;
    notifyListeners();
  }
  
  // Méthode pour charger l'enfant depuis Firestore
  Future<void> loadCurrentChild(String childId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final doc = await _firestore.collection('children').doc(childId).get();
      if (doc.exists) {
        _currentChild = Child.fromMap(doc.id, doc.data()!);
      }
    } catch (e) {
      debugPrint('Erreur chargement enfant: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // Méthode pour charger tous les enfants d'un parent
  Future<void> loadChildren(String parentId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final snapshot = await _firestore
          .collection('children')
          .where('userId', isEqualTo: parentId)
          .get();
      
      _children = snapshot.docs
          .map((doc) => Child.fromMap(doc.id, doc.data()))
          .toList();
          
      if (_children.isNotEmpty && _currentChild == null) {
        _currentChild = _children.first;
      }
    } catch (e) {
      debugPrint('Erreur chargement enfants: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
}