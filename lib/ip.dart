import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';

void main() {
  runApp(const SetIp());
}

class SetIp extends StatelessWidget {
  const SetIp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SetIpPage(title: 'Connect to Server'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SetIpPage extends StatefulWidget {
  final String title;
  const SetIpPage({super.key, required this.title});

  @override
  State<SetIpPage> createState() => _SetIpPageState();
}

class _SetIpPageState extends State<SetIpPage> {
  final TextEditingController ipController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌈 Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade800,
                  Colors.blue.shade600,
                  Colors.lightBlueAccent.shade200,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                width: MediaQuery.of(context).size.width * 0.90,
                constraints: const BoxConstraints(maxWidth: 420),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🌐 Icon
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.shade100,
                      ),
                      child: Icon(
                        Icons.wifi_tethering,
                        color: Colors.blue.shade800,
                        size: 50,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // TITLE
                    Text(
                      "Connect to Server",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Enter the Server IP Address to continue",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // IP INPUT FIELD
                    TextField(
                      controller: ipController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "IP Address",
                        prefixIcon: Icon(Icons.public, color: Colors.blue.shade700),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 35),

                    // 🔵 CONNECT BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _saveIp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          "Connect",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  Future<void> _saveIp() async {
    String ip = ipController.text.trim();

    if (ip.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter a valid IP address");
      return;
    }

    setState(() => _loading = true);

    SharedPreferences sh = await SharedPreferences.getInstance();
    sh.setString("url", "http://$ip:8000/myapp/");
    sh.setString("imgurl", "http://$ip:8000");

    print(ip);
    print("*****************");

    Fluttertoast.showToast(msg: "IP Saved!");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MyLoginPage(title: "")),
    );

    setState(() => _loading = false);
  }
}
