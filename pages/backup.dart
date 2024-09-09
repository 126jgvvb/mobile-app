import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spacemeals/pages/obj32.dart';
import 'package:sembast/sembast.dart';
import 'package:spacemeals/pages/encryption.dart';
import 'package:spacemeals/pages/HomePage.dart';

// ignore: prefer_typing_uninitialized_variables
var serverIP;
var ID;
var store=stringMapStoreFactory.store('my_store');
var Agents=[];
double progressBarValue=0.0;

// ignore: must_be_immutable
class Backup extends StatefulWidget{
  SharedPreferences prefs;
  Backup(this.prefs,{super.key});

  @override
  // ignore: no_logic_in_create_state
  State<Backup> createState()=>_BackupData(prefs);
}


class _BackupData extends State<Backup>{
// ignore: prefer_typing_uninitialized_variables
var isLoading=false;
bool _dataState=false;
bool serverState=false;
// ignore: non_constant_identifier_names
bool Backup_yestterday=false;
  // ignore: non_constant_identifier_names
  DateTime DataDate=DateTime.now();
  SharedPreferences prefs;

  _BackupData(this.prefs);

  void _DownloadNotify(BuildContext context) {
showDialog(
  context: context, 
  builder: (context){
    return AlertDialog(
      content:Row(children:<Widget>[

  CircularProgressIndicator.adaptive(),
  SizedBox(width:5),
      const Text('Backingup...'),
        ]),
        
      );
  });
print('prefs.serverIP:${prefs.getString('serverIP')}');
}

  
void _ConditionAlert(BuildContext context,bool str) {
showDialog(
  context: context, 
  builder: (context){
    return AlertDialog(
      title:const Text('Alert'),
      content:str?const Text('Data upload successful...'):const Text('Network error/something is wrong with the server...'),
      actions: [
        TextButton(
          onPressed:()async{
    Navigator.of(context).pop();
     Navigator.push(context,MaterialPageRoute(builder: ((context) => HomePage(prefs))));
              },
           child:const Text('ok')
  ),
      ],
    );
  });
print('prefs.serverIP:${prefs.getString('serverIP')}');
}

Future<Database> openDatabase() async{
final appDir=await getApplicationDocumentsDirectory();
      await appDir.create(recursive:true);
      var dbPath=join(appDir.path,'spacemeals.db');
      var database=await databaseFactoryIo.openDatabase(dbPath);
    return database;
}

Future<void> initData()async{
  var db=await openDatabase();
 var dataToBackup=await store.find(db);
var  dataSize=dataToBackup.length-1;
var cnt=0;

while(dataSize>=cnt){
  var temp=Agent32.fromJson(dataToBackup[cnt].value);
  var tempjson=temp.tojson();
  Agents.add(tempjson);
  print('Done packing:${temp.name}');
  ++cnt;
}


await db.close();
 setState(() {
    _dataState=true;
 });
}

void _warnUser(BuildContext context) {
showDialog(
  context: context, 
  builder: (context){
    return AlertDialog(
      title:const Text('Alert'),
      content:const Text('This operation might not be repeated again today.continue?'),
      actions: [
        TextButton(
          onPressed:()async{
    Navigator.of(context).pop();
             await  SendDataToServer(context);
              },
           child:const Text('ok')
  ),
        TextButton(
          onPressed:()async{
    Navigator.of(context).pop();
              },
           child:const Text('cancel')
  ),
      ],
    );
  });
print('prefs.serverIP:${prefs.getString('serverIP')}');
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
      const Text('Backing up...'),
        ]),
        
      );
  });
}
else{
  //Navigator.of(context).pop();
}
}

// ignore: non_constant_identifier_names
Future<void> SendDataToServer(BuildContext context) async{
if(serverState==false){
  _ConditionAlert(context,false);
}
else{
 _warnUser(context);
if(prefs.getString('prevBackup')==('${DataDate.day}-${DataDate.month}')){
  void ConditionAlert(BuildContext context) {
showDialog(
  context: context, 
  builder: (context){
    return AlertDialog(
      title:const Text('Alert'),
      content:const Text('This Data has been already uploaded...'),
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
print('prefs.serverIP:${prefs.getString('serverIP')}');
}

ConditionAlert(context);
}

else{
print('>>>>>>>>>>>>>>>>>Initiating upload on IP:$serverIP');
await  checkLastBackup();
Agents.add({'date':DataDate.toString()});

print('>>>>>>>>>>>>>>>>>>>>>>>Transferring:$Agents');

Map<String,dynamic> obj={'Agents':Agents,'ID':ID};

/*
    EncryptData encryptedObj=EncryptData(jsonEncode(obj)); 
await encryptedObj.encrypt();
var encrypted_obj=encryptedObj.get_output();
*/
  try{
   waitingDialog(context);
   // _DownloadNotify(context);

  var uri=Uri.parse('http://$serverIP:2000/database/backup');
  var resp=await http.post(uri,body:jsonEncode(obj),headers: <String,String>{'Content-Type':'application/json;charset=UTF-8'});

  if(resp.statusCode==200){
   waitingDialog(context);
    _ConditionAlert(context,true);
    print('Backup successful...');
    Agents=[]; //important
    
      prefs.setString('prevBackup', '${DataDate.day}-${DataDate.month}');
  }
  else if(resp.statusCode==402){
    waitingDialog(context);
    print("Backup error:${resp.body}");
        Agents=[]; //important
            _dataState=false;
  }
  else{
    waitingDialog(context);
    _ConditionAlert(context,false);
  }
  }
  catch(e){
  _ConditionAlert(context,false);
    print('Error:$e');
        Agents=[]; //important
            _dataState=false;
  }
}
}
}

Future<void> checkServer(BuildContext context) async{
  // ignore: avoid_print
  print('checking server...');
  try{
  var uri=Uri.parse('http://$serverIP:2000/ping?id=$ID');
  var resp=await http.get(uri);


if(resp.statusCode==200){
   setState(() {
   final data=json.decode(resp.body);
  serverState=true;
   // ignore: avoid_print
   print('------------>The server responded with:${data["message"]}');});
  }
else { 
  // ignore: avoid_print
     _ConditionAlert(context,true);
  print('----------->some result:${resp.statusCode}');
  }
  }
// ignore: avoid_print

catch(e){
   _ConditionAlert(context,false);
  print('------>Network issue:$e');}
}


Future<void> getCurrentTime() async{
  DateTime cDate=DateTime.now();
  setState((){DataDate=cDate;});

}


Future<void> checkLastBackup() async{
  setState((){
  Backup_yestterday=(prefs.getBool('backedUpYesterday')==null)?false:true;
  });

}

@override
void initState(){
  super.initState();
 getCurrentTime();
  checkLastBackup();
  ID=prefs.getString('ID');
  serverIP=prefs.getString('serverIP');
}


@override
Widget build(BuildContext context){
 //checkServer(context);

(!_dataState)?_dataState=false:_dataState=true;
(!Backup_yestterday)?Backup_yestterday=false:Backup_yestterday=true;

return MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Scaffold(
    appBar: AppBar(
      backgroundColor:Colors.brown ,
      leading: GestureDetector(
        onTap: (){Navigator.pop(context);},
        child:const Icon(Icons.arrow_back,color:Colors.white),
      ),
      title: const Text('Backup',style:TextStyle(color:Colors.white)),
    ),
   body:Stack(
    children:<Widget> [
     ListView(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 40),
     children: <Widget>[
       ListTile(
         leading: const Text('Data Date:',style: TextStyle(fontSize: 15)),
        title: Text('${DataDate.day}-${DataDate.month}-${DataDate.year}')
      ),
 
             const Divider(color:Colors.grey,height:7,),
        ListTile(
         leading: const Text('Last Backup Date:',style: TextStyle(fontSize: 15),),
        title:  Backup_yestterday?const Icon(Icons.check,color: Colors.green,):const Icon(Icons.clear,color: Colors.red,)
      ),
       const Divider(color:Colors.grey,height:7,),
     ElevatedButton(
              onPressed:()async{
               await checkServer(context);
                await initData();
                SendDataToServer(context);
              },
              style: ElevatedButton.styleFrom( backgroundColor:Colors.blue ,foregroundColor: Colors.white,),
               child: const Text('Backup',style: TextStyle(color: Colors.white),)),
     ] 
     )

    ],
   ))
);

}
}



