// ignore: file_names
//import 'dart:html';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:spacemeals/pages/login.dart';
import 'package:spacemeals/pages/serverPage.dart';
import 'package:spacemeals/pages/backup.dart';
import 'package:spacemeals/pages/list.dart';
import 'package:http/http.dart' as http;
import 'package:spacemeals/pages/scanner_widget.dart';
import 'package:spacemeals/pages/settings.dart';
import 'package:sembast/sembast_io.dart';
import 'package:spacemeals/pages/encryption.dart';
import 'package:spacemeals/pages/obj32.dart';
//import 'package:spacemeals/pages/obj32.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:spacemeals/pages/userProfile.dart';

var AgentName;
var prefStore;
var currentDate=DateTime.now();
   StoreRef<String,dynamic> store=stringMapStoreFactory.store('my_store');


Future<Database> openDatabase() async{
final appDir=await getApplicationDocumentsDirectory();
      await appDir.create(recursive:true);
      store=stringMapStoreFactory.store('my_store');
      var dbPath=join(appDir.path,'spacemeals.db');

       database=await databaseFactoryIo.openDatabase(dbPath);
        return database;
}

void closeDataBase() async{
  await database.close();
}

// ignore: must_be_immutable
class HomePage extends StatefulWidget{
  SharedPreferences prefs;
   HomePage(this.prefs,{super.key});


  @override
  State<HomePage> createState()=>_mainPage(prefs);
}


// ignore: camel_case_types
class _mainPage extends State<HomePage>{
final DateTime _currentDate=DateTime.now();
final GlobalKey<ScaffoldState> _scaffkey=GlobalKey<ScaffoldState>();
 final AppLifecycleObserver _observer=AppLifecycleObserver();
SharedPreferences prefs;

_mainPage(this.prefs);

@override
void initState(){
  super.initState();
  checkLastDataState();
   WidgetsBinding.instance.addObserver(_observer);
  prefStore=prefs;
}

@override
  void dispose(){
  super.dispose();
  WidgetsBinding.instance.removeObserver(_observer);
}

void checkLastDataState() async{
  print('checking app state...');
    if(prefs.getString('today')!=jsonEncode(currentDate.day) && prefs.getString('today')!=null){  //new day?,reseting lunchState to 'No' 
  print('Reseting agent lunch state...');

     var storage=await openDatabase();
        var Agent=await store.find(storage);
      var AgentCnt=Agent.length-1;
      var cnt=0;

        // ignore: avoid_print
        while(AgentCnt>=cnt){
     try{
          final obj=Agent32.fromJson(Agent[cnt].value);
              print('>>>>>>>>>>>>>>>>>Reseting:${obj.name}');
          await store.record('record${obj.name}').delete(storage);
          obj.hadLunch='No';
          await store.record('record${obj.name}').put(storage,obj.tojson());
     }
     catch(e){
      print('Agent update Error:$e');
     }

     cnt++;
    }
    }
    else{
      print('App state is still within the current date...');
    }



}

void _showLogoutConfirmation(BuildContext context) {
showDialog(
  context: context, 
  builder: (context){
    return AlertDialog(
      title:const Text('logout'),
      content:const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed:()async{
            try{
                     var serverIP=prefs.getString('serverIP');
          serverIP ?? (serverIP='192.168.43.173');  //if it is null
                  prefs.setBool("loggedIn",false);
                  // ignore: deprecated_member_use
                  prefs.commit();  //saving...

                  print('current server IP:$serverIP');

                  Map<String,dynamic> obj={
                  'ID':prefs.getString('ID')
                  };

                  EncryptData encryptedObj=EncryptData(jsonEncode(obj)); 
await encryptedObj.encrypt();
var encrypted_obj=encryptedObj.get_output();
     Navigator.push(context,MaterialPageRoute(builder: (context)=>LoginPage(prefs)));


            var uri=Uri.parse('http://$serverIP:2000/admin/logout');  //?bringData=${ToExcelFile}

            var resp=await http.post(uri,body:jsonEncode(encrypted_obj),headers: <String,String>{'Content-Type':'application/json;charset=UTF-8'});
            if(resp.statusCode==200){
              // ignore: avoid_print
              print('User successfully loggedout...');
                       // ignore: use_build_context_synchronously
             Navigator.push(context,MaterialPageRoute(builder: (context)=>LoginPage(prefs)));
             exit(0);
             } 
            else{
                 Navigator.push(context,MaterialPageRoute(builder: (context)=>LoginPage(prefs)));
            }
            }
            catch(e){
              print('Logout Error:$e');
            }
            //end here
              },
           child:const Text('yes')
  ),
           TextButton(
            onPressed:(){Navigator.of(context).pop();},
             child:const Text('No'))
      ],
    );
  });
print('prefs.serverIP:${prefs.getString('serverIP')}');
}

Future<void> checkServer() async{
  SharedPreferences prefs=await SharedPreferences.getInstance();
var  serverIP=prefs.getString('severIP');

  var uri=Uri.parse('http://$serverIP:2000/ping');
  var resp=await http.get(uri);

if(resp.statusCode==200){ setState(() {
  prefs.setBool('serverState', true);
  print('The server is active...');
});
}
else{
  print('retrying...');
//  checkServer();
}
}

@override
Widget build(BuildContext context){
 return Scaffold(
    resizeToAvoidBottomInset: false,
    appBar:AppBar(
      backgroundColor:Colors.brown ,
      title:Text('TODAY:${_currentDate.day}-${_currentDate.month}-${_currentDate.year}',style:const TextStyle(color: Colors.white)),
      actions:<Widget>[
        IconButton(
          icon:const Icon(Icons.person,color: Colors.white,),
          onPressed:(){
               Navigator.push(context, MaterialPageRoute(builder:(context)=>profileRender(prefs)));
          }
        ),
        IconButton(
            icon:const Icon(Icons.logout,color: Colors.white,),
            onPressed:(){
              _showLogoutConfirmation(context);
            }
        ),
      ]
    ),
    body:Container(
      child:Stack(
   //   child:QRScan(),
      children: [
        Container(
          color:Colors.black,
          width:double.infinity,
          height:double.infinity,
          child: const QRScan(),  //RScan()
        ),
        scannerScreen(),
      ],
    ), ),


    bottomNavigationBar:SingleChildScrollView(
      child: bottomNav(prefs),
    )
   ,
    drawer: Drawer(
      key: _scaffkey,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
        const UserAccountsDrawerHeader(decoration: BoxDecoration(color: Colors.brown),
          accountName: Text('certusAdmin'), 
          accountEmail: Text('wadikakevin@gmail.com'),
          currentAccountPicture:CircleAvatar(backgroundImage:AssetImage('assets/pizza.jpeg') ,),
          ), 
          ListTile(
            leading:const Icon(Icons.cloud),
            title:const Text('Server session'),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder:(context)=>ServerCall(prefs)));
            },
          ),
          const Divider(color:Colors.grey,height:7,),
            ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Backup'),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder:(context)=>Backup(prefs)));
            },
          ),
              const Divider(color:Colors.grey,height:7,),
            ListTile(
            leading: const Icon(Icons.power_off),
            title: const Text('Exit'),
            onTap: () async{
             // ignore: deprecated_member_use
             print('Saving changes...');
                   prefs.setString("today",jsonEncode(currentDate.day));
             // ignore: deprecated_member_use
             await prefs.commit();
             dispose();
             print('Changes saved...');
              exit(0);
            },
          )
        ],
      ),
    ),

  ); 
}

}




// ignore: camel_case_types
class bottomNav extends StatefulWidget{
  SharedPreferences prefs;
  bottomNav(this.prefs,{super.key});

  @override
  State<bottomNav> createState()=> _bottomNavigation(prefs);
}


// ignore: camel_case_types
class _bottomNavigation extends State<bottomNav>{
  SharedPreferences prefs;
int _selectedIndex=0;
var ctx;
_bottomNavigation(this.prefs);

//irrelevant

void _onSelected(BuildContext context,int value){
  setState(() {
    _selectedIndex=value;
    if(value==0) Navigator.push(context,MaterialPageRoute(builder: (context)=> HomePage(prefs) ));
    if(value==1) Navigator.push(context,MaterialPageRoute(builder: (context)=> ListPage(ListCnt:0,prefs: prefs,)));
    if(value==2) Navigator.push(context,MaterialPageRoute(builder: (context)=>settings(prefs)));   //settings(prefs)
  });
}

@override
Widget build(BuildContext context){
  ctx=context;
  return BottomNavigationBar(
    backgroundColor: Colors.brown,
    elevation: 6.0,
      items:const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon:Icon(Icons.home,color: Colors.white,),
          label:'Home', 
        ),
         BottomNavigationBarItem(
          icon:Icon(Icons.list,color: Colors.white,),
          label:'List',
        ),
         BottomNavigationBarItem(
          icon:Icon(Icons.settings,color: Colors.white,),
          label:'Setting',
        )
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.blue,
      onTap:(selectedIndex){
         _onSelected(ctx,selectedIndex);
      },
    );
}
}



class QRScan extends StatefulWidget{
  const QRScan({super.key});

  @override
 createState()=>QRinterface();
}


class  QRinterface extends State<QRScan>{
late QRViewController controller;
final GlobalKey qrKey=GlobalKey(debugLabel:'QR');
// ignore: null_check_always_fails
Barcode? result;
StoreRef<String,dynamic> store=stringMapStoreFactory.store('my_store');
var database;
var ctx;

void conditionAlert(BuildContext context) {
 showDialog(
  context: context, 
  builder: (context){
    return AlertDialog(
      title:const Text('Alert'),
      content:AgentName!=null?Text('$AgentName confirmed'):const Text('Unidentified code')/* Text('Scanned Signature:${result?.code}')*/,
      actions: [
        TextButton(
          onPressed:()async{
          return  Navigator.of(context).pop();
              },
           child:const Text('ok')
  ),
      ],
    );
  });
}


void TextAlert(BuildContext context,str) {
 showDialog(
  context: context, 
  builder: (context){
    return AlertDialog(
      title:const Text('Alert'),
      content:Text('INFO:$str')/* Text('Scanned Signature:${result?.code}')*/,
      actions: [
        TextButton(
          onPressed:()async{
          return  Navigator.of(context).pop();
              },
           child:const Text('ok')
  ),
      ],
    );
  });
}


Future<void> _onQRViewCreated(QRViewController controller)async {
  controller.scannedDataStream.listen((scanData)async{
    // ignore: avoid_print
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>coded data detected:$scanData");
     setState(() {
       result=scanData;
     });
        // controller.dispose();

     // ignore: non_constant_identifier_names
     var storage=await openDatabase();
    //  var Agent=await store.find(storage,finder:Finder(filter:Filter.equals('signature', scanData) ));
        var Agent=await store.find(storage);
      var AgentCnt=Agent.length-1;
      var cnt=0;

        // ignore: avoid_print
        while(AgentCnt>=cnt){
     try{
          final obj=Agent32.fromJson(Agent[cnt].value);

      if(obj.signature==result?.code){
        setState((){
          AgentName=obj.name;
          });
            
              print('>>>>>>>>>>>>>>>>>formating record for:${obj.name}');
          await store.record('record${obj.name}').delete(storage);
          obj.hadLunch='yes';
          await store.record('record${obj.name}').put(storage,obj.tojson());
                  print('Agent detected:${obj.name}');
                        print('Agent name:$AgentName');
     }
     }
     catch(e){
      print('Agent update Error:$e');
     }

     cnt++;
      }

   conditionAlert(ctx);
      print('******************$AgentCnt...$AgentName');
      
    //  controller.dispose();
  });
}

@override
void dispose(){
  controller.dispose();
  super.dispose();
}

  @override
  Widget build(BuildContext context){
ctx=context;

return Column(
      children:<Widget>[
        Expanded(
            flex:4,
            child:QRView(
            key:qrKey,
  onQRViewCreated:_onQRViewCreated,
      )
            ),
      const Expanded(
    flex:1,
    child:Center(
    child://(result!=null)?Text('Data:${result?.code}',style:TextStyle(color:Colors.white))
   Text('Scan QR code',style:TextStyle(color:Colors.white))
    )
    )
  ]
      );
}
}



// ignore: camel_case_types
class scannerScreen extends StatefulWidget{
  const scannerScreen({super.key});


@override
State<scannerScreen> createState()=> _initScanner();

}


// ignore: camel_case_types
class _initScanner extends State<scannerScreen> with SingleTickerProviderStateMixin{

late AnimationController _animationController;
Animation<double>? _animation;
final bool _animationStopped=false;
String scanText='Scan';
bool scanning=false;

@override
void initState(){
_animationController =AnimationController(duration:const Duration(seconds:2), vsync:this)..repeat(reverse: true);
_animation=Tween<double>(begin:0,end:1).animate(_animationController);

_animationController.addStatusListener((status) {
  if(status==AnimationStatus.completed){
    animateScanAnimation(true);
  }
  else if(status==AnimationStatus.dismissed){
    animateScanAnimation(false);
  }
});
_animationController.forward(from: 0.0);

super.initState();
}

@override
void dispose(){
  _animationController.dispose();
  super.dispose();
}

@override
Widget build(BuildContext context){
  return LayoutBuilder(
    builder:(context,constraints){
       return AnimatedBuilder(
    animation: _animation!,
     builder: (context,child){
      return Stack(
        children:[
          Positioned(
        top:MediaQuery.of(context).size.height*_animation!.value,
        left:0,
        right: 0,
        child:child!,
      )
        ]
      );
     },
     child:Container(
      height:1.0,
      color:Colors.red,
     ),
     );
    }
  );
 /*
  return Column(
        children:<Widget>[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                      borderRadius: const BorderRadius.all(Radius.circular(12))),
                        child:Stack(
                          children: <Widget>[
                             ImageScanner(_animationStopped,1334,animation: _animationController,)//1334
                          ],
                        ) 
                    ),
        ]
  );*/
}

void animateScanAnimation(bool reverse){
(reverse)?_animationController.reverse(from:1.0):_animationController.forward(from: 0.0);
}



}



class AppLifecycleObserver extends WidgetsBindingObserver{
  @override
  void didChangeAppLifecycleState(AppLifecycleState state){
    super.didChangeAppLifecycleState(state);
    if(state==AppLifecycleState.paused){
      print('App pause or termination detected...');
      prefStore.setBool("abruptShutdown",true);
      prefStore.setString("today",jsonEncode(currentDate.day));
      // ignore: deprecated_member_use
      prefStore.commit();
    }
  }
}



























