//import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sembast/sembast_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spacemeals/pages/obj32.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';

// ignore: prefer_typing_uninitialized_variables
// ignore: prefer_typing_uninitialized_variables, non_constant_identifier_names
var defaultCnt=1;
  var database;
     bool stateFlag=false;
   // ignore: non_constant_identifier_names
  List<Agent32> AllAgents=List.empty(growable: true);
   String AgentsToDelete='';
   List<Agent32> PendingAgents=List.empty(growable: true);
   List<Agent32> DoneAgents=List.empty(growable: true);
   int totalCnt=0;
   var prefs2;

   StoreRef<String,dynamic> store=stringMapStoreFactory.store('my_store');



Future<Database> openDatabase() async{
final appDir=await getApplicationDocumentsDirectory();
      await appDir.create(recursive:true);
      store=stringMapStoreFactory.store('my_store');
      var dbPath=join(appDir.path,'spacemeals.db');

       database=await databaseFactoryIo.openDatabase(dbPath);
        return database;
}


Future<void> deleteAgents() async{
  print('Deleting agent...$AgentsToDelete');
  var db=await openDatabase();
  await store.record('record$AgentsToDelete').delete(db);

  var cnt=0;
  while(AllAgents.length>cnt){
  if(AllAgents[cnt].name!=AgentsToDelete) AllAgents[cnt]=AllAgents[cnt]; 
  ++cnt;
  }

cnt=0;

  while(DoneAgents.length>cnt){
  if(DoneAgents[cnt].name!=AgentsToDelete) DoneAgents[cnt]=DoneAgents[cnt]; 
    ++cnt;
  }

  cnt=0;

  while(PendingAgents.length>cnt){
  if(PendingAgents[cnt].name!=AgentsToDelete) PendingAgents[cnt]=PendingAgents[cnt]; 
    ++cnt;
  }

  print('done...');
}

void closeDataBase() async{
  await database.close();
}

// ignore: must_be_immutable
class ListPage extends StatefulWidget{
SharedPreferences prefs;
int ListCnt=AllAgents.length;
  ListPage({required this.prefs,required this.ListCnt,super.key});


  @override
  State<ListPage> createState()=>_initList(prefs);
}



// ignore: camel_case_types
class _initList extends State<ListPage> with SingleTickerProviderStateMixin{
late TabController _tabcontroller;
SharedPreferences prefs;
int tcnt=totalCnt;

  _initList(this.prefs);
  //AllAgents.length

     Future<void> LoadDBdataIntoMemory() async{
    print('>>>>>>>>>>>>>>>>>>>sorting data...');
 
     var storage=await openDatabase();
        var Agent=await store.find(storage);
      var AgentCnt=Agent.length-1;
      var cnt=0;

        // ignore: avoid_print
        while(AgentCnt>=cnt){
     try{
      if(cnt==0){
          if(prefs.getBool('stateFlag')==true){
            DoneAgents=[];
            PendingAgents=[];
          }
      }

          final obj=Agent32.fromJson(Agent[cnt].value);
      if(obj.hadLunch=='yes'){
        DoneAgents.add(obj);
   }
   else{
      PendingAgents.add(obj);
   }
   }
   catch(e){
    print("loading error: $e");
   }
   cnt++;
   }

       prefs.setBool('stateFlag', true);
   }

@override
void initState(){
  super.initState();
  prefs2=prefs;
  LoadDBdataIntoMemory();
  _tabcontroller=TabController(length: 3, vsync: this);
}

@override
void didUpdateWidget(ListPage oldWidget){
  super.didUpdateWidget(oldWidget);
  if(widget.ListCnt!=oldWidget.ListCnt){
    tcnt=widget.ListCnt;
    print(">>>>>>>>>>>>cnt:$tcnt");
  }
}


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor:Colors.brown ,
        toolbarTextStyle: const TextStyle(color:Colors.white),
        leading: GestureDetector(
          onTap: (){Navigator.pop(context);},
          child:const Icon(Icons.arrow_back,color: Colors.white,),
        ),
        title: const Text('Analysis',style:TextStyle(color: Colors.white),),
        bottom: TabBar(
          labelStyle:const TextStyle(color: Colors.white),
        //  indicatorColor: Colors.yellow,
          controller: _tabcontroller,
          tabs:const [
           Tab(text: 'All'),
           Tab(text: 'Done'),
            Tab(text:'Pendng')
          ]
        ),
        actions:<Widget> [
          GestureDetector(
            onTap: (){
               //   startDatabase();
            },
             child: const Icon(Icons.refresh,color: Colors.white,)),
        ],
      ),
      body: TabBarView(
        controller: _tabcontroller,
        children: [
          FutureBuilder(
            future: openDatabase(),
             builder: (BuildContext context,AsyncSnapshot<Database> snapshot){
              if(snapshot.connectionState==ConnectionState.waiting){
                return 
                const Center(child:Row( children:<Widget>[
                  Text(''),
                         SizedBox(width:150,),
  CircularProgressIndicator.adaptive(),
        ]));
              }
              else if(snapshot.hasError){
                return Text('Error: ${snapshot.error}');
              }
              else{
             //   final store=intMapStoreFactory.store('my_store');
                return FutureBuilder(
                  future: store.find(snapshot.data as DatabaseClient),
                   builder: (context,AsyncSnapshot<List<RecordSnapshot>> snapshot){
                          if(snapshot.connectionState==ConnectionState.waiting){
                            return const Center(
                             child: SizedBox(
                                 width: 0.2,
                              height: 0.2,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                              ),
                            ));
                          }
                          else if(snapshot.hasError){
                              return Center(
                                child: Text('Error:${snapshot.error}'),
                              );
                          }
                          else{
                            print('-------------poster:${snapshot.data}');
                          final  customObjs=snapshot.data
                            ?.map((record){
                         print("Retrieved:${jsonEncode(record.value)}");
                       try{
                       /*   if( Agent32.fromJson(jsonDecode(jsonEncode(record.value))).hadLunch=='yes' && prefs.getBool('stateFlag')==false){
                                          print('Done Agents identified...');
                                         DoneAgents.add( Agent32.fromJson(jsonDecode(jsonEncode(record.value))));
                          }
                           if( Agent32.fromJson(jsonDecode(jsonEncode(record.value))).hadLunch=='No' && prefs.getBool('stateFlag')==false){
                               print('Pending Agents identified...');
                               PendingAgents.add( Agent32.fromJson(jsonDecode(jsonEncode(record.value))));
                          }*/

                            return  Agent32.fromJson(jsonDecode(jsonEncode(record.value)));
                       }
                       catch(e){print('Error:$e');}
                            }
                            ).toList();

                            totalCnt=customObjs!.length;
                        

                            return  ListView.builder(
                                itemCount:totalCnt,
                                 itemBuilder: (BuildContext context,int index){
                                final item=customObjs[index];
                                   AllAgents.add(item!);
                                     const Divider(color:Colors.grey,height:12,);
                             return ListTile(
                            tileColor:  Color.fromARGB(255, 95, 64, 53),
                            textColor: Colors.white,
                           hoverColor:const Color.fromARGB(255, 22, 140, 199) ,
                           selectedColor: Colors.green,
                           focusColor: Colors.blue,
                           title: Text(item.name),
                           subtitle: Text('batch:${item.batch}'),
                              trailing:PopupMenuButton(
                            itemBuilder:(BuildContext context){
                              return <PopupMenuEntry>[
                                  PopupMenuItem(
                                    value:item.name,
                                    child:const SizedBox(child:Text('delete',),)
                           ),
                              ];
                            },
                            onSelected: (value){
                              print('<<<<<<<<<<<<<<<<<$value');
                            AgentsToDelete=value;
                            AllAgents.remove(value);
                            DoneAgents.remove(value);
                            PendingAgents.remove(value);
                            deleteAgents();
                            //  switch(value){case 'delete':}
                            },
                            ),
                    );
                  }
                  );
                          }
                          
                   });
              
              }
             }),
           
          DoneAgents.isNotEmpty?  ListView.builder(
                                itemCount: DoneAgents.length,
                                 itemBuilder: (BuildContext context,int index){
                                final item=DoneAgents[index];
                             return ListTile(
                            tileColor:  Color.fromARGB(255, 95, 64, 53),
                            textColor: Colors.white,
                           hoverColor:const Color.fromARGB(255, 22, 140, 199) ,
                           selectedColor: Colors.green,
                           focusColor: Colors.blue,
                           title: Text(item.name),
                           subtitle: Text('batch:${item.batch}'),
                    );
                  }):const Center(
                    child: Text('Not Available'),
                  ) ,
            PendingAgents.isNotEmpty?  ListView.builder(
                                itemCount: PendingAgents.length,
                                 itemBuilder: (BuildContext context,int index){
                                final item=PendingAgents[index];
                             return ListTile(
                            tileColor:   Color.fromARGB(255, 95, 64, 53),
                            textColor: Colors.white,
                           hoverColor:const Color.fromARGB(255, 22, 140, 199) ,
                           selectedColor: Colors.green,
                           focusColor: Colors.blue,
                           title: Text(item.name),
                           subtitle: Text('batch:${item.batch}'),
                    );
                  }):const Center(
                    child: Text('Not Available'),
                  )
         
        ]),
    );
  }


@override
void dispose(){
  _tabcontroller.dispose();
  super.dispose();
}

}




















