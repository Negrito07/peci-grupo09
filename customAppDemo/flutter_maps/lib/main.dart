import 'package:flutter/material.dart';
import 'package:flutter_map_test/pages/SitesList.dart';
import 'pages/login.dart';
import 'pages/map.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map_test/DataOperations.dart' as operation;
import 'dart:io';

void main() {
  // configurar barra de status do dispositivo para transparente
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  //operation.auxiliar([]).whenComplete(() => print("acabou"));
   HttpOverrides.global = MyHttpOverrides();
  // inicializar aplicacao
  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => const Login(),
    },
    debugShowCheckedModeBanner: false,
  ));
}
class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}