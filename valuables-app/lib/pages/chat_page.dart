import "package:flutter/material.dart";
import "package:get_it/get_it.dart";
import "package:valuables/auth/auth_service.dart";
import "package:valuables/chat/chat_service.dart";

class MyCustomForm extends StatefulWidget {
  const MyCustomForm({super.key});

  @override
  MyCustomFormState createState() {
    return MyCustomFormState();
  }
}

class MyCustomFormState extends State<MyCustomForm> {
  final authService = GetIt.I<AuthService>();
  final chatService = GetIt.I<ChatService>();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextFormField(controller: textController),
          TextButton(onPressed: () => print('a'), child: Text("Create")),
        ],
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      body: const Center(child: MyCustomForm()),
    );
  }
}
