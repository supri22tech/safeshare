import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddPostPage extends StatefulWidget {
  const AddPostPage({super.key});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  File? _selectedImage;
  final picker = ImagePicker();

  final TextEditingController captionController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime? selectedDate;


  Future pickImage() async {
    final pickedFile =
    await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future submitPost() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url') ?? "";
    String lid = sh.getString('lid') ?? "";
    if (_selectedImage == null ||
        captionController.text.isEmpty ||
        descriptionController.text.isEmpty
       ) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    var uri = Uri.parse(url + 'post_insert/');

    var request = http.MultipartRequest('POST', uri);

    request.fields['user'] = lid; // pass logged-in user id
    request.fields['caption'] = captionController.text;
    request.fields['description'] = descriptionController.text;

    request.files.add(await http.MultipartFile.fromPath(
      'photo',
      _selectedImage!.path,
    ));

    var response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Post Uploaded!")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")));
    }
  }

  Future pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Post")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Image picker
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 58,
                backgroundColor: Colors.blue.shade50,
                backgroundImage: _selectedImage != null
                    ? FileImage(File(_selectedImage!.path))
                    : null,
                child: _selectedImage == null
                    ? Icon(Icons.camera_alt,
                    size: 34, color: Colors.white)
                    : null,
              ),
            ),


            TextField(
              controller: captionController,
              decoration: const InputDecoration(
                labelText: "Caption",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),



            Center(
              child: ElevatedButton(
                onPressed: submitPost,
                child: const Text("Submit Post"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}





