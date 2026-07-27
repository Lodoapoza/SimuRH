import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simurh/services/license_service.dart';

enum AuthRole { professor, student, none }

class AuthState {
  final AuthRole role;
  final bool isLicensed;
  final LicenseInfo? license;
  final String profName;

  const AuthState({
    this.role = AuthRole.none,
    this.isLicensed = false,
    this.license,
    this.profName = '',
  });

  bool get isAuthenticated => role != AuthRole.none;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> checkLicense() async {
    final ok = await LicenseService.isValid();
    final license = await LicenseService.getLicense();
    final prefs = await SharedPreferences.getInstance();
    final profName = prefs.getString('prof_name') ?? '';
    state = AuthState(
      role: ok ? AuthRole.professor : AuthRole.none,
      isLicensed: ok,
      license: license,
      profName: profName,
    );
  }

  Future<void> setRole(AuthRole role) async {
    state = AuthState(role: role);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
