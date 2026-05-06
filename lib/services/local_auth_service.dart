import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LocalAuthService {
  static const String _usersKey = 'app_users';
  static const String _currentUserKey = 'current_user';
  static const String _childrenKey = 'app_children';
  static const String _currentChildKey = 'current_child';
  
  // Cache
  Map<String, dynamic>? _cachedCurrentUser;
  List<Map<String, dynamic>>? _cachedChildren;

  

  // Inscription
  Future<bool> signUp(String email, String password, String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      List<Map<String, dynamic>> users = [];
      
      if (usersJson != null) {
        users = List<Map<String, dynamic>>.from(jsonDecode(usersJson));
      }
      
      // Vérifier si l'email existe déjà
      if (users.any((user) => user['email'] == email)) {
        return false;
      }
      
      // Ajouter le nouvel utilisateur
      users.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'email': email,
        'password': password,
        'name': name,
        'createdAt': DateTime.now().toIso8601String(),
        'childrenIds': [],
      });
      
      await prefs.setString(_usersKey, jsonEncode(users));
      return true;
    } catch (e) {
      print('Erreur signUp: $e');
      return false;
    }
  }

  // Ajoutez cette méthode dans LocalAuthService
Future<void> forceRefreshUser() async {
  final prefs = await SharedPreferences.getInstance();
  final userJson = prefs.getString(_currentUserKey);
  if (userJson != null) {
    _cachedCurrentUser = jsonDecode(userJson);
    print('Utilisateur rechargé: ${_cachedCurrentUser?['name']}');
  } else {
    // Essayer de restaurer depuis la liste des users
    final usersJson = prefs.getString(_usersKey);
    if (usersJson != null) {
      final users = List<Map<String, dynamic>>.from(jsonDecode(usersJson));
      if (users.isNotEmpty) {
        _cachedCurrentUser = users.first;
        await prefs.setString(_currentUserKey, jsonEncode(_cachedCurrentUser));
        print('Utilisateur restauré: ${_cachedCurrentUser?['name']}');
      }
    }
  }
}

  // Connexion
  Future<Map<String, dynamic>?> signIn(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      
      if (usersJson == null) return null;
      
      final users = List<Map<String, dynamic>>.from(jsonDecode(usersJson));
      final user = users.firstWhere(
        (user) => user['email'] == email && user['password'] == password,
        orElse: () => {},
      );
      
      if (user.isEmpty) return null;
      
      // Sauvegarder l'utilisateur courant
      _cachedCurrentUser = user;
      await prefs.setString(_currentUserKey, jsonEncode(user));
      
      // Vérifier que la sauvegarde a réussi
      final savedUser = await getCurrentUser();
      print('Utilisateur connecté: ${savedUser?['name']}');
      
      return user;
    } catch (e) {
      print('Erreur signIn: $e');
      return null;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      await prefs.remove(_currentChildKey);
      _cachedCurrentUser = null;
      _cachedChildren = null;
      print('Déconnexion réussie');
    } catch (e) {
      print('Erreur signOut: $e');
    }
  }

  // Récupérer l'utilisateur courant (avec vérification)
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      // Retourner le cache si disponible
      if (_cachedCurrentUser != null) {
        return _cachedCurrentUser;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_currentUserKey);
      
      if (userJson == null) {
        print('Aucun utilisateur connecté');
        return null;
      }
      
      final user = jsonDecode(userJson);
      _cachedCurrentUser = user;
      
      print('Utilisateur récupéré: ${user['name']} (${user['id']})');
      return user;
    } catch (e) {
      print('Erreur getCurrentUser: $e');
      return null;
    }
  }

  // Vérifier si un utilisateur est connecté
  

  // Ajouter un enfant (version corrigée)
  Future<bool> addChild(String parentId, Map<String, dynamic> child) async {
    try {
      print('Ajout enfant - parentId: $parentId');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Générer l'ID
      final childId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Préparer les données
      final newChild = {
        'id': childId,
        'parentId': parentId,
        'name': child['name'],
        'age': child['age'],
        'preferredLanguage': child['preferredLanguage'],
        'avatarIndex': child['avatarIndex'],
        'customImagePath': child['customImagePath'],
        'points': child['points'] ?? 0,
        'level': child['level'] ?? 1,
        'streak': child['streak'] ?? 0,
        'lastActive': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      // Lire les enfants existants
      List<Map<String, dynamic>> children = [];
      final childrenJson = prefs.getString(_childrenKey);
      if (childrenJson != null) {
        children = List<Map<String, dynamic>>.from(jsonDecode(childrenJson));
      }
      
      // Ajouter le nouvel enfant
      children.add(newChild);
      
      // Sauvegarder
      await prefs.setString(_childrenKey, jsonEncode(children));
      
      // Mettre à jour le cache
      _cachedChildren = children;
      
      // Mettre à jour la liste des enfants du parent
      await _addChildToParent(parentId, childId);
      
      print('Enfant ajouté avec succès: ${newChild['name']} (ID: $childId)');
      return true;
    } catch (e) {
      print('Erreur addChild: $e');
      return false;
    }
  }

  // Ajouter l'ID de l'enfant au parent
  Future<void> _addChildToParent(String parentId, String childId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      
      if (usersJson == null) return;
      
      final users = List<Map<String, dynamic>>.from(jsonDecode(usersJson));
      final userIndex = users.indexWhere((user) => user['id'] == parentId);
      
      if (userIndex != -1) {
        if (users[userIndex]['childrenIds'] == null) {
          users[userIndex]['childrenIds'] = [];
        }
        users[userIndex]['childrenIds'].add(childId);
        
        // Mettre à jour l'utilisateur courant si c'est le même
        final currentUser = await getCurrentUser();
        if (currentUser != null && currentUser['id'] == parentId) {
          currentUser['childrenIds'] = users[userIndex]['childrenIds'];
          _cachedCurrentUser = currentUser;
          await prefs.setString(_currentUserKey, jsonEncode(currentUser));
        }
        
        await prefs.setString(_usersKey, jsonEncode(users));
        print('Parent mis à jour avec succès');
      }
    } catch (e) {
      print('Erreur _addChildToParent: $e');
    }
  }

  // Récupérer les enfants d'un parent
  Future<List<Map<String, dynamic>>> getChildren(String parentId) async {
    try {
      if (_cachedChildren != null) {
        return _cachedChildren!.where((child) => child['parentId'] == parentId).toList();
      }
      
      final prefs = await SharedPreferences.getInstance();
      final childrenJson = prefs.getString(_childrenKey);
      
      if (childrenJson == null) return [];
      
      final children = List<Map<String, dynamic>>.from(jsonDecode(childrenJson));
      _cachedChildren = children;
      
      return children.where((child) => child['parentId'] == parentId).toList();
    } catch (e) {
      print('Erreur getChildren: $e');
      return [];
    }
  }

  // Récupérer un enfant par son ID
  Future<Map<String, dynamic>?> getChildById(String childId) async {
    try {
      if (_cachedChildren != null) {
        try {
          return _cachedChildren!.firstWhere((child) => child['id'] == childId);
        } catch (e) {
          // Pas trouvé dans le cache
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      final childrenJson = prefs.getString(_childrenKey);
      
      if (childrenJson == null) return null;
      
      final children = List<Map<String, dynamic>>.from(jsonDecode(childrenJson));
      final child = children.firstWhere((child) => child['id'] == childId);
      return child;
    } catch (e) {
      print('Erreur getChildById: $e');
      return null;
    }
  }

  // Mettre à jour l'image d'un enfant
  Future<bool> updateChildImage(String childId, String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final childrenJson = prefs.getString(_childrenKey);
      
      if (childrenJson == null) return false;
      
      final children = List<Map<String, dynamic>>.from(jsonDecode(childrenJson));
      final index = children.indexWhere((child) => child['id'] == childId);
      
      if (index != -1) {
        children[index]['customImagePath'] = imagePath;
        await prefs.setString(_childrenKey, jsonEncode(children));
        
        // Mettre à jour le cache
        if (_cachedChildren != null && index < _cachedChildren!.length) {
          _cachedChildren![index]['customImagePath'] = imagePath;
        }
        
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur updateChildImage: $e');
      return false;
    }
  }

  // Dans local_auth_service.dart, modifiez la méthode updateChildStats comme ceci :

Future<bool> updateChildStats(String childId, {
  int? points,
  int? level,
  int? streak,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final childrenJson = prefs.getString(_childrenKey);
  
  if (childrenJson == null) return false;
  
  final children = List<Map<String, dynamic>>.from(jsonDecode(childrenJson));
  final index = children.indexWhere((child) => child['id'] == childId);
  
  if (index != -1) {
    // Ajouter des points si spécifiés
    if (points != null && points != 0) {
      children[index]['points'] = (children[index]['points'] ?? 0) + points;
    }
    
    // Mettre à jour le niveau si spécifié
    if (level != null) {
      children[index]['level'] = level;
    }
    
    // Mettre à jour la série si spécifiée
    if (streak != null) {
      children[index]['streak'] = streak;
    }
    
    children[index]['lastActive'] = DateTime.now().toIso8601String();
    await prefs.setString(_childrenKey, jsonEncode(children));
    
    // Mettre à jour le cache
    if (_cachedChildren != null && index < _cachedChildren!.length) {
      if (points != null && points != 0) {
        _cachedChildren![index]['points'] = children[index]['points'];
      }
      if (level != null) _cachedChildren![index]['level'] = level;
      if (streak != null) _cachedChildren![index]['streak'] = streak;
      _cachedChildren![index]['lastActive'] = children[index]['lastActive'];
    }
    
    return true;
  }
  return false;
}

  // Sauvegarder l'image d'un enfant
  Future<String?> saveChildImage(File imageFile, String childId) async {
    try {
      final imagesDir = await getChildrenImagesDirectory();
      final fileName = '${childId}.jpg';
      final newPath = path.join(imagesDir.path, fileName);
      
      await imageFile.copy(newPath);
      await updateChildImage(childId, newPath);
      
      return newPath;
    } catch (e) {
      print('Erreur saveChildImage: $e');
      return null;
    }
  }

  // Ajoutez cette méthode à LocalAuthService
Future<bool> verifyAndRestoreSession() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Vérifier si l'utilisateur est dans SharedPreferences
    final userJson = prefs.getString(_currentUserKey);
    if (userJson != null) {
      final user = jsonDecode(userJson);
      _cachedCurrentUser = user;
      print('Session restaurée pour: ${user['name']}');
      return true;
    }
    
    // Vérifier si des utilisateurs existent dans la base
    final usersJson = prefs.getString(_usersKey);
    if (usersJson != null) {
      final users = List<Map<String, dynamic>>.from(jsonDecode(usersJson));
      if (users.isNotEmpty) {
        // Prendre le dernier utilisateur connecté ou le premier
        final lastUser = users.last;
        await prefs.setString(_currentUserKey, jsonEncode(lastUser));
        _cachedCurrentUser = lastUser;
        print('Session restaurée avec dernier utilisateur: ${lastUser['name']}');
        return true;
      }
    }
    
    print('Aucune session à restaurer');
    return false;
  } catch (e) {
    print('Erreur restauration session: $e');
    return false;
  }
}

  // Récupérer le dossier des images
  Future<Directory> getChildrenImagesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final childrenImagesDir = Directory('${appDir.path}/children_images');
    if (!await childrenImagesDir.exists()) {
      await childrenImagesDir.create(recursive: true);
    }
    return childrenImagesDir;
  }

  // Récupérer le dossier de l'application
  Future<Directory> getAppDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  // Sauvegarder l'enfant courant
  Future<void> setCurrentChild(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentChildKey, childId);
  }

  // Récupérer l'enfant courant
  Future<String?> getCurrentChild() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentChildKey);
  }

  // Ajoutez cette méthode pour déboguer
Future<void> debugPrintAllData() async {
  final prefs = await SharedPreferences.getInstance();
  
  print('=== DÉBOGAGE COMPLET ===');
  
  // Vérifier l'utilisateur courant
  final userJson = prefs.getString(_currentUserKey);
  print('Utilisateur courant: $userJson');
  
  // Vérifier tous les utilisateurs
  final usersJson = prefs.getString(_usersKey);
  if (usersJson != null) {
    final users = List<Map<String, dynamic>>.from(jsonDecode(usersJson));
    print('Nombre d\'utilisateurs: ${users.length}');
    for (var user in users) {
      print('  - User: ${user['name']} (ID: ${user['id']})');
    }
  }
  
  // Vérifier tous les enfants
  final childrenJson = prefs.getString(_childrenKey);
  if (childrenJson != null) {
    final children = List<Map<String, dynamic>>.from(jsonDecode(childrenJson));
    print('Nombre d\'enfants: ${children.length}');
    for (var child in children) {
      print('  - Enfant: ${child['name']} (ParentID: ${child['parentId']})');
    }
  }
  
  print('=====================');
}

// Remplacez la méthode isLoggedIn par celle-ci :
Future<bool> isLoggedIn() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Vérifier d'abord la clé de l'utilisateur courant
    final hasCurrentUser = prefs.containsKey(_currentUserKey);
    
    if (hasCurrentUser) {
      final userJson = prefs.getString(_currentUserKey);
      if (userJson != null && userJson.isNotEmpty) {
        print('isLoggedIn: true (utilisateur trouvé)');
        return true;
      }
    }
    
    // Si pas d'utilisateur courant, essayer de restaurer depuis la liste des users
    final usersJson = prefs.getString(_usersKey);
    if (usersJson != null) {
      final users = List<Map<String, dynamic>>.from(jsonDecode(usersJson));
      if (users.isNotEmpty) {
        // Restaurer le dernier utilisateur
        final lastUser = users.last;
        await prefs.setString(_currentUserKey, jsonEncode(lastUser));
        _cachedCurrentUser = lastUser;
        print('isLoggedIn: true (utilisateur restauré: ${lastUser['name']})');
        return true;
      }
    }
    
    print('isLoggedIn: false');
    return false;
  } catch (e) {
    print('Erreur isLoggedIn: $e');
    return false;
  }
}

// Ajoutez cette méthode dans LocalAuthService
Future<bool> ensureLoggedIn() async {
  // Vérifier d'abord si déjà connecté
  final isLogged = await isLoggedIn();
  if (isLogged) {
    return true;
  }
  
  // Sinon, essayer de restaurer la session
  final restored = await verifyAndRestoreSession();
  if (restored) {
    return true;
  }
  
  // En dernier recours, prendre le premier utilisateur de la liste
  try {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson != null) {
      final users = List<Map<String, dynamic>>.from(jsonDecode(usersJson));
      if (users.isNotEmpty) {
        final firstUser = users.first;
        await prefs.setString(_currentUserKey, jsonEncode(firstUser));
        _cachedCurrentUser = firstUser;
        print('Utilisateur forcé: ${firstUser['name']}');
        return true;
      }
    }
  } catch (e) {
    print('Erreur ensureLoggedIn: $e');
  }
  
  return false;
}

// Ajoutez cette méthode dans votre classe LocalAuthService
Future<bool> deleteChild(String childId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Récupérer l'enfant pour obtenir son image
    final child = await getChildById(childId);
    
    // 2. Supprimer l'image si elle existe
    if (child != null && child['customImagePath'] != null) {
      final imageFile = File(child['customImagePath']);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    }
    
    // 3. Supprimer l'enfant de la liste
    final childrenJson = prefs.getString(_childrenKey);
    if (childrenJson != null) {
      List<Map<String, dynamic>> children = List<Map<String, dynamic>>.from(jsonDecode(childrenJson));
      children.removeWhere((c) => c['id'] == childId);
      await prefs.setString(_childrenKey, jsonEncode(children));
      
      // Mettre à jour le cache
      _cachedChildren = children;
    }
    
    // 4. Supprimer l'ID de l'enfant du parent
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      final usersJson = prefs.getString(_usersKey);
      if (usersJson != null) {
        List<Map<String, dynamic>> users = List<Map<String, dynamic>>.from(jsonDecode(usersJson));
        final userIndex = users.indexWhere((u) => u['id'] == currentUser['id']);
        if (userIndex != -1) {
          if (users[userIndex]['childrenIds'] != null) {
            users[userIndex]['childrenIds'].removeWhere((id) => id == childId);
          }
          await prefs.setString(_usersKey, jsonEncode(users));
        }
      }
    }
    
    // 5. Si c'était l'enfant courant, le supprimer
    final currentChild = await getCurrentChild();
    if (currentChild == childId) {
      await prefs.remove(_currentChildKey);
    }
    
    print('Enfant supprimé avec succès: $childId');
    return true;
  } catch (e) {
    print('Erreur deleteChild: $e');
    return false;
  }
}

// Ajoutez ces méthodes dans LocalAuthService


Future<bool> updateChild(String childId, Map<String, dynamic> updatedData) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final childrenJson = prefs.getString(_childrenKey);
    
    if (childrenJson == null) return false;
    
    List<Map<String, dynamic>> children = List<Map<String, dynamic>>.from(jsonDecode(childrenJson));
    final index = children.indexWhere((child) => child['id'] == childId);
    
    if (index != -1) {
      children[index]['name'] = updatedData['name'];
      children[index]['age'] = updatedData['age'];
      children[index]['preferredLanguage'] = updatedData['preferredLanguage'];
      children[index]['avatarIndex'] = updatedData['avatarIndex'];
      children[index]['customImagePath'] = updatedData['customImagePath'];
      children[index]['lastActive'] = DateTime.now().toIso8601String();
      
      await prefs.setString(_childrenKey, jsonEncode(children));
      
      if (_cachedChildren != null && index < _cachedChildren!.length) {
        _cachedChildren![index] = children[index];
      }
      
      print('Enfant mis à jour avec succès: ${updatedData['name']}');
      return true;
    }
    
    return false;
  } catch (e) {
    print('Erreur updateChild: $e');
    return false;
  }
}
}