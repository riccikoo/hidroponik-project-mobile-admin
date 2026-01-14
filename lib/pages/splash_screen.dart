import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<Offset> _textSlideAnimation;

  // Modern Color Palette (sama dengan login page)
  final Color primaryColor = const Color(0xFF4361EE); // Modern blue
  final Color secondaryColor = const Color(0xFF3A0CA3); // Dark blue
  final Color accentColor = const Color(0xFF4CC9F0); // Light blue
  final Color backgroundColor = const Color(0xFFF8F9FF); // Light background
  final Color surfaceColor = Colors.white;
  final Color textPrimary = const Color(0xFF2B2D42);
  final Color textSecondary = const Color(0xFF8D99AE);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Fade animation untuk seluruh konten
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Scale animation untuk logo
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    // Rotation animation untuk logo (subtle)
    _logoRotationAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Slide animation untuk text
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // Navigate setelah animasi selesai
    Timer(
      const Duration(milliseconds: 2500),
      () => _redirectToLogin(),
    );
  }

  Future<void> _redirectToLogin() async {
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/login',
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Animated Background Pattern
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value * 0.1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          primaryColor.withOpacity(0.3),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.8],
                        center: Alignment.center,
                        radius: 1.0,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Floating Particles
          ..._buildFloatingParticles(),

          // Main Content
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo Container
                    Transform.rotate(
                      angle: _logoRotationAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryColor, secondaryColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(35),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.4),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Inner Shadow Effect
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(35),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.2),
                                        Colors.transparent,
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.1),
                                      ],
                                      stops: const [0, 0.3, 0.7, 1],
                                    ),
                                  ),
                                ),
                                // Icon
                                Center(
                                  child: Icon(
                                    Icons.admin_panel_settings_rounded,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Animated Text Content
                    SlideTransition(
                      position: _textSlideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              'HydroGrow',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: textPrimary,
                                letterSpacing: -0.5,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ADMIN SYSTEM',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Loading Progress
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: SizedBox(
                        width: 120,
                        child: Column(
                          children: [
                            // Progress Bar
                            Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _animationController.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [primaryColor, accentColor],
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Loading Text
                            Text(
                              'Initializing System...',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Footer
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Powered by Text
                  Text(
                    'Powered by HydroGrow Technology',
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Version Text
                  Text(
                    'v1.0.0 • © 2024',
                    style: TextStyle(
                      fontSize: 10,
                      color: textSecondary.withOpacity(0.5),
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

  List<Widget> _buildFloatingParticles() {
    final particles = <Widget>[];

    // Create multiple floating particles
    for (int i = 0; i < 8; i++) {
      particles.add(
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final size = 8.0 + (i * 2.0);
              final xPos = 0.2 + (i * 0.1);
              final yPos = 0.3 + (i * 0.08);
              final duration = 3.0 + (i * 0.5);
              final offset = (DateTime.now().millisecondsSinceEpoch / 1000) %
                  (duration * 2 * 3.14);

              return Transform.translate(
                offset: Offset(
                  MediaQuery.of(context).size.width * xPos +
                      sin(offset) * 20,
                  MediaQuery.of(context).size.height * yPos +
                      cos(offset) * 15,
                ),
                child: Opacity(
                  opacity: 0.15 + (i * 0.02),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: [
                        primaryColor,
                        accentColor,
                        secondaryColor,
                      ][i % 3],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return particles;
  }
}