import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import 'auth_service.dart';

enum AuthGateStage {
  checkingAuth,
  unauthenticated,
  loadingProfile,
  authenticated,
  permissionDenied,
  error,
}

class AuthGateController extends ChangeNotifier {
  StreamSubscription<User?>? _authSub;
  StreamSubscription<UserModel?>? _profileSub;

  AuthGateStage _stage = AuthGateStage.checkingAuth;
  User? _firebaseUser;
  UserModel? _userModel;
  String? _errorMessage;

  AuthGateStage get stage => _stage;
  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  String? get errorMessage => _errorMessage;

  void start() {
    _authSub ??= AuthService.authStateChanges.listen(_handleAuthStateChange);
  }

  Future<void> _handleAuthStateChange(User? user) async {
    _firebaseUser = user;
    _userModel = null;
    _errorMessage = null;

    await _profileSub?.cancel();
    _profileSub = null;

    if (user == null) {
      _stage = AuthGateStage.unauthenticated;
      notifyListeners();
      return;
    }

    _stage = AuthGateStage.loadingProfile;
    notifyListeners();

    try {
      final ensured = await AuthService.ensureUserModel(user);
      if (ensured == null) {
        _stage = AuthGateStage.error;
        _errorMessage = 'Unable to create or load your account profile.';
        notifyListeners();
        return;
      }

      _profileSub = AuthService.userModelStream(user.uid).listen(
        (model) {
          if (model == null) {
            _stage = AuthGateStage.loadingProfile;
            _userModel = null;
          } else {
            _stage = AuthGateStage.authenticated;
            _userModel = model;
          }
          notifyListeners();
        },
        onError: (error) {
          final msg = '$error';
          _errorMessage = msg;
          _stage = _isPermissionDenied(msg)
              ? AuthGateStage.permissionDenied
              : AuthGateStage.error;
          notifyListeners();
        },
      );
    } catch (error) {
      final msg = '$error';
      _errorMessage = msg;
      _stage = _isPermissionDenied(msg)
          ? AuthGateStage.permissionDenied
          : AuthGateStage.error;
      notifyListeners();
    }
  }

  bool _isPermissionDenied(String message) {
    return message.contains('permission-denied') ||
        message.contains('PERMISSION_DENIED');
  }

  Future<void> signOut() => AuthService.signOut();

  @override
  void dispose() {
    _profileSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
