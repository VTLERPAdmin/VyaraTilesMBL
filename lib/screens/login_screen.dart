import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/loader_service.dart';
import '../services/api_services.dart';
import '../services/session_manager.dart';
import '../screens/dashboard_screen.dart';
import '../widgets/no_internet_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  bool loading = false;
  bool rememberMe = true;
  bool obscurePassword = true;
  bool hasConnectionError = false;

  @override
  void initState() {
    super.initState();
    loadSavedUser();
    _checkConnectivity();
  }

  // Quick probe against our own server, so we know connectivity is
  // actually good enough to reach the login API — not just that the
  // device has *some* network. A generic DNS check (e.g. google.com)
  // could say "online" even if our server is unreachable.
  Future<void> _checkConnectivity() async {
    try {
      await http
          .get(Uri.parse("https://vyaratiles.co.in/Api/ERPAuth"))
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;
      setState(() => hasConnectionError = false);
    } catch (e) {
      if (!mounted) return;
      if (_isConnectionError(e)) {
        setState(() => hasConnectionError = true);
      }
      // Non-connection errors here (e.g. a 4xx/5xx from hitting the
      // endpoint with no params) are fine — they still prove the
      // server is reachable, so we don't treat them as offline.
    }
  }

  Future<void> loadSavedUser() async {
  final prefs = await SharedPreferences.getInstance();

  String lastUser =
      prefs.getString("lastUserId") ?? "";

  setState(() {
    userController.text = lastUser;
    passController.clear();
  });
}

  // True only for genuine connectivity failures (no network, timeout,
  // DNS/socket errors) — NOT for wrong-password or other API-level
  // failures, which arrive as a normal 200 response with a failure
  // message and never reach this check.
  bool _isConnectionError(Object e) {
    return e is SocketException ||
        e is TimeoutException ||
        e is HttpException ||
        e.toString().contains("Failed host lookup") ||
        e.toString().contains("Connection refused") ||
        e.toString().contains("Connection timed out") ||
        e.toString().contains("Network is unreachable");
  }

  Future<void> login() async {
    if (userController.text.isEmpty || passController.text.isEmpty) {
      if (hasConnectionError) {
        // We were on the No-Internet screen (likely because the user
        // never got a chance to type their password before it took
        // over on first load). Send them back to the login form so
        // they can actually fill it in, instead of silently staying
        // put with no visible change.
        setState(() => hasConnectionError = false);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter User ID & Password")),
      );
      return;
    }

     LoaderService.show(
    context,
    title: "Logging In",
    subtitle: "Please wait...",
  );

    try {
      final response = await ApiService.login(
        userController.text.trim(),
        passController.text.trim(),
      );

      LoaderService.hide();

      if (!mounted) return;

      setState(() => hasConnectionError = false);

      if (response["StatusCode"] == 200) {
        await SessionManager.saveSession(
          userId: userController.text.trim(),
          password: passController.text.trim(),
          userData: response,
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response["Message"])),
        );
      }
    } catch (e) {
      LoaderService.hide();

      if (!mounted) return;

      if (_isConnectionError(e)) {
        setState(() => hasConnectionError = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please turn on your internet")),
        );
      } else {
        // Reaching here means the failure wasn't a connectivity issue
        // (it's some other error — parsing, server-side, etc.), so
        // connectivity itself is fine. Make sure we're not stuck on
        // NoInternetScreen with no way back to the form.
        if (hasConnectionError) {
          setState(() => hasConnectionError = false);
        }
        debugPrint("LOGIN ERROR: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (hasConnectionError) {
      return NoInternetScreen(
        onRetry: () {
          // Don't clear hasConnectionError here — only login() should
          // decide that, based on whether the retry actually succeeds
          // or fails again (or, if fields are empty, login() routes
          // back to the form itself so the user can type in).
          login();
        },
      );
    }

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      body: isDesktop
          ? _buildDesktopLogin(context)
          : _buildMobileLogin(context), // ✅ ONLY MOBILE CHANGED
    );
  }

  // =====================================================
  // DESKTOP UI (UNCHANGED)
  // =====================================================
  Widget _buildDesktopLogin(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
  Expanded(
    flex: 2,
    child: Container(
      color: const Color(0xFF06224D),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // ✅ LOGO (optional - you can remove if not needed)
             Image.asset(
               "assets/logo_app.png",
              width: 90,
               height: 90,
            ),

            const SizedBox(height: 5),

            const Text(
              "Vyara Tiles ERP",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Enterprise Resource Planning System",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ),
  ),

      
        Expanded(
          flex: 3,
          child: Container(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF111827) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Login",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 25),

                      TextField(
                        controller: userController,
                        decoration: const InputDecoration(
                          labelText: "User ID",
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: passController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF06224D),
                          ),
                          onPressed: loading ? null : login,
                         child: const Text(
                            "LOGIN",
                            style: TextStyle(color: Colors.white),
                          ),

                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // MOBILE UI (REPLACED WITH YOUR DESIGN)
  // =====================================================
  Widget _buildMobileLogin(BuildContext context) {
  final size = MediaQuery.of(context).size;

  return Scaffold(
    resizeToAvoidBottomInset: false,
    backgroundColor: const Color(0xFF06224D), // SAME AS DESKTOP
    body: Stack(
      children: [

  Positioned(
  top: size.height * 0.21,
  left: 0,
  right: 0,
  child: Padding(
    padding: const EdgeInsets.only(right: 25),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [

        // VYARA + Tiles
        Column(
          mainAxisSize: MainAxisSize.min,
          children:  [

            Image.asset(
               "assets/logo_app.png",
              width: 80,
               height: 80,
            ),

             const SizedBox(height: 1),

           const Text(
              "Vyara ERP ",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),

          /*  Text(
              "ERP system",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ), */
          ],
        ),

        const SizedBox(height: 3),

        // WHITE UNDERLINE
       Container(
          width: 131,
          height: 2,
          color: Colors.white,
        ), 
      ],
    ),
  ),
),
// WHITE CURVED AREA ONLY (NO PATTERN, NO CIRCLE)
        Positioned(
          top: size.height * 0.32,
          left: 0,
          right: 0,
          bottom: 0,
          
          child: ClipPath(
            clipper: WaveClipper(),
            child: Container(
              color: Colors.white,
              child: SafeArea(
                top: false,
                
                
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.08,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const SizedBox(height: 60),

                        // SIGN IN
                        Text(
                          "Sign in",
                          style: TextStyle(
                            fontSize: size.width * 0.07,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Container(
                          width: 60,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFF06224D), // desktop color
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        SizedBox(height: size.height * 0.05),

                        // USER ID
                        const Text("User ID"),
                        TextField(
                          controller: userController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person_outline),
                            hintText: "Enter User ID",
                            border: UnderlineInputBorder(),
                          ),
                        ),

                        SizedBox(height: size.height * 0.03),

                        // PASSWORD
                        const Text("Password"),
                        TextField(
                          controller: passController,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                            hintText: "Enter Password",
                            border: const UnderlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // LOGIN BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: loading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF06224D), // desktop color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                           child: const Text(
                            "LOGIN",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),                 
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}

// ===================== WAVE CLIPPER =====================
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.lineTo(0, 70);

    path.quadraticBezierTo(
      size.width * 0.20,
      0,
      size.width * 0.45,
      45,
    );

    path.quadraticBezierTo(
      size.width * 0.75,
      105,
      size.width,
      35,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);

    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ===================== PATTERN =====================
class ContourPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (double y = -100; y < size.height; y += 80) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.20, y),
          width: 180,
          height: 80,
        ),
        paint,
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.75, y + 30),
          width: 250,
          height: 100,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}