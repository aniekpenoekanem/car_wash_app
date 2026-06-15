import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() =>
      _AdminLoginScreenState();
}

class _AdminLoginScreenState
    extends State<AdminLoginScreen> {
  final usernameController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> login() async {
    if (usernameController.text.isEmpty ||
        passwordController.text.isEmpty) {
      showMessage("Enter username and password");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          "${ApiService.baseUrl}/login",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode({
          "username":
              usernameController.text.trim(),
          "password":
              passwordController.text.trim(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboardScreen(
              token: data["token"],
            ),
          ),
        );
      } else {
        final error = json.decode(response.body);

        showMessage(
          error["detail"] ?? "Login failed",
        );
      }
    } catch (e) {
      showMessage("Unable to connect to server");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    isLoading ? null : login,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Login"),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "Default credentials:\nadmin / 1234",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}