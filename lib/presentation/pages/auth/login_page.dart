import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitshare/domain/entities/user_entity.dart';
import 'package:habitshare/presentation/providers/auth_provider.dart';
import 'package:habitshare/presentation/providers/social_provider.dart';

// Constants for the Premium Dark Theme
const _kBackgroundColor = Color(0xFF131313);
const _kPrimaryColor = Color(0xFFDAB9FF);
const _kPrimaryContainerColor = Color(0xFFBB86FC);
const _kOnPrimaryContainerColor = Color(0xFF4C0F89);
const _kSecondaryColor = Color(0xFF46F5E0);
const _kOnSurfaceColor = Color(0xFFE2E2E2);
const _kOnSurfaceVariantColor = Color(0xFFCDC3D4);
const _kOutlineVariantColor = Color(0xFF4B4452);
const _kOutlineColor = Color(0xFF978D9D);
const _kSurfaceContainerLowest = Color(0xFF0A0A0A);
const _kHintColor = Color(0xFF5E5E5E);

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.fill;
      
    const double spacing = 48.0;
    const double radius = 1.0; 
    
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isRegistering = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuthSuccess(UserEntity user) async {
    var profile = user;
    if (_isRegistering) {
      final name = _nameController.text.trim();
      if (name.isNotEmpty &&
          (profile.displayName == null ||
              profile.displayName!.trim().isEmpty)) {
        profile = profile.copyWith(displayName: name);
      }
    }
    await ref.read(socialRepositoryProvider).upsertUserProfile(profile);
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (_isRegistering && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = _isRegistering
        ? await ref.read(authRepositoryProvider).registerWithEmail(
              email: email,
              password: password,
              displayName: name,
            )
        : await ref.read(authRepositoryProvider).signInWithEmail(
              email: email,
              password: password,
            );

    if (mounted) {
      setState(() => _isLoading = false);
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        },
        _handleAuthSuccess,
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      final result = await ref.read(authRepositoryProvider).signInWithGoogle();
      if (!mounted) {
        return;
      }
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        },
        _handleAuthSuccess,
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  bool get _isBusy => _isLoading || _isGoogleLoading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      body: Stack(
        children: [
          // Dot Grid Overlay (opacity 0.2)
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: CustomPaint(
                painter: _DotGridPainter(),
              ),
            ),
          ),
          // Background Glow Effects
          Positioned(
            top: MediaQuery.of(context).size.height * -0.15,
            right: MediaQuery.of(context).size.width * -0.10,
            child: Container(
              width: 700,
              height: 700,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x1ABB86FC),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.7],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * -0.10,
            left: MediaQuery.of(context).size.width * -0.05,
            child: Container(
              width: 500,
              height: 500,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x0D46F5E0),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.7],
                ),
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Text(
                        _isRegistering ? 'Create Account' : 'Welcome back',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: _kPrimaryContainerColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isRegistering 
                            ? 'Join the ranks of high-achievers. Start your momentum today.'
                            : 'Log in to continue your journey.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: _kOnSurfaceVariantColor,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Glass Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: _kSurfaceContainerLowest.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                                width: 1,
                              ),
                            ),
                            child: _buildForm(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isRegistering
                                ? 'Already have an account? '
                                : 'Don\'t have an account? ',
                            style: const TextStyle(
                              color: _kOnSurfaceVariantColor,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: _isBusy ? null : () {
                              setState(() {
                                _isRegistering = !_isRegistering;
                                // Clear inputs on switch
                                _emailController.clear();
                                _passwordController.clear();
                                _nameController.clear();
                              });
                            },
                            child: Text(
                              _isRegistering ? 'Sign in' : 'Sign up',
                              style: const TextStyle(
                                color: _kPrimaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Google Button
        OutlinedButton.icon(
          onPressed: _isBusy ? null : _handleGoogleSignIn,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: _kOutlineVariantColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            foregroundColor: _kOnSurfaceColor,
          ),
          icon: _isGoogleLoading 
              ? const SizedBox(
                  width: 20, height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimaryColor)
                )
              : Image.asset(
                  'assets/images/google_logo.png',
                  width: 24,
                  height: 24,
                ),
          label: const Text('Continue with Google', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 24),
        // Divider
        Row(
          children: [
            const Expanded(child: Divider(color: _kOutlineVariantColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: const TextStyle(
                  color: _kOutlineColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const Expanded(child: Divider(color: _kOutlineVariantColor)),
          ],
        ),
        const SizedBox(height: 24),
        
        if (_isRegistering) ...[
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_outline,
            hintText: 'Alex Sterling',
          ),
          const SizedBox(height: 16),
        ],
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.mail_outline,
          hintText: 'name@example.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock_outline,
          hintText: '••••••••',
          obscureText: _obscurePassword,
          isPassword: true,
        ),
        const SizedBox(height: 32),
        // Submit Button
        ElevatedButton(
          onPressed: _isBusy ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimaryContainerColor,
            foregroundColor: _kOnPrimaryContainerColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isLoading 
              ? const SizedBox(
                  width: 20, height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: _kOnPrimaryContainerColor)
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isRegistering ? 'Register Account' : 'Continue',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    if (!_isRegistering) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20),
                    ]
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: _kOnSurfaceVariantColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _kPrimaryContainerColor,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            enabled: !_isBusy,
            style: const TextStyle(color: _kOnSurfaceColor, fontSize: 16),
            cursorColor: _kPrimaryContainerColor,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: _kHintColor),
              prefixIcon: Icon(icon, color: _kOutlineColor),
              suffixIcon: isPassword ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: _kOutlineColor,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ) : null,
              filled: false,
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _kOutlineVariantColor),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: _kPrimaryContainerColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
