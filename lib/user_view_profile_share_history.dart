import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ViewSharedAccounts extends StatefulWidget {
  const ViewSharedAccounts({super.key});

  @override
  State<ViewSharedAccounts> createState() => _ViewSharedAccountsState();
}

class _ViewSharedAccountsState extends State<ViewSharedAccounts> {
  List<dynamic> sharedRecords = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSharedDetails();
  }

  Future<void> fetchSharedDetails() async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    String? lid = pref.getString('lid');

    try {
      var response = await http.post(
        Uri.parse("${url!}send_view_shared_details/"),
        body: {'lid': lid!},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          setState(() {
            sharedRecords = data['data']; // This matches the "l" list from Django
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shared Account Logs",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : sharedRecords.isEmpty
            ? const Center(child: Text("No sharing history found"))
            : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: sharedRecords.length,
          itemBuilder: (context, index) {
            final record = sharedRecords[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history, color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Shared on: ${record['date'] ?? 'N/A'}",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: record['status'] == 'accepted' ? Colors.green.shade100 : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            record['status'].toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: record['status'] == 'accepted' ? Colors.green.shade700 : Colors.orange.shade700,
                            ),
                          ),
                        )
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildUserColumn("From", record['from_user']),
                        const Icon(Icons.arrow_forward_outlined, color: Colors.grey),
                        _buildUserColumn("To", record['to_user']),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserColumn(String label, String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
      ],
    );
  }
}