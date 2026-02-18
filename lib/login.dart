import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'parent/ParentHome.dart';
import 'UserHome.dart';
import 'register.dart';
import 'parent/ParantRegistration.dart';

void main() {
  runApp(const MyLogin());
}

class MyLogin extends StatelessWidget {
  const MyLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyLoginPage(title: 'Login'),
    );
  }
}

class MyLoginPage extends StatefulWidget {
  final String title;
  const MyLoginPage({super.key, required this.title});

  @override
  State<MyLoginPage> createState() => _MyLoginPageState();
}

class _MyLoginPageState extends State<MyLoginPage> {
  TextEditingController unameController = TextEditingController();
  TextEditingController passController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    unameController.dispose();
    passController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------
  // UI (No animation at all)
  // --------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade700,

      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade800,
                  Colors.blue.shade600,
                  Colors.cyan.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(32),
                constraints: const BoxConstraints(maxWidth: 450),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Logo
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(
                        Icons.person_outline,
                        size: 50,
                        color: Colors.blue.shade700,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "Welcome Back",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Login to continue",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 35),

                    // USERNAME
                    TextField(
                      controller: unameController,
                      decoration: _inputStyle(
                        label: "Username",
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // PASSWORD
                    TextField(
                      controller: passController,
                      obscureText: !_isPasswordVisible,
                      decoration: _inputStyle(
                        label: "Password",
                        icon: Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _send_data,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                            : const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Divider(color: Colors.grey.shade300),

                    const SizedBox(height: 18),

                    // USER SIGNUP
                    _secondaryButton(
                      text: "Create New Account",
                      icon: Icons.person_add,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => UserRegisterPage()),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // PARENT SIGNUP
                    _secondaryButton(
                      text: "Parent Registration",
                      icon: Icons.family_restroom,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ParentRegister()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // Input Style
  // --------------------------------------------------------
  InputDecoration _inputStyle({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue.shade600),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
      ),
    );
  }

  // --------------------------------------------------------
  // Secondary Button
  // --------------------------------------------------------
  Widget _secondaryButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        side: BorderSide(color: Colors.blue.shade600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.blue.shade700),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // LOGIN FUNCTION
  // --------------------------------------------------------
  void _send_data() async {
    String uname = unameController.text.trim();
    String password = passController.text.trim();

    if (uname.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please fill in all fields",
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() => _isLoading = true);

    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? "";
    String imgurl = sh.getString('imgurl') ?? "";

    final uri = Uri.parse("${url}android_login/");

    try {
      final response = await http.post(uri, body: {
        'uname': uname,
        'passwd': password,
      });

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        // ✅ VALID LOGIN
        if (data['task'] == 'valid') {
          sh.setString("lid", data['id'].toString());

          Fluttertoast.showToast(
            msg: "Login Successful!",
            backgroundColor: Colors.green,
          );

          if (data['type'] == "User") {

    //         "img": str(u.photo),
    // "name": str(u.name),
    // "status": str(u.status),
            sh.setString("uimg", imgurl+ data['img'].toString());
            sh.setString("uname", data['name'].toString());
            sh.setString("ustatus", data['status'].toString());

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => UserHome()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ParentHome()),
            );
          }
        }

        // 🚫 PARENT REQUIRED
        else if (data['task'] == 'parent_required') {
          Fluttertoast.showToast(
            msg: data['message'],
            backgroundColor: Colors.orange,
          );
        }

        // 🚫 BLOCKED
        else if (data['task'] == 'blocked') {
          Fluttertoast.showToast(
            msg: data['message'],
            backgroundColor: Colors.red,
          );
        }

        // ❌ INVALID
        else {
          Fluttertoast.showToast(
            msg: "Invalid Username or Password",
            backgroundColor: Colors.red,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: "Network Error",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: $e",
        backgroundColor: Colors.red,
      );
    }

    setState(() => _isLoading = false);
  }
}
