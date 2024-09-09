import 'package:hive/hive.dart';

@HiveType(typeId:0)
class User extends HiveObject{
  @HiveField(0) late String name;
  @HiveField(1) late String email;
  @HiveField(2) late String password;

  User(this.name,this.email,this.password);
}