import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:typed_data' as typed;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'message.dart';

class ChatScreen extends StatefulWidget {
  final String username;
  final String senderId;
  final String receiverId;
  final String conversationId;
  ChatScreen({
    Key? key,
    required this.username,
    required this.senderId,
    required this.receiverId,
    required this.conversationId,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  late IO.Socket socket;
  String? base64String;
  String? fileLink;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    socket = IO.io('ws://192.168.2.189:3001', IO.OptionBuilder()
        .setTransports(['websocket'])
        .build());
    socket.connect();
     socket.onConnect((_) {
       print('Socket connected');
       socket.emit('getConversation', {
         'senderId': widget.senderId,
         'receiverId': widget.receiverId,
       });

     });

    _setupSocketListeners();
    _fetchPreviousMessages();
  }

  void _setupSocketListeners() {
    socket.on('newMessage', (data) {
        print("This is Data of new messaage${data}");
          if(widget.conversationId==data["_doc"]['conversationId']) {
            if (mounted) {
              setState(() {
                print("is this running");
                _messages.add(data['_doc']);
              });
            }
          }

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
        if (mounted) {
          setState(() {
            _messages.addAll(messagesAsMaps);
          });
        }
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (error) {
      print('Error fetching messages: $error');
    }
  }
  Future<String?> pickFileAndConvertToBase64() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: false);

    if (result != null && result.files.isNotEmpty) {
      File file = File(result.files.single.path!);
      List<int> fileBytes = await file.readAsBytes();
      String base64String = base64Encode(fileBytes);
      String? mimeType = lookupMimeType(file.path);
      String dataUrl = 'data:$mimeType;base64,$base64String';
      // fileLink=dataUrl;
      try {

        http.Response response = await http.post(
          Uri.parse("http://192.168.2.189:3001/api/message/send-image"),

          body: {
            "file": dataUrl,
          },
        );

        if (response.statusCode == 200) {
          print(response.body);
          var data = jsonDecode(response.body);
          String imagePath = data['path'];
          if (mimeType != null) {
            String typedoc = dataUrl.split('/').first;
            print("Data URL: $dataUrl");
            MessageModel newMessage = MessageModel(
              senderId: widget.senderId,
              receiverId: widget.receiverId,
              text: '/$imagePath',
              conversationId: widget.conversationId,
              type: typedoc.split(':').last,
            );

            socket.emit('sendMessage', newMessage.toJson());
            return dataUrl;
          } else {
            print("Could not determine MIME type");
            return null;
          }
        } else {
          print('File not uploaded: Status Code ${response.statusCode}');
          print('Response: ${response.body}');
          return null;
        }
      } catch (e) {
        print("This is Error: ${e.toString()}");
        return null;
      }
    } else {
      print('No file selected');
      return null;
    }
  }
  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      String message = _controller.text;
      if (fileLink==null) {
        MessageModel newMessage = MessageModel(
        senderId: widget.senderId,
        receiverId: widget.receiverId,
        text: message,
        conversationId:widget.conversationId,
        type: 'text',
      );
        socket.emit('sendMessage', newMessage.toJson());
      }
      _controller.clear();
    }
  }


  Future<VideoPlayerController> _initializeVideoPlayer(String videoUrl) async {
    Uri uri = Uri.parse(videoUrl);
    VideoPlayerController controller = VideoPlayerController.networkUrl(uri);
    await controller.initialize();
    return controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    _videoController?.dispose();
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
                bool isSender = message['senderId'] == widget.senderId;
               if(message['type']=='image'){
                 // String base64String = message['text'].split(',').last;
                 // typed.Uint8List _bytesImage = Base64Decoder().convert(base64String);
                 return Align(
                   alignment: isSender
                       ? Alignment.centerRight
                       : Alignment.centerLeft,
                   child: Container(
                     padding:
                     EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                     margin:
                     EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                     decoration: BoxDecoration(
                       color: isSender ? Colors.blueAccent : Colors.grey[300],
                       borderRadius: BorderRadius.circular(15),
                     ),
                     // child: Image.memory(
                     //   _bytesImage,
                     //   width: 150,
                     //   height: 150,
                     //   fit: BoxFit.cover,
                     // ),
                     child: Image.network('http://192.168.2.189:3001${message['text']}')
                   ),
                 );
               }
               else if (message['type'] == 'video') {
                 String videoUrl = message['text'];
                 return Align(
                   alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                   child: Container(
                     padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                     margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                     decoration: BoxDecoration(
                       color: isSender ? Colors.blueAccent : Colors.grey[300],
                       borderRadius: BorderRadius.circular(15),
                     ),
                     child: FutureBuilder<VideoPlayerController>(
                       future: _initializeVideoPlayer(videoUrl),
                       builder: (context, snapshot) {
                         if (snapshot.connectionState == ConnectionState.done) {
                           final controller = snapshot.data!;
                           return AspectRatio(
                             aspectRatio: controller.value.aspectRatio,
                             child: VideoPlayer(controller),
                           );
                         } else {
                           return Center(child: CircularProgressIndicator());
                         }
                       },
                     ),
                   ),
                 );
               }
               else{
                 return Align(
                   alignment: isSender
                       ? Alignment.centerRight
                       : Alignment.centerLeft,
                   child: Container(
                     padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                     margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                     decoration: BoxDecoration(
                       color: isSender ? Colors.blueAccent : Colors.grey[300],
                       borderRadius: BorderRadius.circular(15),
                     ),
                     child: Padding(
                       padding: const EdgeInsets.all(8.0),
                       child: Column(
                         children: [
                           Text(
                             message['text'],
                             style: TextStyle(
                               color: isSender ? Colors.white : Colors.black87,
                             ),
                           ),

                         ],
                       ),
                     ),
                   ),
                 );
               }

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
                IconButton(
                    onPressed:pickFileAndConvertToBase64 ,
                    icon: Icon(Icons.attachment)
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
