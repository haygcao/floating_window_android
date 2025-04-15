import 'package:flutter/material.dart';

class Detail extends StatelessWidget {
  static const String routeName = 'detail';
  final String name;
  final String value;

  const Detail({super.key, required this.name, required this.value});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Detail")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
