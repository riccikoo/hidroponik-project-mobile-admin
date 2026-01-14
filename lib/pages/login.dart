import 'package:flutter/material.dart';
import 'package:hidroponik_project_admin/models/user_model.dart';
import '../services/api.dart';
import '../services/shared.dart';
import 'dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Modern Color Palette
  final Color primaryColor = const Color(0xFF4361EE); // Modern blue
  final Color secondaryColor = const Color(0xFF3A0CA3); // Dark blue
  final Color accentColor = const Color(0xFF4CC9F0); // Light blue
  final Color backgroundColor = const Color(0xFFF8F9FF); // Light background
  final Color surfaceColor = Colors.white;
  final Color textPrimary = const Color(0xFF2B2D42);
  final Color textSecondary = const Color(0xFF8D99AE);

  void _login() async {
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Email dan password wajib diisi");
      setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await ApiService.login(email, password);

      setState(() => _isLoading = false);

      if (result['status'] == true) {
        final token = result['token']?.toString();

        if (token == null || token.isEmpty) {
          _showMessage("Error: Token tidak valid");
          return;
        }

        final userData = result['user'];

        if (userData == null) {
          _showMessage("Error: Data user tidak ditemukan");
          return;
        }

        try {
          final userMap = userData as Map<String, dynamic>;
          final user = User.fromJson(userMap);

          if (user.role?.toLowerCase() != 'admin') {
            _showMessage("Akses ditolak. Hanya admin yang dapat login.");
            return;
          }

          await SharedService.saveLoginData(token, user.toJson());

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardPage()),
          );
        } catch (e) {
          _showMessage("Error memproses data user: $e");
        }
      } else {
        _showMessage(result['message']?.toString() ?? 'Login gagal');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage("Terjadi kesalahan: $e");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 400;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background Pattern
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/pattern.png'), // Buat pattern di Figma
                  fit: BoxFit.cover,
                  opacity: 0.05,
                ),
              ),
            ),
          ),

          // Decorative Circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [accentColor.withOpacity(0.2), Colors.transparent],
                  stops: const [0, 0.8],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [primaryColor.withOpacity(0.1), Colors.transparent],
                  stops: const [0, 0.8],
                ),
              ),
            ),
          ),

          // Main Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Header Section
                    _buildHeaderSection(isSmallScreen),

                    const SizedBox(height: 40),

                    // Login Card
                    _buildLoginCard(isSmallScreen),

                    const SizedBox(height: 32),

                    // Additional Info
                    _buildFooterSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(bool isSmallScreen) {
    return Column(
      children: [
        // Animated Icon Container
        Container(
          width: isSmallScreen ? 80 : 100,
          height: isSmallScreen ? 80 : 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_person_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),

        const SizedBox(height: 24),

        // Title
        Text(
          'HydroGrow Admin',
          style: TextStyle(
            fontSize: isSmallScreen ? 24 : 32,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Dashboard Management System',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Text
          Text(
            'Welcome Back',
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Sign in to continue to your dashboard',
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              color: textSecondary,
            ),
          ),

          const SizedBox(height: 32),

          // Email Field
          _buildInputField(
            label: 'Email Address',
            hintText: 'admin@hydrogrow.com',
            controller: _emailController,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 20),

          // Password Field
          _buildPasswordField(),

          const SizedBox(height: 16),

          // Remember me & Forgot Password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Remember me',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  _showMessage("Contact super admin to reset password");
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: primaryColor,
                ),
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Login Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'SIGN IN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or continue with',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),

          const SizedBox(height: 24),

          // Alternative Login (Optional)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                _showMessage("Alternative login option coming soon");
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                foregroundColor: textPrimary,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fingerprint_rounded, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Use Biometric Login',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              prefixIcon: Icon(
                icon,
                color: primaryColor,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter your password',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: primaryColor,
                size: 20,
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterSection() {
    return Column(
      children: [
        Text(
          '⚠️ Restricted Access',
          style: TextStyle(
            color: Colors.orange.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This dashboard is only accessible to authorized administrators.\nUnauthorized access attempts will be logged.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 16),
        // Footer Text
        Text(
          'HydroGrow System v1.0 • © 2024',
          style: TextStyle(
            color: textSecondary.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}