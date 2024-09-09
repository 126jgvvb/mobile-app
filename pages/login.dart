import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import "package:local_auth/local_auth.dart";
import 'package:spacemeals/pages/HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spacemeals/pages/encryption.dart';
//import './encryption.dart'as EncryptData;

class UserData{
  late String name;
  late String password;
UserData(this.name,this.password);
}

// ignore: must_be_immutable
class LoginPage extends StatefulWidget{
  SharedPreferences prefs;
       LoginPage(this.prefs,{super.key});
       @override
  State<LoginPage> createState()=> _initLogin(prefs);
}



class _initLogin extends State<LoginPage> with SingleTickerProviderStateMixin{
  final TextEditingController _nameController=TextEditingController();
    final TextEditingController _passwordController=TextEditingController();
     final _formKey=GlobalKey<FormState>();
     SharedPreferences prefs;
     final GlobalKey<ScaffoldMessengerState> _scaffoldKey=GlobalKey<ScaffoldMessengerState>();
    late var fingerConfiguration=true;
    bool serverState=false;
      var isLoading=2;
      var Btnstate=false;
      var _deviceID=null;
      var serverIP;
      var username=null;

    _initLogin(this.prefs);

    void _ConditionAlert(BuildContext context,bool str) {
showDialog(
  context: context, 
  builder: (context){
    return AlertDialog(
      title:const Icon(Icons.warning_sharp,color: Colors.yellowAccent,size: 24,),
      content: str? const Text('network error,check your server connection...'):const Text('Invalid user credentials...'),
      actions: [
        TextButton(
          onPressed:()async{
           if(Btnstate==true) toggleBtn();
            Navigator.of(context).pop();
              },
           child:const Text('ok')
  ),
      ],
    );
  });
}



    void _Email_failure_alert(BuildContext context) {
showDialog(
  context: context, 
  builder: (context){
    return AlertDialog(
      title:const Icon(Icons.warning_sharp,color: Colors.yellowAccent,size: 24,),
      content:const Text('An error occured while sending email...'),
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


    Future<void> _loginAnalysis(BuildContext context) async{
print('processing input..');
//const CircularProgressIndicator();

   if(_formKey.currentState!.validate()){
    toggleBtn();


// ignore: non_constant_identifier_names
String Nuser=_nameController.text.trim();
// ignore: non_constant_identifier_names
String Npass=_passwordController.text.trim();

 // ignore: use_build_context_synchronously
 if(Nuser=='coded'  && Npass=='1234'){
   prefs.setBool('stateFlag',false);
      Navigator.push(context,MaterialPageRoute(builder:(context)=>HomePage(prefs)));
 }
      else{
  // ignore: use_build_context_synchronously
          var serverIP=prefs.getString('serverIP');
          print('Current Server IP:$serverIP');

Map<String,dynamic> obj={
          "name":Nuser,
          "password":Npass,
          "ID":_deviceID
        };


EncryptData encryptedObj=EncryptData(jsonEncode(obj)); 
await encryptedObj.encrypt();
var encrypted_obj=jsonEncode(encryptedObj.get_output());

print('Remote processing of user input initiated...');

        var uri=Uri.parse('http://$serverIP:2000/admin/login');

        try{
        var resp=await http.post(uri,body:encrypted_obj,headers: <String,String>{'Content-Type':'application/json;charset=UTF-8'});
if(resp.statusCode==200){
  print('User Logged in succesfully...');
// ignore: use_build_context_synchronously
      toggleBtn();
    Navigator.push(context,MaterialPageRoute(builder:(context)=>HomePage(prefs)));
}
else if(resp.statusCode==402){
_ConditionAlert(context,false);  //rendering the status to the user
toggleBtn();
print('Check your credentials...');
}
else{
  _ConditionAlert(context,true);
  toggleBtn();
 print('Server response:${resp.body}');
}
      }
catch(e){
  _ConditionAlert(context,true);
  toggleBtn();
  print('Error found...$e');
}
 }

 } 

   }



Future<void> checkServer(BuildContext context) async{
          var serverIP=prefs.getString('serverIP');
          serverIP==null?serverIP='192.168.43.173':serverIP=serverIP;
          print('Current server IP:$serverIP');
          
  // ignore: avoid_print
  print('checking server...');
  try{
  var uri=Uri.parse('http://$serverIP:2000/ping?id=$_deviceID');
  var resp=await http.get(uri);

if(resp.statusCode==200){
  setState(() {
     serverState=true;
  });
  
 print("Server is active");
  }
  else {
    setState(() {
          serverState=false;
    });

    _ConditionAlert(context,true);
    print('server response:${resp.body}');
  }
  }
// ignore: avoid_print
catch(e){
  _ConditionAlert(context,true);
  print('------>Network issue:$e');}
}

Future<void> toggleBtn() async{
  setState(() {
print('changing button to:$Btnstate');
 Btnstate= (Btnstate==false)?true:false;
  });
}

void waitingDialog(BuildContext context){
  serverState=(serverState==true?false:true);

 if(serverState==true){
  showDialog(
  context: context, 
  builder: (context){
    Future.delayed(Duration(seconds:3),(){Navigator.of(context).pop(true);});
   // if(isLoading==false) Navigator.of(context).pop(true);
    return AlertDialog(
      content:Row(children:<Widget>[
  CircularProgressIndicator.adaptive(),
  SizedBox(width:5),
      const Text('just a sec...'),
        ]),
        
      );
  });
}
else{
  //_ConditionAlert(context,true);
}
}

void server_Notification(context){
  showDialog(
  context: context, 
  builder: (context){
    return AlertDialog(
      title:const Icon(Icons.warning_sharp,color: Colors.yellowAccent,size: 24,),
      content:const Text('please check your email for the new password link...'),
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

Future<void> request_password(BuildContext context) async{
  setState(()=>isLoading=5);
print('@@@@@@@@$username');

    Map<String,dynamic> obj={
          "username":username,
          "ID":_deviceID
    };

    EncryptData encryptedObj=EncryptData(jsonEncode(obj)); 
await encryptedObj.encrypt();
var encrypted_obj=encryptedObj.get_output();

    var uri=Uri.parse('http://$serverIP:2000/forgot-password');
var response=await http.post(uri,body: jsonEncode(encrypted_obj),headers:<String,String>{'Content-Type':'application/json;charset=UTF-8'});
 waitingDialog(context);

if(response.statusCode==200){
  waitingDialog(context);
server_Notification(context);
print('server response recieved...');
}
else if(response.statusCode==402){
  waitingDialog(context);
  _Email_failure_alert(context);
}
else{
  waitingDialog(context);
  _ConditionAlert(context,true);
}
//}
}

@override
void initState() {
    // TODO: implement initState
    super.initState();
  setState((){
    
    _deviceID=prefs.getString('ID');;
  });
  }

  @override
  Widget build(BuildContext context){
     _deviceID=prefs.getString('ID');
       username=prefs.getString('username');
    print('=========$_deviceID');
    serverIP=prefs.getString('serverIP');
  //checkServer(context);

    return Scaffold(
      key: _scaffoldKey,
        body: Stack(
            children:<Widget>[
              MaterialApp(
                    debugShowCheckedModeBanner:false,
                 theme: ThemeData(
        appBarTheme: const AppBarTheme(
          color: Colors.brown,
          elevation: 6.0,
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: const TextTheme(
          titleMedium: TextStyle(color: Colors.white)
        ),
      ),
              ),
                    Image.asset('assets/burgher.jpeg',fit:BoxFit.cover,width:double.infinity,height:double.infinity),
                   const SizedBox(height:20),
               //   Center(child:Text('Login',style:TextStyle(color:Colors.blue, fontSize:30))),
              Padding(
                padding:const EdgeInsets.all(16.0),
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                    Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                               TextFormField(
                    decoration:const InputDecoration(
                      labelText:'name',
                      fillColor: Colors.white,
                hintStyle: TextStyle(color: Colors.white),
                labelStyle: TextStyle(color: Colors.white),
                      ),
                        style:const TextStyle(color:Colors.white),
                   controller:_nameController,
                        validator:(value){
                          if(value!.isEmpty){
                            return 'Enter name';
                          }
                          else {
                            return null;
                          }
                        },
                ),
                 const SizedBox(height:20.0),
                TextFormField(
                  obscureText:true,
                    decoration:const InputDecoration(
                      labelText:'password',
                      fillColor: Colors.white,
                hintStyle: TextStyle(color: Colors.white),
                labelStyle: TextStyle(color: Colors.white),
                      ),
                        style:const TextStyle(color:Colors.white),
                        validator:(value){
                          if(value!.isEmpty){
                            return 'Enter password';
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
               const SizedBox(height:20.0),
                SizedBox(
                  height:50,
                  width:200,
                child:ElevatedButton(
                    onPressed: ()async {
                   //   toggleBtn();
                        await  checkServer(context);
                        await _loginAnalysis(context);
                   
                       },
                    child: Btnstate? 
                    SizedBox(width: 24,height: 24,child:CircularProgressIndicator(strokeWidth: 2.0,color: Colors.blue,),)
                    :const Text('login',style:TextStyle(color:Colors.blue))
                )
                ),
                const SizedBox(height:10.0),
                 GestureDetector(
                onTap:()async{
                await  request_password(context);
                //  Navigator.push(context,MaterialPageRoute(builder:(context)=>LoginPage(prefs)));
                },
                child:const Text('forgot password',style:TextStyle(color:Colors.blue))
              )
              ]
          ) ,
        )]

          ));
  }
}



















