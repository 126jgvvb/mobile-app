import 'package:hive/hive.dart';

class AgentObject{
late  String name;
late String signature;
late String batch;
late String hadLunch;

AgentObject(this.name,this.signature,this.batch,this.hadLunch);
}

@HiveType(typeId:0)
class AgentHive extends HiveObject{
  @HiveField(0)
 // ignore: non_constant_identifier_names
 late List<AgentObject> Agents;

AgentHive(this.Agents);
}


class AgentAdapter extends TypeAdapter<AgentHive>{
@override
final int typeId=0;

@override
AgentHive read(BinaryReader reader){
  return AgentHive(reader.readList().cast<AgentObject>());
}

@override
void write(BinaryWriter writer,AgentHive obj){
  writer.writeList(obj.Agents);
}

}



