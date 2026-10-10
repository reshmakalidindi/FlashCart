import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'api_config.dart';

class AuthService {
  // Safe lazy getters for Firebase instances if configured
  FirebaseAuth? get _auth {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance;
      }
    } catch (_) {}
    return null;
  }

  // Active user session state
  UserModel? _currentUserModel;
  String? _jwtToken;
  bool _isDemoMode = false;

  bool get isDemoMode => _isDemoMode;
  UserModel? get currentMockUser => _currentUserModel;
  String? get jwtToken => _jwtToken;

  Stream<User?> get authStateChanges {
    final auth = _auth;
    if (auth != null) {
      return auth.authStateChanges();
    }
    return Stream.value(null);
  }

  User? get currentUser => _auth?.currentUser;

  Future<UserModel?> getCurrentUserProfile() async {
    return _currentUserModel;
  }

  /// Signs in via FastAPI backend: POST /api/v1/auth/login
  /// Falls back to local credentials/demo mode if server is offline.
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _jwtToken = data['access_token'];
        final userObj = data['user'];
        final isStaff = (userObj['role'] == 'staff' || userObj['role'] == 'admin');

        _currentUserModel = UserModel(
          uid: userObj['user_id'] ?? 'usr_1',
          email: userObj['email'] ?? email,
          displayName: userObj['full_name'] ?? 'Shopper',
          isStaff: isStaff,
          createdAt: DateTime.now(),
        );
        _isDemoMode = false;
        debugPrint('Signed in successfully via FastAPI backend: ${_currentUserModel!.email} (staff: $isStaff)');
        return _currentUserModel!;
      }
    } catch (e) {
      debugPrint('FastAPI login attempt failed ($e), falling back to demo session.');
    }

    // Demo fallback session
    _isDemoMode = true;
    final isStaff = email.toLowerCase().contains('staff');
    _currentUserModel = UserModel(
      uid: 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: isStaff ? 'Store Staff' : (email.split('@').first),
      isStaff: isStaff,
      createdAt: DateTime.now(),
    );
    return _currentUserModel!;
  }

  /// Signs up via FastAPI backend: POST /api/v1/auth/register
  Future<UserModel> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    bool isStaff = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'full_name': name.trim(),
          'role': isStaff ? 'staff' : 'customer',
        }),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 201) {
        final userObj = jsonDecode(response.body);
        _currentUserModel = UserModel(
          uid: userObj['user_id'] ?? 'usr_new',
          email: userObj['email'] ?? email,
          displayName: userObj['full_name'] ?? name,
          isStaff: isStaff,
          createdAt: DateTime.now(),
        );
        _isDemoMode = false;
        debugPrint('Registered successfully via FastAPI backend: ${_currentUserModel!.email}');
        return _currentUserModel!;
      }
    } catch (e) {
      debugPrint('FastAPI registration attempt failed ($e), using local session.');
    }

    _isDemoMode = true;
    _currentUserModel = UserModel(
      uid: 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: name,
      isStaff: isStaff,
      createdAt: DateTime.now(),
    );
    return _currentUserModel!;
  }

  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (_) {}
    _currentUserModel = null;
    _jwtToken = null;
    _isDemoMode = false;
  }
}
