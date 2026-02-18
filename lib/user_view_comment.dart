import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:safe_share/add_post.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'addComment.dart';
import 'comment post.dart';

class UserviewComment extends StatefulWidget {
  const UserviewComment({super.key});

  @override
  State<UserviewComment> createState() => UserViewpost();
}

class UserViewpost extends State<UserviewComment> {
  List<dynamic> postList = [];
  bool isLoading = true;
  String? baseUrl;

  @override
  void initState() {
    super.initState();
    fetchposts();
  }

  Future<void> fetchposts() async {
    print("================");
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    String? pid = pref.getString('pid').toString();
    baseUrl = pref.getString('imgurl').toString()+"/media/"; // base URL for media files

    if (url == null || pid == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      var response = await http.post(
        Uri.parse(url + 'view_comment/'),
        body: {'pid': pid},
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
        title: const Text('comment'),
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
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // post Photo
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['user'].toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text("comment: ${post['comment'].toString()}",
                            style: const TextStyle(fontSize: 12)),
                        Text("date: ${post['date'].toString()}",
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

      floatingActionButton: FloatingActionButton(onPressed: (){
        // AddPostPage

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AddComment()),
        );
      },
        child: Icon(Icons.add),),
    );
  }
}
