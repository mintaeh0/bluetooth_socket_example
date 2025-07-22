import 'package:bluetooth_socket_example/bluetooth_view.dart';
import 'package:bluetooth_socket_example/bluetooth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.from(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: ChangeNotifierProvider(
        create: (context) => BluetoothViewModel(),
        builder: (context, child) {
          return BluetoothView();
        },
      ),
    );
  }
}
