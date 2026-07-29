// frontend/lib/features/auth/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class AuthProvider extends ChangeNotifier {
  // Constructeur sans paramètre (ApiClient sera injecté plus tard)
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

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  String? get token => _token;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get userLevel => _userLevel;
  int? get userId => _userId;

  // 🔧 Méthode pour injecter ApiClient après la création
  void setApiClient(ApiClient apiClient) {
    _apiClient = apiClient;
  }

  // 🔧 Méthode d'initialisation
  Future<void> init() async {
    // TODO: Charger la session depuis le stockage local (SharedPreferences)
    _isInitialized = true;
    notifyListeners();
  }

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
        _userEmail = email;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();

        await _fetchUserProfile();
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
    if (_apiClient == null) return;

    try {
      final response = await _apiClient!.get('/auth/me');
      if (response.statusCode == 200) {
        final data = response.data;
        _userName = '${data['first_name']} ${data['last_name']}';
        _userLevel = data['level'];
        _userId = data['id'];
        notifyListeners();
      }
    } catch (e) {
      // On garde les valeurs par défaut
    }
  }

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
        return true;
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

  Future<void> logout() async {
    _isAuthenticated = false;
    _token = null;
    _userEmail = null;
    _userName = null;
    _userLevel = null;
    _userId = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}