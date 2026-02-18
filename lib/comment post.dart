import 'package:flutter/material.dart';

void main(){
  runApp(appPost());
}

class appPost extends StatelessWidget {
  const appPost({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PostPage(),
    );
  }
}

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post'),
        backgroundColor: Colors.brown,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20,),
            TextFormField(
              decoration: InputDecoration(
                  hintText: 'Photo',
                  border: OutlineInputBorder()
              ),
            ),

            SizedBox(height: 20,),
            TextFormField(
              decoration: InputDecoration(
                  hintText: 'caption',
                  border: OutlineInputBorder()
              ),
            ),

            SizedBox(height: 20,),
            TextFormField(
              decoration: InputDecoration(
                  hintText : 'description',
                  border: OutlineInputBorder()
              ),
            ),
            ElevatedButton(onPressed: (){}, child: Text('Upload'))
          ],
        ),
      ),
    );
  }
}
