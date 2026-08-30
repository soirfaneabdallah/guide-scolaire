

// frontend/lib/features/auth/providers/auth_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _initStorage();
  }

  ApiClient? _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  // ============================================================
  //  ÉTATS
  // ============================================================

  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  String? _token;
  User? _user;

  // ============================================================
  //  GETTERS
  // ============================================================

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  String? get token => _token;
  User? get user => _user;

  // ✅ Getters de compatibilité (pour l'ancien code)
  String? get userEmail => _user?.email;
  String? get userName => _user?.fullName ?? _user?.firstName ?? 'Élève';
  String? get userLevel => _user?.level ?? 'Collège';
  int? get userId => _user?.id;
  String? get userAvatar => _user?.avatarUrl;
  String? get userBio => _user?.bio;
  String? get userSchool => _user?.school;
  String? get userPhone => _user?.phoneNumber;

  // ============================================================
  //  INITIALISATION
  // ============================================================

  Future<void> _initStorage() async {
    try {
      // Récupérer le token stocké
      final storedToken = await _storage.read(key: _tokenKey);
      if (storedToken != null && storedToken.isNotEmpty) {
        _token = storedToken;
        _isAuthenticated = true;
        
        // Charger le profil utilisateur
        if (_apiClient != null) {
          await _fetchUserProfile();
        }
      }
    } catch (e) {
      print('❌ Erreur lecture storage: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  void setApiClient(ApiClient apiClient) {
    _apiClient = apiClient;
    // Si déjà authentifié, charger le profil
    if (_isAuthenticated && _token != null) {
      _fetchUserProfile();
    }
  }

  // ============================================================
  //  STOCKAGE TOKEN
  // ============================================================

  Future<void> _saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    _token = token;
    _isAuthenticated = true;
  }

  Future<void> _clearToken() async {
    await _storage.delete(key: _tokenKey);
    _token = null;
    _isAuthenticated = false;
  }

  // ============================================================
  //  LOGIN
  // ============================================================

  Future<bool> login(String email, String password) async {
    if (_apiClient == null) {
      _error = 'ApiClient non initialisé';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient!.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['access_token'];
        
        await _saveToken(token);
        
        // ✅ Récupérer l'utilisateur
        if (data['user'] != null) {
          _user = User.fromJson(data['user']);
        } else {
          await _fetchUserProfile();
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erreur de connexion';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      _error = e.response?.data['detail'] ?? 'Erreur réseau';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  //  REGISTER
  // ============================================================

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String level,
    String? school,
    String? phoneNumber,
  }) async {
    if (_apiClient == null) {
      _error = 'ApiClient non initialisé';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient!.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'level': level,
          if (school != null) 'school': school,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        },
      );

      if (response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        // ✅ Connexion automatique après inscription
        return await login(email, password);
      } else {
        _error = 'Erreur lors de l\'inscription';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      _error = e.response?.data['detail'] ?? 'Erreur réseau';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  //  FETCH USER PROFILE
  // ============================================================

  Future<void> _fetchUserProfile() async {
    if (_apiClient == null || _token == null) return;

    try {
      final response = await _apiClient!.get('/auth/me');
      if (response.statusCode == 200) {
        _user = User.fromJson(response.data);
        notifyListeners();
      }
    } catch (e) {
      print('❌ Erreur chargement profil: $e');
    }
  }

  // ✅ Méthode publique pour recharger le profil
  Future<void> loadUserProfile() async {
    await _fetchUserProfile();
  }

  // ============================================================
  //  ✅ UPDATE PROFILE
  // ============================================================

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? level,
    String? school,
    String? phoneNumber,
    String? bio,
    String? avatarUrl,
  }) async {
    if (_apiClient == null) {
      _error = 'ApiClient non initialisé';
      notifyListeners();
      return false;
    }

    if (_token == null) {
      _error = 'Vous devez être connecté';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (level != null) 'level': level,
        if (school != null) 'school': school,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (bio != null) 'bio': bio,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };

      final response = await _apiClient!.put(
        '/auth/me',
        data: data,
      );

      if (response.statusCode == 200) {
        _user = User.fromJson(response.data);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erreur lors de la mise à jour du profil';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      _error = e.response?.data['detail'] ?? 'Erreur réseau';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  //  ✅ UPLOAD AVATAR
  // ============================================================

  Future<String?> uploadAvatar(File imageFile) async {
    if (_apiClient == null || _token == null) {
      _error = 'Vous devez être connecté';
      notifyListeners();
      return null;
    }

    try {
      // Lire les bytes du fichier
      final bytes = await imageFile.readAsBytes();
      
      // Créer le FormData
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });

      final response = await _apiClient!.post(
        '/auth/me/avatar',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final avatarUrl = data['avatar_url'];
        
        // ✅ Mettre à jour l'utilisateur
        if (_user != null) {
          _user = _user!.copyWith(avatarUrl: avatarUrl);
          notifyListeners();
        }
        
        return avatarUrl;
      } else {
        _error = 'Erreur lors de l\'upload';
        notifyListeners();
        return null;
      }
    } on DioException catch (e) {
      _error = e.response?.data['detail'] ?? 'Erreur réseau';
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ============================================================
  //  ✅ DELETE ACCOUNT
  // ============================================================

  Future<bool> deleteAccount() async {
    if (_apiClient == null || _token == null) {
      _error = 'Vous devez être connecté';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient!.delete('/auth/me');

      if (response.statusCode == 200 || response.statusCode == 204) {
        await logout();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erreur lors de la suppression du compte';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      _error = e.response?.data['detail'] ?? 'Erreur réseau';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  //  LOGOUT
  // ============================================================

  Future<void> logout() async {
    await _clearToken();
    _user = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // ============================================================
  //  UTILITAIRES
  // ============================================================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ✅ Recharger les données utilisateur depuis le serveur
  Future<void> refreshUser() async {
    if (_token != null) {
      await _fetchUserProfile();
    }
  }
}

// ============================================================
//  MODÈLE USER
// ============================================================

class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? fullName;
  final String? level;
  final String? avatarUrl;
  final String? bio;
  final String? school;
  final String? phoneNumber;
  final String? role;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.fullName,
    this.level,
    this.avatarUrl,
    this.bio,
    this.school,
    this.phoneNumber,
    this.role,
    this.isActive = true,
    this.isVerified = false,
    required this.createdAt,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ??
          '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      level: json['level'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      school: json['school'],
      phoneNumber: json['phone_number'],
      role: json['role'],
      isActive: json['is_active'] ?? true,
      isVerified: json['is_verified'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'level': level,
      'avatar_url': avatarUrl,
      'bio': bio,
      'school': school,
      'phone_number': phoneNumber,
      'role': role,
      'is_active': isActive,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? fullName,
    String? level,
    String? avatarUrl,
    String? bio,
    String? school,
    String? phoneNumber,
    String? role,
    bool? isActive,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      level: level ?? this.level,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      school: school ?? this.school,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}