import 'dart:async';
import 'package:audio_session/audio_session.dart';
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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  RtmpConnection? _connection;
  RtmpStream? _stream;
  bool _recording = false;
  CameraPosition currentPosition = CameraPosition.back;

  @override
  void initState() {
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
    super.dispose();
  }

  Future<void> initPlatformState() async {
    await Permission.camera.request();
    await Permission.microphone.request();

    // Set up AVAudioSession for iOS
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth,
    ));

    // Create RTMP connection
    RtmpConnection connection = await RtmpConnection.create();
    connection.eventChannel.receiveBroadcastStream().listen((event) {
      switch (event["data"]["code"]) {
        case 'NetConnection.Connect.Success':
          _stream?.publish("stream"); // Publish stream id
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
      bitrate: 512 * 1000,
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFFE4237),
    ));

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
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
        body: Stack(
          children: [
            // Playback Widget
            Center(
              child: _stream == null
                  ? const Text("Error")
                  : AspectRatio(
                aspectRatio: 9 / 16,
                child: NetStreamDrawableTexture(_stream),
              ),
            ),
            // SlidingUpPanel
            SlidingUpPanel(
              minHeight: 70,
              maxHeight: 550,
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
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BarIndicator(),
                    Center(
                      child: Text(
                        "Chat",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
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
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FloatingActionButton(
              backgroundColor: const Color(0xFFFE4237),
              child: _recording ? const Icon(Icons.fiber_smart_record) : const Icon(Icons.not_started),
              onPressed: () {
                if (_recording) {
                  _connection?.close();
                  setState(() {
                    _recording = false;
                  });
                } else {
                  _connection?.connect("rtmp://145.49.31.151:1935/live/");
                }
              },
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              backgroundColor: const Color(0xFFFE4237),
              onPressed: switchCamera,
              child: const Icon(Icons.flip_camera_android),
            ),
          ],
        ),
      ),
    );
  }
}

class BarIndicator extends StatelessWidget {
  const BarIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: 40,
        height: 3,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
  }
}
