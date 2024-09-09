import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class settings extends StatefulWidget{
  SharedPreferences prefs;

  settings(this.prefs, {super.key});

  @override
  State<settings> createState()=>_initSettings(prefs);
}


class _initSettings extends State<settings>{
var _autoBackup;
var servState=false;
var currentTime;
SharedPreferences prefs;

_initSettings(this.prefs);

Future<void> _selectTime() async{
 final TimeOfDay? picked=await showTimePicker(context: context, initialTime: currentTime);

if(picked!=null){
  setState(() async{
    currentTime=picked as String;
   TimeOfDay deck=currentTime as TimeOfDay;
    prefs.setString('schedule_time',jsonEncode({'hour':deck.hour as String,'minute':deck.minute as String}));
  });
}
}


Future<void> initIdentifiers() async{
  setState(() async{
    _autoBackup=prefs.getBool('autoBackup') ?? false;
    currentTime=(prefs.getString('schedule_time')!=null)?prefs.getString('schedule_time'):TimeOfDay.now();
  });

}

Future<dynamic> getSavedTime() async{
  var obj=prefs.getString('schedule_time');
  var jsonObj=jsonDecode(jsonEncode(obj));
  print('>>>>>>>>>>>>>>>>>>>>Time:${jsonEncode(jsonObj)}');
return jsonObj;
//return '${jsonObj.hour}:${jsonObj.minute}';
}

@override
void initState(){
  super.initState();
    initIdentifiers();
}


  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: AppBar(
        backgroundColor:Colors.brown ,
        leading: GestureDetector(
          onTap: (){
            Navigator.pop(context);
          },
          child:const Icon(Icons.arrow_back,color: Colors.white,),
        ),
        title:const Text('settings',style: TextStyle(color: Colors.white),),
      ),
      body: Center(
       child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Text('Automatic backup'),
                  const SizedBox(width:170),
                  Switch(
                    value: _autoBackup,
                     onChanged: (value){
                        setState(() async{
                          _autoBackup=value;
                        await  prefs.setBool('autoBackup',_autoBackup);
                        });
                     })
                ],
              ),
                Row(
                  children: <Widget>[
                   const Text('Select the Scheduled time'),
                    const SizedBox(width:60),
                    ElevatedButton(
                      onPressed: _selectTime, 
                      child:const Text('setTime'))
                  ],
                ),
                const SizedBox(height:20),
                 const Row(
                  children:<Widget> [
   //              Text('Selected Time:${prefs.getBool('autoBackup')!=null?getSavedTime():({currentTime.hour})}',style: TextStyle(fontSize: 12,))
                  ],),

              const SizedBox(height:20),
            ],
        )
      ),
    );
  }
}




