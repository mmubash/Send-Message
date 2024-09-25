import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';

import 'dbMessages.dart';
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
        .setTransports(['websocket'])
        .build());

    socket.connect();

    socket.onConnect((_) {

      socket.emit('getConversation', {
        'senderId': widget.senderId,
        'receiverId': widget.receiverId,
      });
      _getMessagesFunc();
    });
    socket.onConnectError((data) => print("Connection Error: $data"));
    socket.onDisconnect((_) => print("Disconnected"));
    _fetchPreviousMessages();
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

 void _getMessagesFunc(){
   socket.emit('getMessages', widget.conversationId.toString());
   print('Connected to the server');
   socket.on('getMessage', (data) async {
     print('##########');
     print('%%%%%%%%%%%%%%%%% %%%%%$data');
     MessageModel message = MessageModel(
       senderId: data['senderId'],
       receiverId: data['receiverId'],
       text: data['text'],
       conversationId: data['conversationId'],
       type: data['type'],
       status: data['status'],
       createdAt: DateTime.now().toIso8601String(),
       updatedAt: DateTime.now().toIso8601String(),
       iV: 0,
     );
     // Update the UI
     setState(() {
       _messages.add(message.toJson()); // Add the message to the list as JSON
     });
   });
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
        status: 'sent',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        iV: 0,
      );
      socket.emit('sendMessage', newMessage.toJson());
      setState(() {
        _messages.add(newMessage.toJson());
      });

      _controller.clear();
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildMessage(String text, bool isSentByUser, String senderId, String receiverId,String conversationId) {
    isSentByUser = senderId == widget.senderId;
    return Align(
      alignment: isSentByUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: isSentByUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: isSentByUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Text(
            //   username,
            //   style: TextStyle(
            //     fontWeight: FontWeight.bold,
            //     fontSize: 14,
            //     color: isSentByUser ? Colors.white : Colors.black87,
            //   ),
            // ),
            SizedBox(height: 5),
            Text(
              text,
              style: TextStyle(
                color: isSentByUser ? Colors.white : Colors.black87,
              ),
            ),
            // Text(
            //   timestamp,
            //   style: TextStyle(
            //     color: isSentByUser ? Colors.white : Colors.black87,
            //   ),
            // ),
            SizedBox(height: 5),
          ],
        ),
      ),
    );
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
                return _buildMessage(
                    message['text'],
                    // message['username'],
                    message['isSentByUser']??false,
                    message['senderId'],
                    message['receiverId'],
                    message['conversationId']
                  // message['timestamp'],
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
