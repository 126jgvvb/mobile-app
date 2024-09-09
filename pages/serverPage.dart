// ignore: file_names
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:sembast/sembast_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spacemeals/pages/HomePage.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:spacemeals/pages/obj32.dart';
import 'package:path/path.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:image/image.dart' as img;

var serverIP;
// ignore: non_constant_identifier_names
var AgentSignature='test@123';
DateTime currentDate=DateTime.now();
 List<Agent32> AgentSignatures=List.empty(growable: true);
var databaseDB;
int grossCnt=1;
int cnt=0;
int dataCnt=0;
bool Nodata=false;
//final StoreRef<String,dynamic> store=stringMapStoreFactory.store('my_store');
final  store=stringMapStoreFactory.store('my_store');

Future<Database> openDatabase() async{
final appDir=await getApplicationDocumentsDirectory();
      await appDir.create(recursive:true);
      var dbPath=join(appDir.path,'spacemeals.db');
      var   database=await databaseFactoryIo.openDatabase(dbPath);
      return database;
}



// ignore: must_be_immutable
class ServerCall extends StatefulWidget{
  SharedPreferences prefs;
ServerCall(this.prefs,{super.key});

  @override
  State<ServerCall> createState()=>_initServerSession(prefs);
}


// ignore: camel_case_types
class _initServerSession extends State<ServerCall>{
// ignore: non_constant_identifier_names
bool ToExcelFile=false;
// ignore: prefer_typing_uninitialized_variables
var obtainedData;
bool serverState=false;
// ignore: prefer_typing_uninitialized_variables
SharedPreferences prefs;
var date;
var ID;
// ignore: non_constant_identifier_names
final MrImage=QrImageView(data: AgentSignature,size: 200,version: QrVersions.auto,);


_initServerSession(this.prefs);

void _ConditionAlert(BuildContext context,bool str) {
showDialog(
  context: context, 
  builder: (context){
    return AlertDialog(
      title:const Text('Alert'),
      content:str?const Text('Data has been successfully downloaded'):const Text('Network error/something is wrong with the server...'),
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


void _DownloadNotify(BuildContext context) {
showDialog(
  context: context, 
  builder: (context){
    return AlertDialog(
      content:Row(children:<Widget>[
  CircularProgressIndicator.adaptive(),
  SizedBox(width:5),
      const Text('please wait...'),
        ]),
        
      );
  });
print('prefs.serverIP:${prefs.getString('serverIP')}');
}

Future<void> deleteDB() async{
  final appDir=await getApplicationDocumentsDirectory();
      await appDir.create(recursive:true);
      var dbPath=join(appDir.path,'spacemeals.db');
      var DBfile=File(dbPath);

      if(await DBfile.exists()){
        await DBfile.delete();
        setState(() {
          dataCnt=0;
        });
        print('cleaning procedure successful');
      }

}

void closeDataBase() async{
  var db=await openDatabase();
  await db.close();
}


Future<void> confirmDataErase(BuildContext context) async{
  showDialog(
  context: context, 
  builder: (context){
    return AlertDialog(
      title:const Text('Alert'),
      content:const Text('Delete data?'),
      actions: [
        TextButton(
          onPressed:()async{
            await deleteDB();

            if(dataCnt==0) await showDialog(
  context: context, 
  builder: (context){
    return AlertDialog(
      title:const Text('Alert'),
      content:const Text('Data erasing successful...?'),
      actions: [
        TextButton(
          onPressed:()async{
               Navigator.of(context).pop();
              },
           child:const Text('ok')
  ),],
    );
  });

    Navigator.of(context).pop();
              },
           child:const Text('yes')
  ),
     TextButton(
          onPressed:()async{
    Navigator.of(context).pop();
              },
           child:const Text('No')
  ),
      ],
    );
  });
}

Future <void> _submit(BuildContext context,date) async{
//serverIP=(prefs.getString('serverIP') ?? '192.168.43.173');
 if(serverState==false){  _ConditionAlert(context,true);}

else{
Map<String,dynamic> obj={
  'ID':ID,
  'date':date
};

var uri=Uri.parse('http://$serverIP:2000/database/getAgents');  

var resp=await http.post(uri,body:jsonEncode(obj),headers:<String,String>{'Content-Type':'application/json;charset=UTF-8'});
_DownloadNotify(context);
//await http.post(uri,body:jsonEncode({'date':'${currentDate.day}-${currentDate.month}-${currentDate.year}'}),headers: <String,String>{'Content-Type':'application/json;charset=UTF-8'});

try{
if(resp.statusCode==200){
  if(!ToExcelFile){  //data has been imported
      obtainedData=json.decode(resp.body);
      cnt=obtainedData['maxCnt']-1;
      // ignore: avoid_print
      print('Data length:${obtainedData['maxCnt']}');
      print('---------->recievedData:${obtainedData["data"]}');

 //   await deleteDB();

while(cnt>-1){
Agent32 obj=Agent32(obtainedData["data"][cnt]['name'],obtainedData["data"][cnt]['signature'],obtainedData["data"][cnt]['batch'], obtainedData["data"][cnt]['hadLunch']);
AgentSignatures.add(obj);
//await deleteDB();
prefs.setBool('stateFlag',false);
var db=await openDatabase();
var jsonObj=obj.tojson();
await store.record('record${obj.name}').put(db,jsonObj);
print('***********saving*************');
print('print code...');

--cnt;
}

closeDataBase();
// ignore: avoid_print
 _ConditionAlert(context,true);
print('----------->Data storage complete');

}  
}
//else here
}
catch(e){
  _ConditionAlert(context, false);
  print('Network error:$e');
}
}
}


Future<void> pickDate(context)async{
 final  DateTime? pickedDate=await  showDatePicker(context:context,initialDate:currentDate , firstDate: DateTime(currentDate.year,currentDate.month,1), lastDate:DateTime(currentDate.year,currentDate.month,30));

if(pickedDate!=null && pickedDate!=currentDate){
setState(() {
  currentDate=pickedDate;
  prefs.setString('date',currentDate.toIso8601String());
  date=pickedDate;
});
}
}

// ignore: non_constant_identifier_names
Future <void> LoadsavedIP()async {
SharedPreferences prefs=await SharedPreferences.getInstance();
if(prefs.getString('savedIP')!=null){
setState(()async {
  serverIP=prefs.getString('savedIP') as String;
});    }
else{ 
   serverIP='192.168.43.173';
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
   serverState=true;
   final data=json.decode(resp.body);
   // ignore: avoid_print
   print('------------>The server responded with:${data["message"]}');});
  }
else {
    _ConditionAlert(context,true); 
  // ignore: avoid_print
  print('----------->some result:${resp.statusCode}');
  }
  }
// ignore: avoid_print
catch(e){
  _ConditionAlert(context,false);
  print('------>Network issue:$e');}
}

@override
void initState(){
  super.initState();
  prefs.setString('date', 'empty');
  ID=prefs.getString('ID');
  serverIP=prefs.getString('serverIP');
  print('---------------date----$ID');
}

@override
Widget build(BuildContext context){
//LoadsavedIP();
checkServer(context);

return MaterialApp(
   debugShowCheckedModeBanner:false,
home:Scaffold(
    appBar: AppBar(
      backgroundColor:Colors.brown ,
      leading: GestureDetector(
        onTap: (){Navigator.pop(context);},
        child:const Icon(Icons.arrow_back,color:Colors.white),
      ),
      title:const Text('Server session',style:TextStyle(color:Colors.white)),
    ),
    body: Stack(
      children:<Widget> [
          ListView(   
          children:<Widget>[
            ListTile(
               leading:const Text('server IP address:',style: TextStyle(fontSize: 16),),
              title:TextField(
                autofocus: false,
                maxLength: 14,
                onChanged: (value) =>{
                  if(value.length>=8){ 
                   setState(() async{
                     serverIP=value;
                    prefs.setString('serverIP',serverIP);
                   }),
                    print('NewSaved Ip:$serverIP')
                     }  
                   }),
            ),
         
              const Divider(color:Colors.grey,height:7,),
              ListTile(
                leading: Text('IP Address:$serverIP',style:const TextStyle(fontSize:14)),
              )
            ,
                const Divider(color:Colors.grey,height:7,),
            ListTile(
              leading: Text('current ServerIP:$serverIP',style:const TextStyle(fontSize:14)),
            )
            ,
                       const Divider(color:Colors.grey,height:7,),
               ListTile(
              leading:const Text('Selected Date:',style: TextStyle(fontSize: 14)),
              title: Text('${currentDate.day}-${currentDate.month}-${currentDate.year}'),
          ),
            ListTile(
              leading:const Text('Select date for the data:',style: TextStyle(fontSize:14)),
              title:      ElevatedButton(
              onPressed:()=> pickDate(context),
               child: const Text('select date',style:TextStyle(fontSize:14,))) ,
            ),
                const Divider(color:Colors.grey,height:7,),
ListTile(
              leading:const Text('Clear Data:',style: TextStyle(fontSize: 14)),
              title: ElevatedButton(
                onPressed:()async{
                  print('Erasing data...');
                  await confirmDataErase(context);
                  print('Done...');
                },
                child:const Text('Reset'),
              ),
          ),
              const Divider(color:Colors.grey,height:7,),
          ListTile(
            title:  ElevatedButton(
            onPressed: ()async{
              await checkServer(context);
             await _submit(context,date);
               },
              style: ElevatedButton.styleFrom(
              backgroundColor:Colors.blue ,
              foregroundColor: Colors.white,
            ),
             child:const Text('Download'),
             ),
          ),
          ListTile(
            title:initImage(initialIndex: 0,)
          )
          ]   
            ), //here
      ],
    ),
  )
);

}
}





class initImage extends StatefulWidget{
 int initialIndex=0;

 initImage({super.key, required this.initialIndex});


  @override
State<initImage> createState()=>ImageProcessor();
}



// ignore: must_be_immutable
class ImageProcessor extends State<initImage>{
final GlobalKey Tkey=GlobalKey();
int cnt=0;
//ImageProcessor({Key?key}): super(key: key);  

@override
void initState(){
  super.initState();
  cnt=widget.initialIndex;
}


@override
void didUpdateWidget(initImage oldWidget){
  super.didUpdateWidget(oldWidget);
  if(widget.initialIndex!=oldWidget.initialIndex){
    cnt=widget.initialIndex;
   // incrementCnt();
    print(">>>>>>>>>>>>cnt:$cnt");
  }
}

Future<void> incrementCnt()async{
  if(grossCnt>=cnt){
  setState(() {
    AgentSignature=AgentSignatures[cnt].signature;
    print('>>>>>>>>>>>cnt:$cnt');
  });
  }
}

Future<void> configureCodes() async{
    print('creating user login image....');
final RenderRepaintBoundary boundary=Tkey.currentContext!.findRenderObject() as RenderRepaintBoundary;
final ui.Image image=await boundary.toImage( pixelRatio: 3.0);
final ByteData? byteData=await image.toByteData(format: ui.ImageByteFormat.png);
final Uint8List bytes=byteData!.buffer.asUint8List();

try{
final result=await ImageGallerySaver.saveImage(bytes,quality:80,name:AgentSignatures[cnt].name,);

  // ignore: avoid_print
  print('Running code configuration....$result');

if(result['isSuccess']){
  // ignore: avoid_print
  print('image has been successfully saved.....');
//changeImagequality('/storage/emulated/0/Pictures/1715089611977.jpg');
}
else{
  // ignore: avoid_print
  print('image save failed');
}
}
catch(e){
  print('Error captured:$e');
}
}

Future<void> createCode() async{
  try{
  var db=await openDatabase();
  var records=await store.find(db);
    grossCnt=records.length-1;

    print('>>>>>>>>>>>>>>>>>>grossCnt:$grossCnt');

if(grossCnt!=0){ 
var ptr=0;
while(grossCnt>=ptr){
  AgentSignatures.add(Agent32.fromJson(records[ptr].value));
  print('>>>>>>>>>>>>>>>Added:${records[ptr].value}');
await incrementCnt();
 await configureCodes();
  cnt++;
  ++ptr;
}


}
else{
  print('^^^^^^^^^^^^Database is empty...');
}
  }
catch(e){
  print('-------------createCode() Error:$e');
} 
}

Future<void> changeImagequality(imgPath)async{
print('changing image quality...');
File imgFile=File(imgPath);
img.Image image=img.decodeImage(imgFile.readAsBytesSync())!;
img.Image adjustedImage=img.copyResize(image,width:image.width,height: image.height);
File(imgPath).writeAsBytesSync(img.encodePng(adjustedImage));
print('Done...');
}

  @override
  Widget build(BuildContext context){
   // configureCodes()

    return  Column(
      children: <Widget>[
        RepaintBoundary(
            key:Tkey,
            child:QrImageView(
              data:AgentSignatures.isEmpty?AgentSignature:AgentSignatures[cnt].signature,
              version:QrVersions.auto,
              size:200.0,
              backgroundColor: Colors.white,
            ),),
              ElevatedButton(
                onPressed: ()async{
                  await     createCode();
                   //await      configureCodes();
                   }, 
                child: const Text('Generate codes'))
      ],);

}

}




