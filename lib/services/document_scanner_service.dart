import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DocumentScannerService {
  final ImagePicker _picker = ImagePicker();

  // Simuler un scanner de document en utilisant l'image picker
  Future<File?> scanDocument() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Erreur: $e');
      return null;
    }
  }

  // Scanner depuis la galerie
  Future<File?> scanFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Erreur: $e');
      return null;
    }
  }

  // Scanner plusieurs images
  Future<List<File>?> scanMultiplePages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 90,
      );
      
      if (images.isNotEmpty) {
        return images.map((img) => File(img.path)).toList();
      }
      return null;
    } catch (e) {
      print('Erreur: $e');
      return null;
    }
  }

  void dispose() {
    // Rien à fermer
  }
}