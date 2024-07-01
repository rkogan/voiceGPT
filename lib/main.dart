import 'dart:convert';

import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speech Recognition App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static final _speech = SpeechToText();
  static final FlutterTts _flutterTts = FlutterTts();
  static final Uri _uri = Uri.parse("https://api.openai.com/v1/completions");
  static const String _apiKey = "ADD_OPENAI_API_KEY_HERE";

  String _spokenText = 'Click button to start recording';
  String _response = '';
  bool _isListening = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.teal,
          centerTitle: true,
          title: const Text(
            'AI Assistant',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              onPressed: () async {
                await FlutterClipboard.copy(_spokenText);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Text Copied to Clipboard')),
                );
              },
              icon: const Icon(
                Icons.copy,
                color: Colors.white,
              ),
            ),
          ],
        ),
        floatingActionButton: AvatarGlow(
          endRadius: 80,
          animate: _isListening,
          glowColor: Colors.teal,
          child: FloatingActionButton(
            onPressed: toggleRecording,
            child: Icon(
              _isListening ? Icons.circle : Icons.mic,
              size: 35,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: SingleChildScrollView(
            reverse: true,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(30.0).copyWith(bottom: 40),
                child: Text(
                  _spokenText.trim(),
                  style: const TextStyle(
                    color: Colors.teal,
                    fontSize: 30,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(30.0).copyWith(bottom: 140),
                child: Text(
                  _response.trim(),
                  style: const TextStyle(
                    color: Colors.teal,
                    fontSize: 20,
                  ),
                ),
              ),
            ])));
  }

  Future<bool> toggleRecording() async {
    final isAvailable = await _speech.initialize(onStatus: (status) async {
      if (_isListening && !_speech.isListening) {
        Future.delayed(const Duration(milliseconds: 500), () async {
          var response = await http.post(_uri,
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $_apiKey"
              },
              body: jsonEncode({
                "prompt":
                    "I am a highly intelligent question answering bot.\n\nQ: $_spokenText\nA: ",
                "max_tokens": 256,
                "temperature": 0.7,
                "model": "gpt-3.5-turbo-instruct",
                "frequency_penalty": 0,
                "presence_penalty": 0,
                "best_of": 1,
                "top_p": 1,
                "n": 1,
                "stream": false,
                "logprobs": null,
              }));

          setState(() {
            _response = jsonDecode(response.body)["choices"][0]["text"];
          });
          _flutterTts.speak(_response.replaceAll("\n", ", "));
        });
      }
      setState(() {
        _isListening = _speech.isListening;
      });
    });
    if (_speech.isListening) {
      _speech.stop();
      return true;
    }
    if (isAvailable) {
      _speech.listen(onResult: (value) {
        setState(() {
          _spokenText = value.recognizedWords;
          _response = 'Loading...';
        });
      });
    }
    return isAvailable;
  }
}
