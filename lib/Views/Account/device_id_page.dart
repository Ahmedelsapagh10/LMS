import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../Config/app_config.dart';

class CopyDeviceIDPage extends StatefulWidget {
  CopyDeviceIDPage({
    super.key,
    required this.token,
  });
  final String token;
  @override
  _CopyDeviceIDPageState createState() => _CopyDeviceIDPageState();
}

class _CopyDeviceIDPageState extends State<CopyDeviceIDPage> {
  String? _currentDeviceId;

  @override
  void initState() {
    super.initState();
    _getCurrentDeviceId();
  }

  Future<void> _getCurrentDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceId;

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id; // Unique ID on Android
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ??
          Random(5).toString(); // Unique ID on iOS
    } else {
      deviceId = "unknown";
    }
    setState(() {
      _currentDeviceId = deviceId;
    });
  }

  void _copyDeviceID() {
    if (_currentDeviceId != null) {
      Clipboard.setData(
          ClipboardData(text: _currentDeviceId ?? "No Device ID found"));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Device ID copied to clipboard')),
      );
    }
  }

  @override
  void dispose() {
    logout();
    super.dispose();
  }

  Future<void> logout() async {
    try {
      Uri logoutUrl = Uri.parse(baseUrl + '/logout');

      await http.get(logoutUrl, headers: header(token: widget.token));
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Device ID',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _currentDeviceId == null
            ? Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'images/device_id_image.webp',
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 30),
                  Text(
                    "Your current Device ID is displayed below. Please copy it and send it to the admin for updating.",
                    style: TextStyle(fontSize: 18, color: Colors.grey[800]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  Text(
                    _currentDeviceId ?? 'Loading...',
                    style: TextStyle(
                        fontSize: 24,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Icon(
                      Icons.copy,
                      color: Colors.white,
                    ),
                    label: Text(
                      "Copy Device ID",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    onPressed: _copyDeviceID,
                  ),
                ],
              ),
      ),
    );
  }
}
