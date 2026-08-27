// frontend/lib/features/auth/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider();

  ApiClient? _apiClient;

  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  String? _token;
  String? _userEmail;
  String? _userName;
  String? _userLevel;
  int? _userId;
  String? _userAvatar;
  String? _userBio;
  String? _userSchool;
  String? _userPhone;

  // ============================================================
  //  GETTERS
  // ============================================================

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  String? get token => _token;
  String? get userEmail => _userEmail;
  String? get userName => _userName ?? 'Élève';
  String? get userLevel => _userLevel ?? 'Collège';
  int? get userId => _userId;
  String? get userAvatar => _userAvatar;
  String? get userBio => _userBio;
  String? get userSchool => _userSchool;
  String? get userPhone => _userPhone;

  // ✅ GETTER POUR LA COMPATIBILITÉ AVEC L'ANCIEN CODE
  User? get user {
    if (_userId == null) return null;
    return User(
      id: _userId!,
      email: _userEmail ?? '',
      firstName: _userName?.split(' ').first ?? '',
      lastName: _userName?.split(' ').skip(1).join(' ') ?? '',
      fullName: _userName,
      level: _userLevel,
      avatarUrl: _userAvatar,
      bio: _userBio,
      school: _userSchool,
      phoneNumber: _userPhone,
      isActive: true,
      isVerified: false,
      createdAt: DateTime.now(),
    );
  }

  // ============================================================
  //  INITIALISATION
  // ============================================================

  void setApiClient(ApiClient apiClient) {
    _apiClient = apiClient;
  }

  Future<void> init() async {
    _isInitialized = true;
    notifyListeners();
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
        _token = data['access_token'];
        _isAuthenticated = true;

        // ✅ Récupérer l'utilisateur de la réponse
        if (data['user'] != null) {
          final user = data['user'];
          _userName = user['full_name'] ?? 
                      '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
          _userEmail = user['email'] ?? email;
          _userLevel = user['level'] ?? 'Collège';
          _userId = user['id'];
          _userAvatar = user['avatar_url'];
          _userBio = user['bio'];
          _userSchool = user['school'];
          _userPhone = user['phone_number'];
          
          print('✅ [AuthProvider] Utilisateur chargé: $_userName');
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

  Future<void> _fetchUserProfile() async {
    if (_apiClient == null || _token == null) return;

    try {
      final response = await _apiClient!.get('/auth/me');
      if (response.statusCode == 200) {
        final data = response.data;
        _userName = data['full_name'] ?? 
                    '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim();
        _userEmail = data['email'];
        _userLevel = data['level'] ?? 'Collège';
        _userId = data['id'];
        _userAvatar = data['avatar_url'];
        _userBio = data['bio'];
        _userSchool = data['school'];
        _userPhone = data['phone_number'];
        notifyListeners();
      }
    } catch (e) {
      print('❌ Erreur chargement profil: $e');
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
          'school': school,
          'phone_number': phoneNumber,
        },
      );

      if (response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
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
  //  ✅ UPDATE PROFILE (AJOUTÉ)
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
        final userData = response.data;
        
        // ✅ Mettre à jour les données locales
        _userName = userData['full_name'] ?? 
                    '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim();
        _userEmail = userData['email'];
        _userLevel = userData['level'] ?? 'Collège';
        _userId = userData['id'];
        _userAvatar = userData['avatar_url'];
        _userBio = userData['bio'];
        _userSchool = userData['school'];
        _userPhone = userData['phone_number'];
        
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
  //  LOGOUT
  // ============================================================

  Future<void> logout() async {
    _isAuthenticated = false;
    _token = null;
    _userEmail = null;
    _userName = null;
    _userLevel = null;
    _userId = null;
    _userAvatar = null;
    _userBio = null;
    _userSchool = null;
    _userPhone = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// ============================================================
//  MODÈLE USER (POUR COMPATIBILITÉ)
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
}