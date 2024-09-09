// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class newUser extends _newUser with RealmEntity, RealmObjectBase, RealmObject {
  newUser(
    String username,
    String password,
  ) {
    RealmObjectBase.set(this, 'username', username);
    RealmObjectBase.set(this, 'password', password);
  }

  newUser._();

  @override
  String get username =>
      RealmObjectBase.get<String>(this, 'username') as String;
  @override
  set username(String value) => RealmObjectBase.set(this, 'username', value);

  @override
  String get password =>
      RealmObjectBase.get<String>(this, 'password') as String;
  @override
  set password(String value) => RealmObjectBase.set(this, 'password', value);

  @override
  Stream<RealmObjectChanges<newUser>> get changes =>
      RealmObjectBase.getChanges<newUser>(this);

  @override
  Stream<RealmObjectChanges<newUser>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<newUser>(this, keyPaths);

  @override
  newUser freeze() => RealmObjectBase.freezeObject<newUser>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'username': username.toEJson(),
      'password': password.toEJson(),
    };
  }

  static EJsonValue _toEJson(newUser value) => value.toEJson();
  static newUser _fromEJson(EJsonValue ejson) {
    return switch (ejson) {
      {
        'username': EJsonValue username,
        'password': EJsonValue password,
      } =>
        newUser(
          fromEJson(username),
          fromEJson(password),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(newUser._);
    register(_toEJson, _fromEJson);
    return SchemaObject(ObjectType.realmObject, newUser, 'newUser', [
      SchemaProperty('username', RealmPropertyType.string),
      SchemaProperty('password', RealmPropertyType.string),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
