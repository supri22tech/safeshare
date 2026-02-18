import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:safe_share/add_post.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Viewpost extends StatefulWidget {
  const Viewpost({super.key});

  @override
  State<Viewpost> createState() => ViewPost();
}

class ViewPost extends State<Viewpost> {
  List<dynamic> postList = [];
  bool isLoading = true;
  String? baseUrl;

  @override
  void initState() {
    super.initState();
    fetchposts();
  }

  Future<void> fetchposts() async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    String? lid = pref.getString('lid');
    baseUrl = pref.getString('imgurl').toString()+"/media/"; // base URL for media files

    if (url == null || lid == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      var response = await http.post(
        Uri.parse(url + 'parent_view_post/'),
        body: {'lid': lid},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          setState(() {
            postList = data['data'];
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching posts: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('posts'),
        backgroundColor: Colors.blue.shade600,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : postList.isEmpty
          ? const Center(child: Text("No posts found"))
          : Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: postList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final post = postList[index];
            String imageUrl = post['photo'];
            // prepend base URL if needed
            if (baseUrl != null && !imageUrl.startsWith('http')) {
              imageUrl = baseUrl! + imageUrl;
            }
            // {'date': '2025-11-23', 'photo': '1000081074.jpg', 'caption': 'dhhdh', 'description': 'djjd'}
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // post Photo
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16)),
                    child: Image.network(
                      imageUrl,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100,
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text("caption: ${post['caption']}",
                            style: const TextStyle(fontSize: 12)),
                        Text("description: ${post['description']}",
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      // floatingActionButton: FloatingActionButton(onPressed: (){
      //   // AddPostPage
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (context) => AddPostPage()),
      //   );
      // },child: Icon(Icons.add),),
    );
  }
}
