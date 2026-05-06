// lib/screens/child/child_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../services/sound_service.dart';
import '../../services/local_auth_service.dart';

class ChildProfileScreen extends StatefulWidget {
  final String childId;
  final String childName;
  
  const ChildProfileScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  final SoundService _soundService = SoundService();
  final ImagePicker _imagePicker = ImagePicker();
  final LocalAuthService _auth = LocalAuthService();
  
  String _childName = '';
  String _childAge = '5';
  String _childGender = 'Garçon';
  String _childLevel = 'Moyenne section';
  String _academicYear = '2024-2025'; // Nouveau champ
  String _parentName = ''; // Nouveau champ
  String _avatarUrl = '';
  int _avatarIndex = 0;
  File? _selectedImage;
  bool _isLoading = false;
  bool _useCustomImage = false;
  
  int _totalGamesPlayed = 0;
  int _totalPoints = 0;
  int _totalActivities = 0;
  int _currentStreak = 0;
  
  final TextEditingController _nameController = TextEditingController();
  
  final List<Map<String, dynamic>> _avatars = const [
    {'emoji': '👶', 'name': 'Bébé', 'color': Colors.blue},
    {'emoji': '🎓', 'name': 'Écolier', 'color': Colors.green},
    {'emoji': '✨', 'name': 'Magique', 'color': Colors.purple},
    {'emoji': '🚀', 'name': 'Astronaute', 'color': Colors.orange},
    {'emoji': '🌳', 'name': 'Nature', 'color': Colors.teal},
    {'emoji': '🎵', 'name': 'Musique', 'color': Colors.pink},
  ];
  
  final List<String> _ageOptions = ['3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
  final List<String> _genderOptions = ['Garçon', 'Fille'];
  final List<String> _levelOptions = [
    'Petite section', 'Moyenne section', 'Grande section', 'CP', 'CE1', 'CE2', 'CM1', 'CM2', '6ème',
  ];
  
  // Options pour l'année universitaire
  final List<String> _academicYears = [
    '2023-2024',
    '2024-2025',
    '2025-2026',
    '2026-2027',
    '2027-2028',
  ];

  @override
  void initState() {
    super.initState();
    _childName = widget.childName;
    _nameController.text = _childName;
    _loadChildData();
    _loadStatistics();
    _loadParentInfo();
  }

  Future<void> _loadParentInfo() async {
    try {
      final currentUser = await _auth.getCurrentUser();
      if (currentUser != null) {
        setState(() {
          _parentName = currentUser['name'] ?? 'Parent';
        });
      } else {
        // Essayer de récupérer depuis SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final savedParentName = prefs.getString('parent_name');
        if (savedParentName != null) {
          setState(() {
            _parentName = savedParentName;
          });
        }
      }
    } catch (e) {
      print('Erreur chargement parent: $e');
      setState(() {
        _parentName = 'Parent';
      });
    }
  }

  Future<void> _loadChildData() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Charger les données depuis SharedPreferences
      final savedAge = prefs.getString('child_age_${widget.childId}');
      final savedGender = prefs.getString('child_gender_${widget.childId}');
      final savedLevel = prefs.getString('child_level_${widget.childId}');
      final savedAcademicYear = prefs.getString('child_academic_year_${widget.childId}');
      final savedAvatarIndex = prefs.getInt('child_avatar_index_${widget.childId}');
      final savedAvatarUrl = prefs.getString('child_avatar_url_${widget.childId}');
      final savedCustomImagePath = prefs.getString('child_custom_image_${widget.childId}');
      
      setState(() {
        _childAge = savedAge ?? '5';
        _childGender = savedGender ?? 'Garçon';
        _childLevel = savedLevel ?? 'Moyenne section';
        _academicYear = savedAcademicYear ?? '2024-2025';
        _avatarIndex = savedAvatarIndex ?? 0;
        _avatarUrl = savedAvatarUrl ?? '';
        
        // Charger l'image personnalisée si elle existe
        if (savedCustomImagePath != null && savedCustomImagePath.isNotEmpty) {
          final imageFile = File(savedCustomImagePath);
          if (imageFile.existsSync()) {
            _selectedImage = imageFile;
            _useCustomImage = true;
          }
        }
      });
      
      // Essayer de charger depuis LocalAuthService
      final currentUser = await _auth.getCurrentUser();
      if (currentUser != null && currentUser.containsKey('children')) {
        final children = currentUser['children'] as List?;
        if (children != null) {
          final child = children.firstWhere(
            (c) => c['id'] == widget.childId,
            orElse: () => {},
          );
          
          if (child.isNotEmpty) {
            setState(() {
              if (child.containsKey('avatarIndex') && child['avatarIndex'] != -1) {
                _avatarIndex = child['avatarIndex'] ?? 0;
                _useCustomImage = false;
              } else if (child.containsKey('customImagePath')) {
                final customPath = child['customImagePath'];
                if (customPath != null && customPath.isNotEmpty) {
                  final imageFile = File(customPath);
                  if (imageFile.existsSync()) {
                    _selectedImage = imageFile;
                    _useCustomImage = true;
                  }
                }
              }
              if (child.containsKey('academicYear')) {
                _academicYear = child['academicYear'] ?? '2024-2025';
              }
            });
          }
        }
      }
      
    } catch (e) {
      print('Erreur chargement données: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStatistics() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Afficher toutes les clés pour déboguer
    print('=== Toutes les clés SharedPreferences ===');
    final keys = prefs.getKeys();
    for (var key in keys) {
      if (key.contains(widget.childId)) {
        print('🔑 $key = ${prefs.get(key)}');
      }
    }
    print('=== Fin debug ===');
    
    setState(() {
      _totalGamesPlayed = prefs.getInt('total_games_${widget.childId}') ?? 0;
      _totalPoints = prefs.getInt('points_${widget.childId}') ?? 0;
      _totalActivities = prefs.getInt('total_activities_${widget.childId}') ?? 0;
      _currentStreak = prefs.getInt('streak_${widget.childId}') ?? 0;
    });
    
    print('📊 Statistiques chargées:');
    print('   Jeux: $_totalGamesPlayed');
    print('   Points: $_totalPoints');
    print('   Activités: $_totalActivities');
    print('   Série: $_currentStreak');
    
  } catch (e) {
    print('Erreur chargement statistiques: $e');
  }
}

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('child_name_${widget.childId}', _childName);
      await prefs.setString('child_age_${widget.childId}', _childAge);
      await prefs.setString('child_gender_${widget.childId}', _childGender);
      await prefs.setString('child_level_${widget.childId}', _childLevel);
      await prefs.setString('child_academic_year_${widget.childId}', _academicYear);
      await prefs.setInt('child_avatar_index_${widget.childId}', _avatarIndex);
      
      if (_useCustomImage && _selectedImage != null) {
        // Sauvegarder l'image personnalisée
        await _auth.saveChildImage(_selectedImage!, widget.childId);
        await prefs.setString('child_custom_image_${widget.childId}', _selectedImage!.path);
      }
      
      await _playFeedback();
      _showMessage('✅ Profil mis à jour avec succès !', isSuccess: true);
      
    } catch (e) {
      _showMessage('❌ Erreur: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAvatar() async {
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
              const Divider(height: 32),
              const Text(
                'Ou choisir un avatar',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _avatars.length,
                  itemBuilder: (context, index) {
                    final avatar = _avatars[index];
                    final isSelected = _avatarIndex == index && !_useCustomImage;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _avatarIndex = index;
                          _useCustomImage = false;
                          _selectedImage = null;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 70,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? (avatar['color'] as Color).withOpacity(0.2) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? avatar['color'] as Color : Colors.grey.shade200,
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
                                decoration: BoxDecoration(
                                  color: avatar['color'] as Color,
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      
      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
          _useCustomImage = true;
        });
        _showMessage('📸 Photo importée !', isSuccess: true);
      }
    } catch (e) {
      _showMessage('Erreur lors de la sélection', isError: true);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      
      if (image != null && mounted) {
        setState(() {
          _selectedImage = File(image.path);
          _useCustomImage = true;
        });
        _showMessage('📸 Photo prise !', isSuccess: true);
      }
    } catch (e) {
      _showMessage('Erreur lors de la prise de photo', isError: true);
    }
  }

  Future<void> _playFeedback() async {
    try {
      await _soundService.playClick();
    } catch (e) {}
  }

  void _showMessage(String message, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : (isSuccess ? Colors.green : Colors.blue),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildAvatarWidget() {
    if (_useCustomImage && _selectedImage != null) {
      return ClipOval(
        child: Image.file(
          _selectedImage!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    } else if (_avatarIndex >= 0 && _avatarIndex < _avatars.length) {
      final avatar = _avatars[_avatarIndex];
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (avatar['color'] as Color).withOpacity(0.3),
              (avatar['color'] as Color).withOpacity(0.1),
            ],
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            avatar['emoji'],
            style: const TextStyle(fontSize: 60),
          ),
        ),
      );
    } else {
      return Container(
        width: 120,
        height: 120,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF4A3AFF)],
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            _childName.isNotEmpty ? _childName[0].toUpperCase() : '👤',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          '👤 Profil de $_childName',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
            tooltip: 'Enregistrer',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildAvatarSection(),
                  const SizedBox(height: 24),
                  _buildInfoSection(),
                  const SizedBox(height: 24),
                  _buildParentInfoSection(), // Nouvelle section parent
                  const SizedBox(height: 24),
                  _buildStatsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildAvatarSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                _buildAvatarWidget(),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Appuyez pour changer la photo',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info, color: Color(0xFF6C63FF), size: 20),
              SizedBox(width: 12),
              Text('Informations personnelles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          
          TextField(
            controller: _nameController,
            onChanged: (value) => _childName = value,
            decoration: InputDecoration(
              labelText: 'Nom de l\'enfant',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _childAge,
            decoration: InputDecoration(
              labelText: 'Âge',
              prefixIcon: const Icon(Icons.cake),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
            ),
            items: _ageOptions.map((age) => DropdownMenuItem(value: age, child: Text('$age ans'))).toList(),
            onChanged: (value) => setState(() => _childAge = value!),
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _childGender,
            decoration: InputDecoration(
              labelText: 'Genre',
              prefixIcon: const Icon(Icons.people),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
            ),
            items: _genderOptions.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
            onChanged: (value) => setState(() => _childGender = value!),
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _childLevel,
            decoration: InputDecoration(
              labelText: 'Niveau scolaire',
              prefixIcon: const Icon(Icons.school),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
            ),
            items: _levelOptions.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
            onChanged: (value) => setState(() => _childLevel = value!),
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _academicYear,
            decoration: InputDecoration(
              labelText: 'Année universitaire',
              prefixIcon: const Icon(Icons.calendar_today),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
            ),
            items: _academicYears.map((year) => DropdownMenuItem(value: year, child: Text(year))).toList(),
            onChanged: (value) => setState(() => _academicYear = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildParentInfoSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.1),
            const Color(0xFF4A3AFF).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6C63FF).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.family_restroom, color: Color(0xFF6C63FF), size: 20),
              SizedBox(width: 12),
              Text('Parent responsable', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_outline, color: Color(0xFF6C63FF), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nom du parent',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      _parentName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Tuteur',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ce parent peut gérer le profil et suivre les progrès de l\'enfant',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4A3AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Statistiques', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('🎮 Jeux', _totalGamesPlayed.toString()),
              _buildStatItem('⭐ Points', _totalPoints.toString()),
              _buildStatItem('📚 Activités', _totalActivities.toString()),
              _buildStatItem('🔥 Série', '$_currentStreak'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  void _navigateToDashboard() {
    Navigator.pop(context, {
      'updated': true,
      'name': _childName,
      'age': _childAge,
      'gender': _childGender,
      'level': _childLevel,
      'academicYear': _academicYear,
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}