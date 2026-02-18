import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ViewSharedContent());
}

class ViewSharedContent extends StatelessWidget {
  const ViewSharedContent({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'View Shared Content',
      debugShowCheckedModeBanner: false,
      home: const ViewSharedContentPage(),
    );
  }
}

class ViewSharedContentPage extends StatefulWidget {
  const ViewSharedContentPage({super.key});

  @override
  State<ViewSharedContentPage> createState() => _ViewSharedContentPageState();
}

class _ViewSharedContentPageState extends State<ViewSharedContentPage> {

  List<String> date_ = [];
  List<String> photo_ = [];
  List<String> caption_ = [];
  List<String> description_ = [];

  @override
  void initState() {
    super.initState();
    viewSharedContent();
  }

  Future<void> viewSharedContent() async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String baseUrl = sh.getString('url') ?? "";
      String url = "${baseUrl}view_shared_content/";

      var response = await http.post(Uri.parse(url));
      var jsondata = json.decode(response.body);

      if (jsondata['status'] == "ok") {
        var arr = jsondata["data"];

        setState(() {
          date_ = List<String>.from(arr.map((e) => e['date'].toString()));
          photo_ = List<String>.from(arr.map((e) => e['photo'].toString()));
          caption_ = List<String>.from(arr.map((e) => e['caption'].toString()));
          description_ = List<String>.from(arr.map((e) => e['description'].toString()));
        });
      }

    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Content'),
        backgroundColor: Colors.cyan,
      ),
      body: ListView.builder(
        itemCount: photo_.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(10),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Correct image
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(photo_[index]),
                  ),
                  const SizedBox(width: 15),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Date: ${date_[index]}",
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),

                        Text("Caption: ${caption_[index]}"),
                        const SizedBox(height: 5),

                        Text("Description: ${description_[index]}"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
