import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController _unameController = TextEditingController();

  final TextEditingController _pswController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: const Text("登录"),
        ),
        body: Center(
          child: Column(
            children: [
              TextField(
                  controller: _unameController,
                  decoration: const InputDecoration(
                      labelText: "用户名", prefixIcon: Icon(Icons.person))),
              TextField(
                  controller: _pswController,
                  decoration: const InputDecoration(
                      labelText: "密码", prefixIcon: Icon(Icons.person))),
              Padding(
                  padding: const EdgeInsets.all(10),
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.login),
                    label: const Text("登录"),
                  ))
            ],
          ),
        ));
  }
}
