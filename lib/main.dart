import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'package:servicedelivery/connectvity.dart';
import 'package:servicedelivery/constants.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:servicedelivery/splash/error.dart';
import 'splash/splash_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

Map _source = {ConnectivityResult.none: false};
MyConnectivity _connectivity = MyConnectivity.instance;
bool isconected = false;

class _MyHomePageState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _connectivity.initialise();
    _connectivity.myStream.listen((source) {
      setState(() => _source = source);
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_source.keys.toList()[0]) {
      case ConnectivityResult.none:
        setState(() {
          isconected = false;
        });

        // ignore: avoid_print

        break;
      case ConnectivityResult.mobile:
        setState(() {
          isconected = true;
        });
        // ignore: avoid_print

        break;
      case ConnectivityResult.wifi:
        setState(() {
          isconected = true;
        });

      // ignore: avoid_print

    }
    return isconected
        ? MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Flutter Auth',
            theme: ThemeData(
              primaryColor: kPrimaryColor,
              scaffoldBackgroundColor: Colors.white,
            ),
            home: const SplashScreen(),
            builder: EasyLoading.init(),
          )
        : buildUnAuthScreen();
  }

  buildUnAuthScreen() {
    return MaterialApp(
      title: 'Flutter Auth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kPrimaryColor,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ConnectionFaildScreen(),
    );
  }
}
