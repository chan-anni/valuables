import "package:flutter/material.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:valuables/auth/auth_service.dart";

class MyCustomForm extends StatefulWidget {
  const MyCustomForm({super.key});

  @override
  MyCustomFormState createState() {
    return MyCustomFormState();
  }
}

class MyCustomFormState extends State<MyCustomForm> {
  final authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController textController = TextEditingController();

  Future<Map<String, dynamic>?> createRoom() async {
    try {
      // Access the text from the controller
      final String roomName = textController.text.trim();

      if (roomName.isEmpty) return null;

      final data = await Supabase.instance.client
          .from('chat_room')
          .insert({
            'name': roomName, // Using the variable from controller
            'is_public': false,
          })
          .select('id')
          .single();

      await Supabase.instance.client.from("chat_room_member").insert({
        "chat_room_id": data['id'],
        "member_id": authService.getCurrentUserSession()?.user.id,
      });

      debugPrint("Room created with ID: ${data['id']}");
      return data;
    } catch (e) {
      debugPrint("Error creating room: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextFormField(controller: textController),
          TextButton(onPressed: createRoom, child: Text("Create")),
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
