
import 'package:driveapp/drive.dart';
import 'package:flutter/material.dart';


class DriveScreen extends StatefulWidget {
  const DriveScreen({super.key});

  @override
  State<DriveScreen> createState() => _DriveScreenState();
}

class _DriveScreenState extends State<DriveScreen> {

  bool isLoading = false;

  void onTap() async {
    isLoading = true;
    setState(() {
    });
    final drive = DriveService();

   await drive.handleSignIn();
   isLoading = false;
   setState(() {
   });
  }

  void logout(){
    final drive = DriveService();

    drive.logout();
  }

  // void createFile(){
  //    final drive = DriveService();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Drive API Test'),
      ),

      body: Center(child: Column(
        children: [
          isLoading? const CircularProgressIndicator() : ElevatedButton(onPressed:onTap, child: const Text('Google Sign in')),
          ElevatedButton(onPressed:logout, child: const Text('Logout')),
          // ElevatedButton(onPressed:createFile, child: const Text('Create File')),
        ],
      )),
    );
  }
}