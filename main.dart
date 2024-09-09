// ignore_for_file: use_build_context_synchronously, duplicate_ignore
import 'dart:io';
import 'dart:convert';
//import 'dart:js';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:spacemeals/pages/encryption.dart';
import 'package:spacemeals/pages/network.dart';
import 'package:spacemeals/pages/serverPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spacemeals/pages/login.dart';
import 'package:spacemeals/pages/HomePage.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/services.dart';
import 'package:realm/realm.dart';
//import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
//import 'package:device_info_plus/device_info_plus.dart';


var isSensorAvailable;//=LocalAuthentication().canCheckBiometrics;
var database;
final config=Configuration.local([newUser.schema]);  //for remote database configuration
final realm=Realm(config);
const APP_ID='spacemealsappsync-kmrmdhr';
final app=App(AppConfiguration(APP_ID));
SharedPreferences prefs=SharedPreferences.getInstance() as SharedPreferences;
Map<String,dynamic>  platformData={'token':'','tokenID':''};
Map<String,dynamic>  obj={'status':''};



Future<void> _recieveDataFromPlatform() async{  //incase user clicks on a url provde in an email to confirm the pasword,we extract the token and tokenID from here
  //method channel
  const platform=MethodChannel('com.example.dataChannel');
  try{
    //invoking method to get data
    final Map<String,dynamic> data=await platform.invokeMethod('getData');
  platformData['token']=data['token'];
  platformData['tokenID']=data['tokenID'];
  }
  on PlatformException catch(e){
    print('Failed to recieve data:${e.message}');
  }
}


void main() async{
WidgetsFlutterBinding.ensureInitialized();
 prefs=await SharedPreferences.getInstance();
  runApp(pageConfiguration());
}


class pageConfiguration extends StatelessWidget{
   pageConfiguration({super.key});

  @override
  Widget build(BuildContext context){
    return const MaterialApp(
      home:SplashScreen()
    );
  }
}


class SplashScreen extends StatefulWidget{
  const SplashScreen({super.key});

@override
_SplashScreenState createState()=> _SplashScreenState();
}


class _SplashScreenState extends State<SplashScreen>{
  @override
  void initState(){
    super.initState();
    _recieveDataFromPlatform();
    choosePage();
  }

 choosePage() async{
await Future.delayed(const Duration(seconds:8));
(prefs.getString('currentUser')!=null)?
Navigator.pushReplacement(context,(prefs.getBool('loggedIn')==false)?MaterialPageRoute(builder:(context)=>LoginPage(prefs)):MaterialPageRoute(builder:(context)=>HomePage(prefs))):
Navigator.pushReplacement(context, MaterialPageRoute(builder:(context)=>const MyApp()));
}

@override
Widget build(BuildContext context){
  return Scaffold(
    resizeToAvoidBottomInset:false,
    body: Stack(
            children:<Widget> [
              Image.asset('assets/appLogo.jpg',fit:BoxFit.cover,width:double.infinity,height:double.infinity),
              const  Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('SpaceMeals',style:TextStyle(color: Colors.blueGrey,fontSize:30)),
              SizedBox(height: 20,),
              CircularProgressIndicator()
            ],
          ),
        ),
            ],
  ),
  );
}

}


class MyApp extends StatelessWidget {
   const MyApp({super.key});

  // ignore: non_constant_identifier_names
  Future<void> LoadState(BuildContext context)async{
    prefs.setBool('stateFlag',false);
    prefs.setString(('APP_ID'), APP_ID);
    if(prefs.getString('currentUser')!=null)
    // ignore: curly_braces_in_flow_control_structures
    if(prefs.getBool('loggedIn')==false) {
      Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginPage(prefs)));
    }
    else {
      Navigator.push(context, MaterialPageRoute(builder: (context)=>HomePage(prefs)));
    }
  }


  @override
  Widget build(BuildContext context) {
    ServerCall(prefs);

    return MaterialApp(
      title: 'space food',
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
      home: const SignupPage(title: 'Certus Admin'),
    );
  }
}

class SignupPage extends StatefulWidget {
   const SignupPage({super.key, required this.title});
  final String title;

  @override
  State<SignupPage> createState() => _signupForm();
}




// ignore: camel_case_types
class _signupForm extends State<SignupPage> with SingleTickerProviderStateMixin{
  final _formKey=GlobalKey<FormState>();
  final TextEditingController _nameController=TextEditingController();
  final TextEditingController _refController=TextEditingController();
  final TextEditingController _emailController=TextEditingController();
    final TextEditingController _passwordController=TextEditingController();
    final TextEditingController _serverIPController=TextEditingController();
 final GlobalKey<ScaffoldMessengerState> _scaffoldKey=GlobalKey<ScaffoldMessengerState>();
  bool isChecked=false;
  bool isFingerChecked=false;
  var serverState=true;
  var serverIP;
  var _deviceID;
  var Btnstate=false;


void _ConditionAlert(BuildContext context,bool str) {
showDialog(
  context: context, 
  builder: (context){
    return AlertDialog(
      title:const Icon(Icons.warning_sharp,color: Colors.yellow,size: 24,),
      content: str? const Text('network error,check your server connection'):const Text('this user already exists'),
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
    toggleBtn();
}


  Future<void> _submit(BuildContext context) async{
  try{
    if(_formKey.currentState!.validate()){
String username=_nameController.text.trim();
String email=_emailController.text.trim();
String ref=_refController.text.trim();
String password=_passwordController.text.trim();
String serverIP=_serverIPController.text.trim();

prefs.setString('username',username);
prefs.setString('email',email);
prefs.setString('password',password);
prefs.setString('serverIP', serverIP);
  _getDeviceID();
//await _getDeviceID();

// ignore: deprecated_member_use
prefs.commit();

//network
 ConnectivityResult _connectivityResult=await (Connectivity().checkConnectivity());
Map<String,dynamic> obj;

        var uri=Uri.parse('http://$serverIP:2000/admin/signup');
         obj={
          'name':username,
          'email':email,
          'password':password,
          'deviceID':_deviceID
        };

if(ref!='' || ref!=undefined){
  obj['signer']=ref;
}

EncryptData encryptedObj=EncryptData(jsonEncode(obj)); 
await encryptedObj.encrypt();
var encrypted_obj=jsonEncode(encryptedObj.get_output());

  var resp=await http.post(uri,body:encrypted_obj,headers: <String,String>{'Content-Type':'application/json;charset=UTF-8'});

//remote registration and login
if(_connectivityResult!=ConnectivityResult.none){ //inernet access available??
/*EmailPasswordAuthProvider authProvider=EmailPasswordAuthProvider(app);
await authProvider.registerUser(username, password);

final userCredentials=Credentials.emailPassword(username,password);
await app.logIn(userCredentials);
*/}


if(resp.statusCode==200){
// ignore: use_build_context_synchronously, avoid_print
    print('Server signUp successful...');
    // ignore: duplicate_ignore
    // ignore: use_build_context_synchronously
prefs.setBool('backedUpYesterday',false);
prefs.setBool('autoBackup',false);
prefs.setString('schedule_time',TimeOfDay.now().toString()); 

    Navigator.push(context,MaterialPageRoute(builder:(context)=> HomePage(prefs)));
}
if(resp.statusCode==403){
    print('signup failed...${resp.body}');
    toggleBtn();
      _ConditionAlert(context,false);
}
      else {
      // ignore: avoid_print
      print('signup failed...${resp.body}');
      toggleBtn();
      _ConditionAlert(context,true);
    }
    }
  }
  catch(e){
     _ConditionAlert(context,true);
     toggleBtn();
    print('***Error:$e');
  }
        }

  Future<void> checkServer() async{
          var serverIP=prefs.getString('serverIP');
          serverIP==null?serverIP='192.168.43.173':serverIP=serverIP;
  // ignore: avoid_print
  print('checking server...at:$serverIP');
  try{
  var uri=Uri.parse('http://$serverIP:2000/ping?id=$_deviceID');
  var resp=await http.get(uri);

if(resp.statusCode==200){
setState(() {
  serverState=true;
});
 // ignore: avoid_print
 print('The server is active...');
  }
  else{
    serverState=false;
    _ConditionAlert(context,true);
      toggleBtn();
    print('The server is not responding...');
  }
  }
// ignore: avoid_print
catch(e){
  // ignore: avoid_print
  print('------>Network issue:$e');}
}

Future<void> _getDeviceID() async{
final DateTime dateStr=DateTime.now();
final DateFormat newLook=DateFormat('yyyymmddHmm');
final String generatedDate=newLook.format(dateStr);
var ID;

try{
 ID=Uuid.v4();
  }
catch(e){
  print('failed to get device ID:$e');
}

setState((){
_deviceID='$generatedDate-$ID';
prefs.setString('ID',_deviceID);
});
}


Future<void> toggleBtn() async{
  setState(() {
 Btnstate= (Btnstate==false)?true:false;
  });
}


@override
void initState() {
    // TODO: implement initState
    super.initState();
  _getDeviceID();
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        resizeToAvoidBottomInset:false,
      key: _scaffoldKey,
      body: Stack(        
          children: <Widget>[
            Image.asset('assets/burgher.jpeg',fit:BoxFit.cover,width:double.infinity,height:double.infinity),
              const SizedBox(height:5),
              Padding(padding:const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   const Center(child:Text('Certus Admin',style:TextStyle(color:Colors.blue, fontSize:30,fontFamily: 'Roboto'))),
                   Form(
                    key:_formKey,
                    child:Column(
                      children: <Widget>[
                TextFormField(
              controller:_nameController,
              decoration:const InputDecoration(
                labelText:'name',
                fillColor: Colors.white,
                hintStyle: TextStyle(color: Colors.white),
                labelStyle: TextStyle(color: Colors.white),
              ),
                validator:(value){
                          if(value!.isEmpty){
                            return 'Enter your name';
                          }
                          else {
                            return null;
                          }
                        },
                style:const TextStyle(color:Colors.white)
              ),
                const SizedBox(height:20.0),

                        TextFormField(
              controller:_emailController,
              decoration:const InputDecoration(
                labelText:'email',
                fillColor: Colors.white,
                hintStyle: TextStyle(color: Colors.white),
                labelStyle: TextStyle(color: Colors.white),
              ),
                validator:(value){
                          if(value!.isEmpty){
                            return 'Enter your email';
                          }
                          else {
                            return null;
                          }
                        },
                style:const TextStyle(color:Colors.white)
              ),
                const SizedBox(height:20.0),
              TextFormField(
                obscureText:true,
                controller:_passwordController,
                decoration:const InputDecoration(labelText:'password',
                fillColor: Colors.white,
                hintStyle: TextStyle(color: Colors.white),
                labelStyle: TextStyle(color: Colors.white),
                ),
                        validator:(value){
                          if(value!.isEmpty){
                            return 'Enter your password';
                          }
                          else {
                            return null;
                          }
                        },
                  style:const TextStyle(color:Colors.white)
              ),

                TextFormField(
              controller:_refController,
              decoration:const InputDecoration(
                labelText:'referral ID (optional)',
                fillColor: Colors.white,
                hintStyle: TextStyle(color: Colors.white),
                labelStyle: TextStyle(color: Colors.white),
              ),
                style:const TextStyle(color:Colors.white)
              ),
                const SizedBox(height:20.0),

              TextFormField(
                controller:_serverIPController,
                decoration:const InputDecoration(labelText:'remote server IP',
                fillColor: Colors.white,
                hintStyle: TextStyle(color: Colors.white),
                labelStyle: TextStyle(color: Colors.white),
                ),
                        validator:(value){
                          if(value!.isEmpty){
                            return 'Enter Server IP';
                          }
                          else {
                            return null;
                          }
                        },
                  style:const TextStyle(color:Colors.white)
              )
                      ],
                    )), 
       const   SizedBox(height:20.0),    
          SizedBox(
              height:50,
              width:200,
          child:ElevatedButton(
            onPressed: () async{
              await  _submit(context);
              // await checkServer();
             /*(serverState==false)?await  _submit(context):(
                showDialog(
  // ignore: duplicate_ignore
  // ignore: use_build_context_synchronously
  context: context, 
  builder: (context){
    return AlertDialog(
      title:const Row(
        children: <Widget>[
          Icon(Icons.warning_amber_sharp,color: Colors.yellow,),
        Text('Error')
        ],
      ),
      content:const Text('please check your server connection'),
      actions: [
        TextButton(
          onPressed:()async{
             // ignore: duplicate_ignore
             // ignore: use_build_context_synchronously
             Navigator.of(context).pop();
             } ,
           child:const Text('ok')),
      ],
    );
  })
             );*/
                },
            style: ElevatedButton.styleFrom(
              backgroundColor:Colors.blue ,
              foregroundColor: Colors.white,


            ),
            child:Btnstate? 
                    SizedBox(width: 24,height: 24,child:CircularProgressIndicator(strokeWidth: 2.0,color: Colors.white,),) 
            :const Text('signup',style:TextStyle(color:Colors.white)),
          )
          )
,
          const  SizedBox(height:5.0),
          SingleChildScrollView(
           child: Row(
              children:<Widget>[
             const Text('Already have an account?',style:TextStyle(fontFamily: 'Roboto',color: Colors.white)),
              GestureDetector(
                onTap:(){
                  Navigator.push(context,MaterialPageRoute(builder:(context)=>LoginPage(prefs)));
                },
                child:const Text('login',style:TextStyle(color:Colors.blue))
              )
           ] ),)
   
                ],
              ),
              
              )
              
    ],
        )),
    );

  }
}




