import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haishin_kit/audio_settings.dart';
import 'package:haishin_kit/audio_source.dart';
import 'package:haishin_kit/net_stream_drawable_texture.dart';
import 'package:haishin_kit/rtmp_connection.dart';
import 'package:haishin_kit/rtmp_stream.dart';
import 'package:haishin_kit/video_settings.dart';
import 'package:haishin_kit/video_source.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:intl/intl.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  RtmpConnection? _connection;
  RtmpStream? _stream;
  bool _recording = false;
  CameraPosition currentPosition = CameraPosition.back;
  List<Message> messages = [];
  final messageController = TextEditingController();
  double messageBarOffset = 0;
  ScrollController scrollController = ScrollController();
  late FocusNode _messageFocusNode;
  IO.Socket socket = IO.io('http://145.49.48.248:3000', <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false,
    //Send jwt token with socket in authorization header
    'extraHeaders': {'Authorization': 'Bearer ' + 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6InRlc3RAdGVzdEB0ZXN0LmNvbSIsInN1YiI6MSwic3RyZWFtIjpmYWxzZSwiaWF0IjoxNjg2NzQxMTMyLCJleHAiOjE2ODczNDU5MzJ9.06qHaTaSoW58OJoGWaWYigDl0PZAJ6MaC1HnYcz_lFs'}
  });
  @override
  void initState() {

    socket.emit('chat', {"streamerID": 'test', "userID": 1}); // put stream id here
    socket.connect();
    socket.on('test', (data) { //Place logged in user here
      print(data);
      setState(() {
        messages.add(Message(data['message'], data['fullName'], data['datetime']));
      });

      // Scroll to the bottom of the ListView
      scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
    _messageFocusNode = FocusNode();
    super.initState();
    initPlatformState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    _stream?.dispose();
    _connection?.dispose();
    SystemChrome.setPreferredOrientations(SystemChrome.restoreSystemUIOverlays as List<DeviceOrientation>);
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> initPlatformState() async {
    await Permission.camera.request();
    await Permission.microphone.request();

    // Set up socket.io client
    // ...

    // Create RTMP connection
    RtmpConnection connection = await RtmpConnection.create();
    connection.eventChannel.receiveBroadcastStream().listen((event) {
      switch (event["data"]["code"]) {
        case 'NetConnection.Connect.Success':
          _stream?.publish("live"); // Publish stream id
          setState(() {
            _recording = true;
          });
          break;
      }
    });

    // Create RTMP stream and configure audio/video settings
    RtmpStream stream = await RtmpStream.create(connection);
    stream.audioSettings = AudioSettings(muted: false, bitrate: 64 * 1000);
    stream.videoSettings = VideoSettings(
      width: 1080,
      height: 1920,
      bitrate: 6000 * 1000,
    );
    stream.attachAudio(AudioSource());
    stream.attachVideo(VideoSource(position: currentPosition));

    if (!mounted) return;

    setState(() {
      _connection = connection;
      _stream = stream;
    });
  }

  void switchCamera() {
    if (currentPosition == CameraPosition.front) {
      currentPosition = CameraPosition.back;
    } else {
      currentPosition = CameraPosition.front;
    }
    _stream?.attachVideo(VideoSource(position: currentPosition));
  }

  void sendMessage() {
    final message = messageController.text;
    if (message.isNotEmpty) {
      // Send the message to the chat server
      // ...

      setState(() {
        //send message to socket
        _messageFocusNode.requestFocus();
        socket.emit('test', {"message": message, "fullName": "Flutter"}); // put stream id here
      });

      // Scroll to the bottom of the ListView
      scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

      messageController.clear();
    }
  }

  void handleKeyboardVisibility(bool visible, double keyboardHeight) {
    setState(() {
      messageBarOffset = visible ? -keyboardHeight : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFFE4237),
    ));

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (BuildContext context) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: const Text(
                'SeeChange',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              backgroundColor: const Color(0xFFFE4237),
            ),
            body: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return Stack(
                  children: [
                    // Playback Widget
                    Center(
                      child: _stream == null
                          ? const Text("Error")
                          : AspectRatio(
                        aspectRatio: 9 / 16,
                        child: NetStreamDrawableTexture(_stream!),
                      ),
                    ),
                    // SlidingUpPanel
                    SlidingUpPanel(
                      minHeight: 90,
                      maxHeight: constraints.maxHeight - 200 - messageBarOffset,
                      parallaxEnabled: true,
                      backdropEnabled: true,
                      color: Colors.transparent,
                      panel: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24.0),
                            topRight: Radius.circular(24.0),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const BarIndicator(),
                            Expanded(
                              child: ListView.builder(
                                controller: scrollController,
                                reverse: true,
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final reversedIndex = messages.length - 1 - index; // Reverse the index
                                  final message = messages[reversedIndex];
                                  return ListTile(
                                    title: Text(
                                      message.fullName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFE4237),
                                      ),
                                    ),
                                    subtitle: Text(
                                      message.message,
                                      style: const TextStyle(fontSize: 16, color: Colors.black),
                                    ),
                                    trailing: Text(
                                      message.dateTime,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: messageController,
                                  focusNode: _messageFocusNode, // Assign the FocusNode
                                  decoration: const InputDecoration(
                                    hintText: 'Type a message...',
                                  ),
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => sendMessage(),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              IconButton(
                                onPressed: sendMessage,
                                icon: const Icon(Icons.send),
                                color: const Color(0xFFFE4237),
                              ),
                            ],
                          ),
                        )
                          ],
                        ),
                      ),
                      collapsed: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(26.0),
                            topRight: Radius.circular(26.0),
                          ),
                        ),
                        child: const Column(
                          children: [
                            BarIndicator(),
                            Center(
                              child: Text(
                                "Swipe up to open chat",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                      onPanelSlide: (double position) {},
                      onPanelOpened: () => handleKeyboardVisibility(true, MediaQuery.of(context).viewInsets.bottom),
                      onPanelClosed: () => handleKeyboardVisibility(false, 0),
                    ),
                  ],
                );
              },
            ),
            floatingActionButton: Padding(
              padding: const EdgeInsets.only(bottom: 40), // Add bottom padding here
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    heroTag: "record",
                    backgroundColor: const Color(0xFFFE4237),
                    child: _recording ? const Icon(Icons.fiber_smart_record) : const Icon(Icons.not_started),
                    onPressed: () {
                      if (_recording) {
                        _connection?.close();
                        setState(() {
                          _recording = false;
                        });
                      } else {
                        _connection?.connect("rtmp://145.49.8.147:1935/live/");
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton(
                    heroTag: "switchCamera",
                    backgroundColor: const Color(0xFFFE4237),
                    onPressed: switchCamera,
                    child: const Icon(Icons.flip_camera_android),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class BarIndicator extends StatelessWidget {
  const BarIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 5.0,
      width: 40.0,
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10.0),
      ),
    );
  }
}

class Message {
  final String message;
  final String fullName;
  final String dateTime;

  Message(this.message, this.fullName, String dateTime)
      : dateTime = DateFormat('MMMM dd HH:mm').format(DateTime.parse(dateTime));
}