import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Social Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FacebookLogin fbLogin = new FacebookLogin();

  FacebookLoginStatus status;

  FacebookAccessToken fmToken;

  final JsonEncoder encoder = new JsonEncoder.withIndent('  ');

  String igDetails = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            RaisedButton(
              child: Text('Get Instagram Details'),
              onPressed: () async {
                getAccounts();
              },
            ),
            Text(igDetails),
          ],
        ),
      ),
    );
  }

  Future<bool> _loginIfNeeded() async {
    if (FacebookLoginStatus.loggedIn == status && fmToken != null) {
      return true;
    }

    try {
      var result = await fbLogin.logIn(['instagram_basic', 'pages_show_list']);
      if (mounted) {
        setState(() {
          status = result.status;
          fmToken = result.accessToken;
        });
      }

      return FacebookLoginStatus.loggedIn == status && fmToken != null;
    } catch (e) {
      print(e);
      return false;
    }
  }

  void getAccounts() async {
    StringBuffer sb = StringBuffer();

    try {
      bool loggedIn = await _loginIfNeeded();
      if (!loggedIn) {
        return;
      }

      String token = fmToken?.token;

      Response response = await Dio().get('https://graph.facebook.com/v7.0/me/accounts?access_token=$token');
      print(response.data);

      Map<String, dynamic> decodedGetAccountsResponse = json.decode(response?.data ?? '');

      sb.writeln("accounts:");
      sb.writeln(encoder.convert(decodedGetAccountsResponse));
      sb.writeln();

      if (decodedGetAccountsResponse.containsKey('data')) {
        List<dynamic> data = decodedGetAccountsResponse['data'];
        if (data.isNotEmpty) {
          for (Map<String, dynamic> singePageData in data) {
            if (singePageData.containsKey('id')) {
              String id = singePageData['id'];
              String name = singePageData['name'];
              String pageDetailsResponse = await getPageDetails(id);

              Map<String, dynamic> pageDetailsResponseDecoded = json.decode(pageDetailsResponse ?? '');

              sb.writeln("page details for $name:");
              sb.writeln(encoder.convert(pageDetailsResponse));
              sb.writeln();

              if (pageDetailsResponseDecoded.containsKey('instagram_business_account')) {
                String instagramBusinessAccount = pageDetailsResponseDecoded['instagram_business_account']['id'];
                String igMediaObjectsResponse = await getIgMediaObjects(instagramBusinessAccount);

                sb.writeln("instagram media objects for $instagramBusinessAccount:");
                sb.writeln(encoder.convert(json.decode(igMediaObjectsResponse ?? '')));
                sb.writeln();
              }
            }
          }
        }
      }
    } catch (e) {
      print(e);
      sb.write(e);
    }

    if (mounted) {
      setState(() => igDetails = sb.toString());
    }
  }

  Future<String> getPageDetails(String id) async {
    String result;

    try {
      bool loggedIn = await _loginIfNeeded();
      if (!loggedIn) {
        return null;
      }

      String token = fmToken?.token;

      Response response =
          await Dio().get('https://graph.facebook.com/v7.0/$id?fields=instagram_business_account&access_token=$token');
      print(response.data);
      result = response.data;
    } catch (e) {
      print(e);
    }

    return result;
  }

  Future<String> getIgMediaObjects(String igUserId) async {
    String result;

    try {
      bool loggedIn = await _loginIfNeeded();
      if (!loggedIn) {
        return null;
      }

      String token = fmToken?.token;

      Response response = await Dio().get('https://graph.facebook.com/v7.0/$igUserId/media?access_token=$token');
      print(response.data);
      result = response.data;
    } catch (e) {
      print(e);
    }

    return result;
  }
}
