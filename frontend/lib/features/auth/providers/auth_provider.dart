// frontend/lib/features/auth/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
//import '../../../core/config/environment.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  String? _token;
  String? _userEmail;
  String? _userName;
  String? _userLevel;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  String? get token => _token;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get userLevel => _userLevel;

  AuthProvider() {
    _init();
  }

  void _init() {
    // TODO: Vérifier le token stocké localement
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiClient.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        _token = data['access_token'];
        _userEmail = email;
        _userName = 'Utilisateur'; // Sera remplacé par le vrai nom
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();

        // Récupérer les infos du profil après connexion
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
    try {
      final response = await apiClient.get('/auth/me');
      if (response.statusCode == 200) {
        final data = response.data;
        _userName = '${data['first_name']} ${data['last_name']}';
        _userLevel = data['level'];
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiClient.post(
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
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}