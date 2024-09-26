import 'dart:convert';

import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'message.dart';

class ChatScreen extends StatefulWidget {
  final String username;
  final String senderId;
  final String receiverId;
  final String conversationId;

  ChatScreen({Key? key, required this.username, required this.senderId, required this.receiverId,required this.conversationId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    socket = IO.io('ws://192.168.2.189:3001', IO.OptionBuilder()
        .setTransports(['websocket']).enableAutoConnect()
        .build());
    socket.onConnect((_) {
      socket.emit('getConversation', {
        'senderId': widget.senderId,
        'receiverId': widget.receiverId,
      });
    });

    _events();
    _fetchPreviousMessages();
  }
  void _events(){

    socket.on('newMessage', (data) {
      print("********uytjky********${data['_doc']}*********************");
      setState(() {
        _messages.add(data['_doc']);
      });
    });
    socket.onConnectError((data) => print("Connection Error: $data"));
    socket.onDisconnect((_) => print("Disconnected"));
  }
  Future<void> _fetchPreviousMessages() async {
    try {
      final response = await http.get(Uri.parse(
          'http://192.168.2.189:3001/api/message/get/${widget.conversationId}'));
      if (response.statusCode == 200) {
        List<dynamic> messageJson = jsonDecode(response.body);
        List<MessageModel> messages = messageJson
            .map((json) => MessageModel.fromJson(json))
            .toList();
        List<Map<String, dynamic>> messagesAsMaps = messages.map((message) => message.toJson()).toList();
        setState(() {
          _messages.addAll(messagesAsMaps);
        });
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (error) {
      print('Error fetching messages: $error');
    }
  }


  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      String message = _controller.text;
      MessageModel newMessage = MessageModel(
        senderId: widget.senderId,
        receiverId: widget.receiverId,
        text: message,
        conversationId: widget.conversationId,
        type: 'text',
      );
      socket.emit('sendMessage', newMessage.toJson());


      _controller.clear();
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with ${widget.username}"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return ListTile(
                    title: Text(message['text']),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}