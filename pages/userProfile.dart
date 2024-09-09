import 'dart:convert';
import 'dart:io';
import 'package:spacemeals/pages/encryption.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

var serverState=false;
//var serverIP;

class profileRender extends StatefulWidget{
  SharedPreferences prefs;
  profileRender(this.prefs,{super.key});

  @override
  // ignore: no_logic_in_create_state
  State<profileRender> createState()=>_Render(prefs);
}


class _Render extends State<profileRender>{
  SharedPreferences prefs;
       final _formKey=GlobalKey<FormState>();
    final TextEditingController _emailController=TextEditingController();
       final TextEditingController _passwordController=TextEditingController();
  _Render(this.prefs);
  var isLoading=false;

  void _unHealthy(BuildContext context){
    Navigator.of(context).pop(true);
      showDialog(
  context: context, 
  builder: (context){
    return AlertDialog(
      title:const Text('Alert'),
      content:const Text('request failed'),
      actions: [
        TextButton(
          onPressed:()async{
    Navigator.of(context).pop();
              },
           child:const Text('ok')
  ),
      ],
    );
  });
  }

void _affirm_password_change(BuildContext context){
        showDialog(
  context: context, 
  builder: (context){
    return AlertDialog(
      title:const Text('Alert'),
      content:const Text('password changed successully'),
      actions: [
        TextButton(
          onPressed:()async{
            Navigator.of(context).pop();
              },
           child:const Text('ok')
  ),
      ],
    );
  });
}

  void _serverSuccess(BuildContext context){
      showDialog(
  context: context, 
  builder: (context){
    return AlertDialog(
      title:const Text('Alert'),
      content:const Text('Account deleted successully'),
      actions: [
        TextButton(
          onPressed:()async{
            exit(0);
              },
           child:const Text('ok')
  ),
      ],
    );
  });
  }

  void _ConditionAlert(BuildContext context,String str) {
showDialog(
  context: context, 
  builder: (context){
    return AlertDialog(
      content:Column(children:<Widget>[
         Padding(
                padding:const EdgeInsets.all(16.0),
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                    Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          Text('Change password',style: TextStyle(color: Colors.black),),
                TextFormField(
                    decoration:const InputDecoration(
                      labelText:'new password',
                      fillColor: Colors.black,
                hintStyle: TextStyle(color: Colors.black),
                labelStyle: TextStyle(color: Colors.black),
                      ),
                        style:const TextStyle(color:Colors.black),
                        validator:(value){
                          if(value!.isEmpty){
                            return 'Enter new password';
                          }
                          else {
                            return null;
                          }
                        },
                    controller:_passwordController,
                  //  obscureText: true,
                ),
                        ],
                      )),
                      SizedBox(height:50),
                 GestureDetector(
                onTap:(){
                  _modify();
                 // confirmAccErase(context);
                  Navigator.pop(context);
                },
                child:const Text('Done',style:TextStyle(color:Colors.blue,fontSize:12))
              )
              ]
          ) ,
        )
      ],),
    );
  });

}


void waitingDialog(BuildContext context){
isLoading=(isLoading==true?false:true);

if(isLoading==true){
  showDialog(
  context: context, 
  builder: (context){
        Future.delayed(Duration(seconds:3),(){Navigator.of(context).pop(true);});
    return AlertDialog(
      content:Row(children:<Widget>[
  CircularProgressIndicator.adaptive(),
  SizedBox(width:5),
      const Text('please wait...'),
        ]),
        
      );
  });
}
else{
  //Navigator.of(context).pop();
}
}


void _modify() async{
  //  String Nuser=_emailController.text.trim();
String password=_passwordController.text.trim();
Map<String,dynamic> obj={
'username':prefs.getString('username'),
'newPassword':password,
'ID':prefs.getString('ID')
};

EncryptData encryptedObj=EncryptData(jsonEncode(obj)); 
await encryptedObj.encrypt();
var encrypted_obj=encryptedObj.get_output();

print('Remote processing of user input initiated...');

prefs.setString('password', password);
//send details to server here and call _unhealthy if it fails
await serverModify(context,'change-password',encrypted_obj);

}


void confirmAccErase(BuildContext context){
  showDialog(
  context: context, 
  builder: (context){
    return AlertDialog(
      title:const Text('Alert'),
      content:const Text('please be aware that you will loose access to all your data!'),
      actions: [
        TextButton(
          onPressed:()async{
            //call server
          await serverErase(context);
          // Navigator.pop(context);
              },
           child:const Text('yes')
  ),
      TextButton(
          onPressed:()async{
            //call server
          Navigator.of(context).pop();
              },
           child:const Text('cancel')
  )
      ],
    );
  });
}


Future<void> serverModify(BuildContext context,String endpoint,obj) async{
  var serverIP=prefs.getString('serverIP');
  // ignore: avoid_print
  print('checking server...');
  try{
  var uri=Uri.parse('http://$serverIP:2000/$endpoint');
  var resp=await http.post(uri,body:jsonEncode(obj),headers: <String,String>{'Content-Type':'application/json;charset=UTF-8'});

waitingDialog(context);

if(resp.statusCode==200){
 waitingDialog(context);
   _affirm_password_change(context);
   // ignore: avoid_print
   print('------------>The server responded positively}');
  }
else {
  waitingDialog(context);
    _unHealthy(context);
  // ignore: avoid_print
  print('----------->some result:${resp.statusCode}');
  }
  }
// ignore: avoid_print
catch(e){
 // waitingDialog(context);
_unHealthy(context);
  print('------>Network issue:$e');}
}


Future<void> serverErase(BuildContext context) async{
  var serverIP=prefs.getString('serverIP');
  // ignore: avoid_print
Map<String,dynamic> obj={
  'username':prefs.getString('username'),
  'ID':(prefs.getString('ID'))
};


  print('checking server...');
  try{
  var uri=Uri.parse('http://$serverIP:2000/admin/delete-account');
  var resp=await http.post(uri,body:jsonEncode(obj),headers: <String,String>{'Content-Type':'application/json;charset=UTF-8'});

waitingDialog(context);

if(resp.statusCode==200){
   setState(() {
   serverState=true;
   // ignore: avoid_print
   print('------------>The server responded positively}');});
   _serverSuccess(context);
  }
else {
    _unHealthy(context);
  // ignore: avoid_print
  print('----------->some result:${resp.statusCode}');
  }
  }
// ignore: avoid_print
catch(e){
_unHealthy(context);
  print('------>Network issue:$e');}
}


  @override
  Widget build(BuildContext context){
    return MaterialApp(
      home:Scaffold(
 appBar:  AppBar(
          backgroundColor:Colors.brown ,
        leading: GestureDetector(
          onTap: (){
            Navigator.pop(context);
          },
          child:const Icon(Icons.arrow_back,color: Colors.white,),
        ),
        title:const Text('user profile',style: TextStyle(color: Colors.white),),
     
      ),

   body:Stack(
    children:<Widget> [
     ListView(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 40),
     children: <Widget>[
              ListTile(
      title:  Container(width: 200,
              margin:EdgeInsets.only(top:0),
            child:CircleAvatar(radius: 80,backgroundImage:AssetImage('assets/profile.png'),),
      ),
              ),
                 const Divider(color:Colors.grey,height:2,),
                ListTile(
                  leading: Text('name:',style:const TextStyle(color: Colors.brown,fontSize:12,fontWeight:FontWeight.bold),),
                  title: Text(prefs.getString('username') as String,style:const TextStyle(fontSize:12,fontWeight:FontWeight.bold)),
                ),
                   const Divider(color:Colors.grey,height:2,),
                   ListTile(
                  leading: Text('email:',style:const TextStyle(color: Colors.brown,fontSize:12,fontWeight:FontWeight.bold),),
                  title: Text(prefs.getString('email') as String,style:const TextStyle(fontSize:12,fontWeight:FontWeight.bold)),
                ),
          const Divider(color:Colors.grey,height:2,),
         ListTile(
                  leading: Text('DeviceID:',style:const TextStyle(color: Colors.brown,fontSize:12,fontWeight:FontWeight.bold),),
                  title: Text(prefs.getString('ID')! as String,style:const TextStyle(fontSize:12,fontWeight:FontWeight.bold)),
                ),
                   const Divider(color:Colors.grey,height:5,),
                   ListTile(
                  title: ElevatedButton(style:ElevatedButton.styleFrom(
                    foregroundColor:Colors.white,
                    backgroundColor: Colors.brown
                  ),
                    onPressed:()async{
                    confirmAccErase(context);
                  //  await serverErase(context);
                    },
                     child: Text('Delete account')),
                ),
                ListTile(
                  title: MaterialButton(
                    onPressed:(){
                     _ConditionAlert(context,'any');
                    },
                    color: Colors.brown,
                    textColor:Colors.white,
                    child: Icon(Icons.edit,size:24,),
                    padding: EdgeInsets.all(18),
                    shape: CircleBorder(),
                    ),
                )
     ] 
  

      )],
    )));

}}