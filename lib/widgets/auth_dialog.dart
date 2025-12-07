import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AuthDialog extends StatefulWidget {
  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  bool isLogin = true;
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: BoxConstraints(maxWidth: 400),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, // Use theme
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Center(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFF0F4FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLogin
                        ? Icons.lock_open_rounded
                        : Icons.person_add_rounded,
                    size: 32,
                    color: Color(0xFF1E50F8),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                isLogin ? 'Welcome Back' : 'Create Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  // color: Colors.black87, // Use theme
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                isLogin
                    ? 'Enter your credentials to access your account'
                    : 'Sign up to start sharing your stories',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              SizedBox(height: 32),

              // Inputs
              if (!isLogin) ...[
                _buildInput(
                  context: context,
                  controller: _name,
                  label: 'Full Name',
                  icon: Icons.person_outline_rounded,
                ),
                SizedBox(height: 16),
              ],
              _buildInput(
                context: context,
                controller: _email,
                label: 'Email Address',
                icon: Icons.email_outlined,
                inputType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              _buildInput(
                context: context,
                controller: _pass,
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),
              SizedBox(height: 32),

              // Action Button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          if (_email.text.isEmpty || _pass.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please fill all fields'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          setState(() => _loading = true);
                          try {
                            if (isLogin) {
                              await auth.login(
                                _email.text.trim(),
                                _pass.text.trim(),
                              );
                            } else {
                              if (_name.text.isEmpty) {
                                throw "Name is required";
                              }
                              await auth.register(
                                _email.text.trim(),
                                _pass.text.trim(),
                                _name.text.trim(),
                              );
                            }
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _loading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1E50F8),
                    shadowColor: Color(0xFF1E50F8).withOpacity(0.4),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isLogin ? 'Sign In' : 'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 16),

              // Toggle
              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                    _email.clear();
                    _pass.clear();
                    _name.clear();
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    children: [
                      TextSpan(
                        text: isLogin
                            ? "Don't have an account? "
                            : "Already have an account? ",
                      ),
                      TextSpan(
                        text: isLogin ? "Register Now" : "Login Here",
                        style: TextStyle(
                          color: Color(0xFF1E50F8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? inputType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey.shade200,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: inputType,
        style: TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 22),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
