import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:safe_share/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class UserRegisterPage extends StatefulWidget {
  const UserRegisterPage({Key? key}) : super(key: key);

  @override
  State<UserRegisterPage> createState() => _UserRegisterPageState();
}

class _UserRegisterPageState extends State<UserRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // ---------------- CONTROLLERS ----------------
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final placeController = TextEditingController();
  final pincodeController = TextEditingController();
  final districtController = TextEditingController();
  final genderController = TextEditingController();
  final dobController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  XFile? _photo;
  XFile? _aadhaar;

  bool _isLoading = false;
  bool _obscure = true;

  final Color primary = Colors.blue.shade700;

  // ---------------- DOB PICKER ----------------
  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      dobController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  // ---------------- IMAGE PICKER ----------------
  Future<void> _pickImage(bool isProfile) async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (img != null) {
      setState(() {
        isProfile ? _photo = img : _aadhaar = img;
      });
    }
  }

  // ---------------- REGISTER ----------------
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_photo == null || _aadhaar == null) {
      Fluttertoast.showToast(
        msg: "Upload profile photo and Aadhaar",
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String url = prefs.getString("url") ?? "";

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("${url}android_user_registration/"),
      );

      // ---------- TEXT FIELDS ----------
      request.fields.addAll({
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "place": placeController.text.trim(),
        "pincode": pincodeController.text.trim(),
        "district": districtController.text.trim(),
        "gender": genderController.text.trim(),
        "dob": dobController.text.trim(),
        "username": usernameController.text.trim(),
        "password": passwordController.text.trim(),
      });

      // ---------- FILES ----------
      request.files.add(await http.MultipartFile.fromPath("photo", _photo!.path));
      request.files.add(await http.MultipartFile.fromPath("adhaaer", _aadhaar!.path));

      var response = await request.send();
      var resString = await response.stream.bytesToString();
      var data = jsonDecode(resString);

      if (data["status"] == "ok") {
        _handleVerification(data["status"], data["message"]);
      } else {
        Fluttertoast.showToast(
          msg: data["message"] ?? "Registration failed",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Server error: $e",
        backgroundColor: Colors.red,
      );
    }

    setState(() => _isLoading = false);
  }

  // ---------------- VERIFICATION UX ----------------
  void _handleVerification(String statuss, String message) {
    Color color;
    String title;
    String ss=message;
    print(statuss);
    switch (message) {
      case "verified_adult":
        color = Colors.green;
        title = "Registration Successful";
        ss="xx";
        break;

      case "verified_minor":
        color = Colors.orange;
        title = "Minor Account";
        message += "\n\nParent registration required before login.";
        ss="xx";
        break;

      case "pending":
        color = Colors.blue;
        title = "Verification Pending";
        message += "\n\nUpload a clearer Aadhaar image.";
        break;

      case "Theft Detected":
        color = Colors.red;
        title = "Theft Detected";
        message += "\n\nUpload real data.";
        break;

      case "blocked":
        color = Colors.red;
        title = "Verification Failed";
        break;

      default:
        color = Colors.grey;
        title = "Info";
    }



    Fluttertoast.showToast(
      msg: message,
      backgroundColor: color,
      toastLength: Toast.LENGTH_LONG,
      textColor: Colors.white,
    );
    print("okkkkkkkkkkkkkk");
    print(ss);
    print("=================");
    if(ss=="xx")
      {
        print("navigate");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyLoginPage(title: "")),
        );

      }

  }

  // ---------------- INPUT DECORATOR ----------------
  InputDecoration _decorate(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primary),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.blue.shade600, Colors.cyan.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [

                    // PROFILE PHOTO
                    GestureDetector(
                      onTap: () => _pickImage(true),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _photo != null ? FileImage(File(_photo!.path)) : null,
                        child: _photo == null
                            ? Icon(Icons.camera_alt, size: 30, color: primary)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _field(nameController, "Full Name", Icons.person),
                    _field(emailController, "Email", Icons.email),
                    _field(phoneController, "Phone", Icons.phone),
                    _field(placeController, "Place", Icons.place),
                    _field(pincodeController, "Pincode", Icons.pin),
                    _field(districtController, "District", Icons.location_city),
                    _field(genderController, "Gender", Icons.wc),

                    TextFormField(
                      controller: dobController,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      decoration: _decorate("Date of Birth", Icons.calendar_today),
                      validator: (v) => v!.isEmpty ? "Select DOB" : null,
                    ),
                    const SizedBox(height: 12),

                    // AADHAAR
                    InkWell(
                      onTap: () => _pickImage(false),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.document_scanner, color: primary),
                            const SizedBox(width: 10),
                            Text(_aadhaar == null ? "Upload Aadhaar Card" : "Aadhaar Uploaded ✅"),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _field(usernameController, "Username", Icons.person_pin),
                    TextFormField(
                      controller: passwordController,
                      obscureText: _obscure,
                      decoration: _decorate(
                        "Password",
                        Icons.lock,
                        suffix: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? "Enter Password" : null,
                    ),

                    const SizedBox(height: 25),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Register Account", style: TextStyle(fontSize: 18)),
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

  Widget _field(TextEditingController c, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        decoration: _decorate(label, icon),
        validator: (v) => v!.isEmpty ? "Required" : null,
      ),
    );
  }
}
