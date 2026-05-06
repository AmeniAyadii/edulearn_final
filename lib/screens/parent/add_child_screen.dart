import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/local_auth_service.dart';
import '../../theme/app_theme.dart';

class AddChildScreen extends StatefulWidget {
  final Map<String, dynamic>? childToEdit;
  
  const AddChildScreen({super.key, this.childToEdit});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final LocalAuthService _auth = LocalAuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  String _selectedLanguage = 'fr';
  bool _isLoading = false;
  int _selectedAvatar = 0;
  File? _selectedImage;
  bool _useCustomImage = false;
  bool _isCheckingSession = true;

  final List<Map<String, dynamic>> _avatars = const [
    {'emoji': '👶', 'name': 'Bébé'},
    {'emoji': '🎓', 'name': 'Écolier'},
    {'emoji': '✨', 'name': 'Magique'},
    {'emoji': '🚀', 'name': 'Astronaute'},
    {'emoji': '🌳', 'name': 'Nature'},
    {'emoji': '🎵', 'name': 'Musique'},
  ];

  final List<Map<String, String>> _languages = const [
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
  ];

  bool get isEditing => widget.childToEdit != null;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    if (isEditing) {
      _loadChildData();
    }
  }

  void _loadChildData() {
    final child = widget.childToEdit!;
    _nameController.text = child['name'] ?? '';
    _ageController.text = (child['age'] ?? '').toString();
    _selectedLanguage = child['preferredLanguage'] ?? 'fr';
    _selectedAvatar = child['avatarIndex'] ?? 0;
    
    if (child['customImagePath'] != null && 
        child['customImagePath'].toString().isNotEmpty) {
      final imageFile = File(child['customImagePath']);
      if (imageFile.existsSync()) {
        _selectedImage = imageFile;
        _useCustomImage = true;
      }
    }
  }

  Future<void> _checkLoginStatus() async {
    setState(() => _isCheckingSession = true);
    
    final isLoggedIn = await _auth.isLoggedIn();
    var currentUser = await _auth.getCurrentUser();
    
    if (currentUser == null) {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('app_users');
      if (usersJson != null) {
        final users = List<Map<String, dynamic>>.from(jsonDecode(usersJson));
        if (users.isNotEmpty) {
          currentUser = users.first;
          print('Utilisateur restauré: ${currentUser['name']}');
        }
      }
    }
    
    print('Status - isLoggedIn: $isLoggedIn, User: ${currentUser?['name']}');
    
    if (!isLoggedIn || currentUser == null) {
      if (mounted) {
        _showSnackBar('Veuillez vous reconnecter');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    }
    
    setState(() => _isCheckingSession = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
      );
      
      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
          _useCustomImage = true;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erreur lors de la sélection');
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 512,
      );
      
      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
          _useCustomImage = true;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erreur lors de la prise de photo');
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _useCustomImage = false;
    });
  }

  Future<Map<String, dynamic>?> _getValidCurrentUser() async {
    var currentUser = await _auth.getCurrentUser();
    
    if (currentUser == null) {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('app_users');
      if (usersJson != null) {
        final users = List<Map<String, dynamic>>.from(jsonDecode(usersJson));
        if (users.isNotEmpty) {
          currentUser = users.first;
          print('Utilisateur restauré avec succès: ${currentUser['name']}');
        }
      }
    }
    
    return currentUser;
  }

  Future<void> _addChild() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Veuillez entrer un prénom');
      return;
    }

    final age = int.tryParse(_ageController.text);
    if (age == null || age < 2 || age > 15) {
      _showSnackBar('Âge invalide (2-15 ans)');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = await _getValidCurrentUser();
      print('CurrentUser avant ajout: ${currentUser?['name']} (ID: ${currentUser?['id']})');
      
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté. Veuillez vous reconnecter.');
      }
      
      if (currentUser['id'] == null) {
        throw Exception('ID utilisateur invalide');
      }
      
      final childData = {
        'name': name,
        'age': age,
        'preferredLanguage': _selectedLanguage,
        'avatarIndex': _useCustomImage ? -1 : _selectedAvatar,
        'customImagePath': null,
        'points': 0,
        'level': 1,
        'streak': 0,
      };
      
      print('Ajout enfant avec parentId: ${currentUser['id']}');
      
      final success = await _auth.addChild(currentUser['id'], childData);
      
      if (success && mounted) {
        if (_useCustomImage && _selectedImage != null) {
          final children = await _auth.getChildren(currentUser['id']);
          if (children.isNotEmpty) {
            final newChild = children.last;
            _auth.saveChildImage(_selectedImage!, newChild['id']);
          }
        }
        
        _showSnackBar('Enfant ajouté avec succès!', isError: false);
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Erreur lors de l\'ajout de l\'enfant');
      }
    } catch (e) {
      print('Erreur détaillée: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(e.toString());
        
        if (e.toString().contains('connecté') || e.toString().contains('session')) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          });
        }
      }
    }
  }

  Future<void> _updateChild() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Veuillez entrer un prénom');
      return;
    }

    final age = int.tryParse(_ageController.text);
    if (age == null || age < 2 || age > 15) {
      _showSnackBar('Âge invalide (2-15 ans)');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = await _getValidCurrentUser();
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }
      
      final updatedData = {
        'name': name,
        'age': age,
        'preferredLanguage': _selectedLanguage,
        'avatarIndex': _useCustomImage ? -1 : _selectedAvatar,
        'customImagePath': widget.childToEdit!['customImagePath'],
        'points': widget.childToEdit!['points'] ?? 0,
        'level': widget.childToEdit!['level'] ?? 1,
        'streak': widget.childToEdit!['streak'] ?? 0,
      };
      
      final success = await _auth.updateChild(widget.childToEdit!['id'], updatedData);
      
      if (success && mounted) {
        if (_useCustomImage && _selectedImage != null) {
          await _auth.saveChildImage(_selectedImage!, widget.childToEdit!['id']);
        }
        
        _showSnackBar('Enfant modifié avec succès!', isError: false);
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Erreur lors de la modification');
      }
    } catch (e) {
      print('Erreur détaillée: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(e.toString());
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return Scaffold(
        backgroundColor: AppTheme.lightBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Vérification de la session...',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier l\'enfant' : 'Ajouter un enfant'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildPhotoSection(),
            const SizedBox(height: 24),
            if (!_useCustomImage) _buildAvatarSection(),
            if (!_useCustomImage) const SizedBox(height: 24),
            _buildFormCard(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Photo de profil'),
        const SizedBox(height: 12),
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _showImagePickerDialog,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      width: 2,
                    ),
                    image: _useCustomImage && _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (!_useCustomImage || _selectedImage == null)
                      ? Icon(
                          Icons.camera_alt,
                          size: 40,
                          color: AppTheme.primaryColor.withOpacity(0.5),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _showImagePickerDialog,
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('Choisir une photo'),
              ),
              if (_useCustomImage)
                TextButton.icon(
                  onPressed: _removeImage,
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ou choisissez un avatar'),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _avatars.length,
            itemBuilder: (context, index) {
              final avatar = _avatars[index];
              final isSelected = _selectedAvatar == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatar = index),
                child: Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        avatar['emoji'],
                        style: const TextStyle(fontSize: 30),
                      ),
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Prénom',
                hintText: 'Entrez le prénom de l\'enfant',
                prefixIcon: const Icon(Icons.child_care_outlined, color: AppTheme.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.lightBackground,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Âge',
                hintText: 'Entrez l\'âge (2-15 ans)',
                prefixIcon: const Icon(Icons.cake_outlined, color: AppTheme.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.lightBackground,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: InputDecoration(
                labelText: 'Langue préférée',
                prefixIcon: const Icon(Icons.language, color: AppTheme.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.lightBackground,
              ),
              items: _languages.map((lang) {
                return DropdownMenuItem(
                  value: lang['code'],
                  child: Row(
                    children: [
                      Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Text(lang['name']!),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedLanguage = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : (isEditing ? _updateChild : _addChild),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isEditing ? Icons.save : Icons.add),
                  const SizedBox(width: 8),
                  Text(isEditing ? 'Modifier l\'enfant' : 'Ajouter l\'enfant'),
                ],
              ),
      ),
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choisir une photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPickerOption(
                    icon: Icons.camera_alt,
                    label: 'Appareil photo',
                    onTap: _takePhoto,
                    color: Colors.blue,
                  ),
                  _buildPickerOption(
                    icon: Icons.photo_library,
                    label: 'Galerie',
                    onTap: _pickImage,
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}