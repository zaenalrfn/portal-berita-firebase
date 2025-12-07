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
    return AlertDialog(
      title: Text(isLogin ? 'Login' : 'Register'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLogin)
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: 'Name'),
            ),
          TextField(
            controller: _email,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _pass,
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() => isLogin = !isLogin);
          },
          child: Text(isLogin ? 'Need account?' : 'Have account?'),
        ),
        ElevatedButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  try {
                    if (isLogin) {
                      await auth.login(_email.text.trim(), _pass.text.trim());
                    } else {
                      await auth.register(
                        _email.text.trim(),
                        _pass.text.trim(),
                        _name.text.trim(),
                      );
                    }
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Auth error: ' + e.toString())),
                    );
                  } finally {
                    setState(() => _loading = false);
                  }
                },
          child: _loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Text(isLogin ? 'Login' : 'Register'),
        ),
      ],
    );
  }
}
