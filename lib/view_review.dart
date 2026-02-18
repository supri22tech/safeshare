import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ViewReview extends StatefulWidget {
  const ViewReview({super.key, required  title});

  @override
  State<ViewReview> createState() => _ViewReviewState();
}

class _ViewReviewState extends State<ViewReview> {
  List<dynamic>Djangodata=[];
  bool isLoading = true;
  @override
  void initState(){
    super.initState();
    View();

  }

  Future<void> View() async {
    final pref = await SharedPreferences.getInstance();
    String? url = pref.getString('url');
    String? lid = pref.getString('lid');


    if (url == null || lid == null){

      setState(() =>
      isLoading = false
      );
      return;
    }

    try{
      var response= await http.post(
        Uri.parse(url + 'view_review/'),
        body: {'lid':lid
        },

      );

      if(response.statusCode == 200){
        final data= json.decode(response.body);
        if (data['status']=='ok'){
          setState(() {
            Djangodata = data['data'];
            isLoading= false;
          });
        }else{
          setState(() => isLoading = false);
        }
      }else{
        setState(() => isLoading=false);
      }
    }catch (e){
      setState(() => isLoading = false);

    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('View Review'),
          backgroundColor: Colors.cyan.shade600,
        ),

        body : ListView.builder(itemCount: Djangodata.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context,index){
              final item = Djangodata[index] ;

              return Card(
                child: Column(
                  children: [
                    Text('date: ${item['date']}'),
                    Text('review: ${item['review']}'),
                    Text('rating: ${item['rating']}'),
                  ],
                ),
              );}
        )




    );
  }
}


