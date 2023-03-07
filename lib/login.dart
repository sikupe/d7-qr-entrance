import 'package:flutter/material.dart';
import 'package:qr_entrance/diva_service.dart';

class LoginPage extends StatefulWidget {
  final void Function(bool) callback;

  const LoginPage({super.key, required this.callback});

  @override
  State<LoginPage> createState() => _LoginPageState(callback: callback);
}

class _LoginPageState extends State<LoginPage> {
  final DivaService _divaService = DivaService();

  final Function(bool) callback;

  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  String? error;
  bool loggingIn = false;

  _LoginPageState({required this.callback});

  void login() {
    () async {
      setState(() {
        loggingIn = true;
      });

      try {
        await _divaService.setNewCredentials(
            _usernameController.text, _passwordController.text);
        setState(() {
          error = null;
        });
        callback.call(true);
      } on DivaException catch (e) {
        setState(() {
          error = e.message;
        });
      }

      setState(() {
        loggingIn = false;
      });
    }();
  }

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.all(15),
              child: Image.asset('assets/logo-domus7-colored.png'),
            ),
            Container(
              margin: const EdgeInsets.all(15),
              child: TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)))),
            ),
            Container(
                margin: const EdgeInsets.all(15),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15))),
                )),
            Container(
              margin: const EdgeInsets.all(15),
              child: TextButton(
                onPressed: login,
                style: ButtonStyle(
                    minimumSize: MaterialStateProperty.all<Size>(const Size(250, 50)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(35.0),
                            side: const BorderSide(color: Colors.blue)))),
                child: loggingIn
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
            ),
            if (error != null)
              Container(
                margin: const EdgeInsets.all(15),
                child: Text(
                  error!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
          ],
        ),
      ),
    );
  }
}
