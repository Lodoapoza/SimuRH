import 'package:flutter/material.dart';
import 'package:simurh/services/auth_service.dart';
import 'package:simurh/services/update_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;
  bool _initialCheck = true;

  // Login fields
  final _loginPhone = TextEditingController();
  final _loginPassword = TextEditingController();

  // Register fields
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPhone = TextEditingController();
  final _regPassword = TextEditingController();
  final _regConfirm = TextEditingController();
  final _regEstName = TextEditingController();
  final _regEstCity = TextEditingController();
  String _regRole = 'student';

  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkLoggedIn();
  }

  Future<void> _checkLoggedIn() async {
    final auth = AuthService();
    final user = await auth.getCurrentUser();
    if (user != null && mounted) {
      _redirectUser(user);
    } else {
      setState(() => _initialCheck = false);
    }
    // Vérifier les mises à jour en arrière-plan
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    try {
      final url = await UpdateService().checkForUpdate();
      if (url != null && mounted) {
        _showUpdateDialog(url);
      }
    } catch (_) {
      // Échec silencieux
    }
  }

  void _showUpdateDialog(String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Mise à jour disponible'),
        content: const Text(
          'Une nouvelle version de SimuRH est disponible. '
          'Voulez-vous la télécharger maintenant ?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              UpdateService().markNotified();
            },
            child: const Text('Plus tard'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              UpdateService().openDownloadUrl(url);
              UpdateService().markNotified();
            },
            child: const Text('Télécharger'),
          ),
        ],
      ),
    );
  }

  void _redirectUser(User user) {
    if (user.role == 'professor') {
      Navigator.pushReplacementNamed(context, '/professor/dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/student/home');
    }
  }

  Future<void> _login() async {
    if (_loginPhone.text.isEmpty || _loginPassword.text.isEmpty) {
      setState(() => _error = 'Téléphone et mot de passe requis');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final auth = AuthService();
      final user = await auth.login(_loginPhone.text, _loginPassword.text);
      if (user != null && mounted) _redirectUser(user);
      else setState(() => _error = 'Identifiants incorrects');
    } catch (e) {
      setState(() => _error = 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    if (_regName.text.isEmpty || _regPhone.text.isEmpty || _regPassword.text.isEmpty || _regEstName.text.isEmpty) {
      setState(() => _error = 'Tous les champs marqués * sont requis');
      return;
    }
    if (_regPassword.text != _regConfirm.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas');
      return;
    }
    if (_regPassword.text.length < 4) {
      setState(() => _error = 'Mot de passe trop court (min 4)');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final auth = AuthService();
      final user = await auth.register(
        _regName.text, _regPhone.text, _regPassword.text,
        _regRole, _regEstName.text, _regEstCity.text,
      );
      if (user != null && mounted) _redirectUser(user);
      else setState(() => _error = 'Erreur lors de l\'inscription');
    } catch (e) {
      setState(() => _error = 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginPhone.dispose();
    _loginPassword.dispose();
    _regName.dispose();
    _regEmail.dispose();
    _regPhone.dispose();
    _regPassword.dispose();
    _regConfirm.dispose();
    _regEstName.dispose();
    _regEstCity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initialCheck) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SimuRH'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Connexion'), Tab(text: 'Inscription')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildLoginTab(), _buildRegisterTab()],
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.school, size: 64, color: Theme.of(context).primaryColor),
          const SizedBox(height: 24),
          TextField(
            controller: _loginPhone,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _loginPassword,
            decoration: const InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            onSubmitted: (_) => _login(),
          ),
          if (_error != null) Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Se connecter', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          TextField(
            controller: _regName,
            decoration: const InputDecoration(
              labelText: 'Nom complet *',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _regPhone,
            decoration: const InputDecoration(
              labelText: 'Téléphone *',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _regEmail,
            decoration: const InputDecoration(
              labelText: 'Email (optionnel)',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _regPassword,
            decoration: const InputDecoration(
              labelText: 'Mot de passe *',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _regConfirm,
            decoration: const InputDecoration(
              labelText: 'Confirmer le mot de passe *',
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          const Text('Rôle *', style: TextStyle(fontWeight: FontWeight.w500)),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Professeur'),
                  value: 'professor',
                  groupValue: _regRole,
                  onChanged: (v) => setState(() => _regRole = v!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Étudiant'),
                  value: 'student',
                  groupValue: _regRole,
                  onChanged: (v) => setState(() => _regRole = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Établissement *', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _regEstName,
            decoration: const InputDecoration(
              hintText: 'Nom de l\'établissement',
              prefixIcon: Icon(Icons.business),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _regEstCity,
            decoration: const InputDecoration(
              hintText: 'Ville',
              prefixIcon: Icon(Icons.location_city),
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Créer mon compte', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
