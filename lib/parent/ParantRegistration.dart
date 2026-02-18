import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../login.dart';

class ParentRegister extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ParentRegistrationPage(),
    );
  }
}

class ParentRegistrationPage extends StatefulWidget {
  const ParentRegistrationPage({super.key});

  @override
  State<ParentRegistrationPage> createState() => _ParentRegistrationPageState();
}

class _ParentRegistrationPageState extends State<ParentRegistrationPage> {
  List<dynamic> studentList = [];
  String? selectedStudent;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController houseController = TextEditingController();
  TextEditingController placeController = TextEditingController();
  TextEditingController unameController = TextEditingController();
  TextEditingController passController = TextEditingController();

  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url').toString();

    try {
      final response = await http.post(
        Uri.parse(url + 'reg_view_student/'),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['status'] == 'ok') {
          setState(() {
            studentList = data['data'];
          });
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  Future<void> _registerParent() async {
    if (selectedStudent == null) {
      Fluttertoast.showToast(msg: "Please select a student");
      return;
    }

    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url').toString();

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse(url + 'parent_registration/'),
        body: {
          'student': selectedStudent!,
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'Housename': houseController.text.trim(),
          'place': placeController.text.trim(),
          'username': unameController.text.trim(),
          'password': passController.text.trim(),
        },
      );

      setState(() => loading = false);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['status'] == 'ok') {
          Fluttertoast.showToast(msg: "Registered Successfully");

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MyLoginPage(title: "")),
          );
        } else {
          Fluttertoast.showToast(msg: "Registration Failed");
        }
      } else {
        Fluttertoast.showToast(msg: "Network Error");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }

    setState(() => loading = false);
  }

  InputDecoration fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue.shade600),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade700,

      body: Stack(
        children: [
          // Gradient BG
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

          // Card
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(18),
              child: Container(
                padding: EdgeInsets.all(25),
                constraints: BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    )
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.family_restroom,
                            size: 60,
                            color: Colors.blue.shade700,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Parent Registration",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),

                    Text(
                      "Select Student",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: 8),

                    InputDecorator(
                      decoration: fieldDecoration("Select Student", Icons.group),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedStudent,
                          isExpanded: true,
                          hint: Text("Choose Student"),
                          items: studentList.map((item) {
                            return DropdownMenuItem(
                              value: item['id'].toString(),
                              child: Text(item['name']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => selectedStudent = value);
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    TextField(
                      controller: nameController,
                      decoration: fieldDecoration("Name", Icons.person),
                    ),
                    SizedBox(height: 20),

                    TextField(
                      controller: emailController,
                      decoration: fieldDecoration("Email", Icons.email),
                    ),
                    SizedBox(height: 20),

                    TextField(
                      controller: phoneController,
                      decoration: fieldDecoration("Phone", Icons.phone),
                    ),
                    SizedBox(height: 20),

                    TextField(
                      controller: houseController,
                      decoration:
                      fieldDecoration("House Name", Icons.home_outlined),
                    ),
                    SizedBox(height: 20),

                    TextField(
                      controller: placeController,
                      decoration:
                      fieldDecoration("Place", Icons.location_on_outlined),
                    ),
                    SizedBox(height: 20),

                    TextField(
                      controller: unameController,
                      decoration: fieldDecoration("Username", Icons.person_pin),
                    ),
                    SizedBox(height: 20),

                    TextField(
                      controller: passController,
                      obscureText: true,
                      decoration: fieldDecoration(
                          "Password", Icons.lock_outline),
                    ),

                    SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: loading ? null : _registerParent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: loading
                            ? CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : Text(
                          "Register",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
