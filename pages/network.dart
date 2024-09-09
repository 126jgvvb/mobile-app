import 'package:realm/realm.dart';

part 'network.realm.dart';

@RealmModel()
class _newUser{
  late String username;
  late String password;
}

class _login{
   late String username;
  late String password;
}


class _BackupData{
  late String data;
}

