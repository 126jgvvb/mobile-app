class Agent32{
late  String name;
late String signature;
late String batch;
late String hadLunch;

Agent32(this.name,this.signature,this.batch,this.hadLunch);

Map<String,dynamic> tojson()=>{
"name":name,
"signature":signature,
"batch":batch,
"hadLunch":hadLunch,
};

factory Agent32.fromJson(Map<String,dynamic> json)=>Agent32(json["name"],json["signature"],json["batch"],json["hadLunch"]);
}