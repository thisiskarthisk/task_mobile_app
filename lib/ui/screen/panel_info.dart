import 'package:flutter/material.dart';

class PanelInfoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("PanelInfoScreen")),
      body: Center(child: Text('Welcome to PanelInfo Screen!', style: TextStyle(fontSize: 24))),
    );
  }
}
