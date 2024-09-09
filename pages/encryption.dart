// ignore_for_file: non_constant_identifier_names
import 'package:encrypt/encrypt.dart' ;
import 'package:flutter/material.dart' hide Key;
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/export.dart';

class EncryptData{
   var encryptionKey='''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAju8PyYD0RQ2OYQGeaMsg
KHAsi68ZbgKjukL++GE5ygHYic8fPPwQfW07DlxnHAaWgV/nLhkbjVFIIdLBdJSx
u9x7FbrvQRKMU9e/R+BJrATrtVw3DPKNbwNfZ/YpNMuNFLbB18gtOxK+Hgdz0HEG
+l3AFgt6DoCEgTXIFLihTlZUZPTZMCVZFquBXOouxMxpvq4PvecwqOoAm9WdAz1G
mfFwN9xpgZBMThWkH2Smizeo3S9PRuabzanfwjTX/vK6fYrSwZBiGo+74D9eFs2g
BBl7N4n7/1oiq8HGnsoVQJI2QjR74Xfpubb7aQWSwy4dq3eQTanp+lO01ya8egdI
zQIDAQAB
-----END PUBLIC KEY-----''';

late var iv;
late var output;
late var raw_data;


EncryptData(this.raw_data);

 Future<Map<String, dynamic>> encrypt() async {
  final len=encryptionKey.length;
print("================lenght:$len");

final publicKey=await parse_PublicKey(encryptionKey);
final encrypter=Encrypter(RSA(publicKey:publicKey,encoding: RSAEncoding.PKCS1));
final encrypted_data=encrypter.encrypt(this.raw_data);

final E_data=encrypted_data.base64;
print("================encrypted data: $E_data");


return this.output= {
  'encrypted_data':encrypted_data.base64
};

}

Map<String,dynamic> get_output(){
  return this.output;
}

}



Future<RSAPublicKey> parse_PublicKey(String key) async{
  final parser=RSAKeyParser();
  return parser.parse(key) as RSAPublicKey;
}





