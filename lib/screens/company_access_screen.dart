
import 'package:flutter/material.dart';

import 'login_screen.dart';

class CompanyAccessScreen extends StatefulWidget {
  const CompanyAccessScreen({super.key});

  @override
  State<CompanyAccessScreen> createState() =>
      _CompanyAccessScreenState();
}

class _CompanyAccessScreenState extends State<CompanyAccessScreen> {
  final TextEditingController _passkeyController =
      TextEditingController();

  bool _obscurePasskey = true;
  bool _isProcessing = false;

  static const String _companyPasskey = 'jay ambe';
  static const Color navy = Color(0xFF06224D);
  static const Color blue = Color(0xFF3478D4);

  @override
  void dispose() {
    _passkeyController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_isProcessing) return;

    final enteredPasskey =
        _passkeyController.text.trim().toLowerCase();

    if (enteredPasskey.isEmpty) {
      _showMessage(
        'Please enter the company passkey.',
        isSuccess: false,
      );
      return;
    }

    if (enteredPasskey != _companyPasskey) {
      _passkeyController.clear();
      _showMessage(
        'Invalid company passkey. Please try again.',
        isSuccess: false,
      );
      return;
    }

    setState(() => _isProcessing = true);
    FocusScope.of(context).unfocus();

    // Show successful validation.
    _showMessage(
      'Company access verified successfully!',
      isSuccess: true,
    );

    // Allow the success message to be seen before navigation.
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    // Open the existing login screen.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  void _showMessage(
    String message, {
    required bool isSuccess,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isSuccess
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor:
              isSuccess ? const Color(0xFF16834A) : navy,
          behavior: SnackBarBehavior.floating,
          duration: Duration(
            milliseconds: isSuccess ? 1000 : 2500,
          ),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAF1FC),
              Colors.white,
              Color(0xFFF4F7FC),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/logo_app.png',
                        height: 78,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Vyara Tiles ERP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: navy,
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'ENTERPRISE RESOURCE PLANNING',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF728098),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.8,
                        ),
                      ),

                      const SizedBox(height: 42),

                      Container(
                        height: 126,
                        width: 126,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFE1ECFF),
                        ),
                        padding: const EdgeInsets.all(15),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF3979D5),
                                Color(0xFF06224D),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: Colors.white,
                            size: 66,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        'Company Access',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: navy,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Welcome to Vyara Tiles ERP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Enter your company passkey to continue '
                        'to the ERP application.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF748094),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 28),

                      TextField(
                        controller: _passkeyController,
                        obscureText: _obscurePasskey,
                        autocorrect: false,
                        enableSuggestions: false,
                        textCapitalization:
                            TextCapitalization.none,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _continue(),
                        decoration: InputDecoration(
                          hintText: 'Enter company passkey',
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: Color(0xFF64748B),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePasskey =
                                    !_obscurePasskey;
                              });
                            },
                            icon: Icon(
                              _obscurePasskey
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Color(0xFFD9E1ED),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: blue,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              _isProcessing ? null : _continue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navy,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: navy,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(15),
                            ),
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 20,
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            color: Color(0xFF3979D5),
                            size: 20,
                          ),
                          SizedBox(width: 9),
                          Flexible(
                            child: Text(
                              'For authorized company users only',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: navy,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
