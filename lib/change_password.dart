import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',debugShowCheckedModeBanner: false,
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const view_shared_content(title: 'Flutter Demo Home Page'),
    );
  }
}

class view_shared_content extends StatefulWidget {
  const view_shared_content({super.key, required this.title});


  final String title;

  @override
  State<view_shared_content> createState() => _view_shared_contentState();
}

class _view_shared_contentState extends State<view_shared_content> {

  _view_shared_contentState() {
    view_notification();
  }

  List<String> date_ = <String>[];
  List<String> review_ = <String>[];
  List<String> rating_ = <String>[];
  List<String> name_ = <String>[];




  Future<void> view_notification() async {
    List<String> date = <String>[];
    List<String> review = <String>[];
    List<String> rating = <String>[];



    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String urls = sh.getString('url').toString();
      String url = '$urls/myapp/view_image_notification/';
      var data = await http.post(Uri.parse(url), body: {


      });
      var jsondata = json.decode(data.body);
      String statuss = jsondata['status'];

      var arr = jsondata["data"];

      print(arr.length);

      for (int i = 0; i < arr.length; i++) {
        date.add(arr[i]['date'].toString());
        review.add(arr[i]['review']);

        rating.add(arr[i]['rating']);



      }

      setState(() {
        date_ = date;
        review_ = review;
        rating_ = rating;


      });

      print(statuss);
    } catch (e) {
      print("Error ------------------- " + e.toString());
      //there is error during converting file image to base64 encoding.
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          leading: BackButton( ),
          // TRY THIS: Try changing the color here to a specific color (to
          // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
          // change color while the other colors stay the same.
          backgroundColor: Theme.of(context).colorScheme.primary,

          title: Text(widget.title),
        ),
        body: ListView.builder(
          physics: BouncingScrollPhysics(),
          // padding: EdgeInsets.all(5.0),
          // shrinkWrap: true,
          itemCount: name_.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              onLongPress: () {
                print("long press" + index.toString());
              },
              title: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Card(
                        child:
                        Row(
                            children: [
                              CircleAvatar(radius: 50,backgroundImage: NetworkImage(date_[index])),
                              Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(5),
                                    child: Text(review_[index]),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(5),
                                    child: Text(rating_[index]),
                                  ),
                                ],
                              ),
                              // ElevatedButton(
                              //   onPressed: () async {
                              //
                              //     final pref =await SharedPreferences.getInstance();
                              //     pref.setString("did", id_[index]);
                              //
                              //     Navigator.push(
                              //       context,
                              //       MaterialPageRoute(builder: (context) => ViewSchedule()),
                              //     );
                              //
                              //
                              //
                              //
                              //   },
                              //   child: Text("Schedule"),
                              // ),
                            ]
                        )

                        ,
                        elevation: 8,
                        margin: EdgeInsets.all(10),
                      ),
                    ],
                  )),
            );
          },
        )
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}