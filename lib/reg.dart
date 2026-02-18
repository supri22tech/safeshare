import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../login.dart';

class UserRegisterPage extends StatefulWidget {
  const UserRegisterPage({Key? key}) : super(key: key);

  @override
  State<UserRegisterPage> createState() => _UserRegisterPageState();
}

class _UserRegisterPageState extends State<UserRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final placeController = TextEditingController();
  final pincodeController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  XFile? _photo;

  bool _isLoading = false;
  bool _obscure = true;
  final Color primary = const Color(0xFFF96332);
  final Color bg = const Color(0xFFF7F7F7);

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _photo = img);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photo == null) {
      Fluttertoast.showToast(msg: "Please select a profile photo");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? url = prefs.getString("url");

      if (url == null || url.isEmpty) {
        Fluttertoast.showToast(msg: "Server URL not found");
        return;
      }

      var req = http.MultipartRequest(
        'POST',
        Uri.parse(url + "flut_user_register/"),
      );

      req.fields.addAll({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'place': placeController.text.trim(),
        'pincode': pincodeController.text.trim(),
        'username': usernameController.text.trim(),
        'password': passwordController.text.trim(),
      });

      req.files.add(await http.MultipartFile.fromPath('photo', _photo!.path));

      var res = await req.send();
      var data = json.decode(await res.stream.bytesToString());

      if (data['status'] == 'ok') {
        Fluttertoast.showToast(msg: "Registration Successful!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MyLoginPage(title: '',)),
        );
      } else {
        Fluttertoast.showToast(msg: "Registration Failed");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("User Registration"),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white,
                  backgroundImage:
                  _photo != null ? FileImage(File(_photo!.path)) : null,
                  child: _photo == null
                      ? Icon(Icons.camera_alt_outlined,
                      color: primary, size: 36)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              _buildInput(nameController, "Full Name", Icons.person),
              _buildInput(emailController, "Email", Icons.email_outlined,
                  type: TextInputType.emailAddress),
              _buildInput(phoneController, "Phone", Icons.phone,
                  type: TextInputType.phone),
              _buildInput(placeController, "Place", Icons.place),
              _buildInput(pincodeController, "Pincode",
                  Icons.location_on_outlined,
                  type: TextInputType.number),
              _buildInput(usernameController, "Username", Icons.person_outline),
              _buildInput(passwordController, "Password", Icons.lock_outline,
                  obscure: _obscure,
                  suffix: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure))),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5)
                    : const Text("Register",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController c, String label, IconData icon,
      {bool obscure = false,
        Widget? suffix,
        TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        keyboardType: type,
        validator: (v) => v!.isEmpty ? "Enter $label" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primary),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primary, width: 1.4),
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
