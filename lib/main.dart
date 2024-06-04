import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AudioPlayerApp());
}

class AudioPlayerApp extends StatelessWidget {
  const AudioPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Player App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AudioPlayerScreen(),
    );
  }
}

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Map<String, dynamic>> _phrases = [];
  List<Map<String, dynamic>> _userShowList = [];

  int _currentPhraseIndex = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadTranscript();
  }

  Future<void> _loadTranscript() async {
    String data = await DefaultAssetBundle.of(context)
        .loadString("assets/transcript.json");

    final transcript = json.decode(data);
    List<Map<String, dynamic>> phrases = [];
    List phrasesJohn = transcript['speakers'][0]['phrases'];
    List phrasesJack = transcript['speakers'][1]['phrases'];

    int maxLength = phrasesJohn.length > phrasesJack.length
        ? phrasesJohn.length
        : phrasesJack.length;

    for (int i = 0; i < maxLength; i++) {
      if (i < phrasesJohn.length) {
        phrases.add({
          'words': phrasesJohn[i]['words'],
          'time': phrasesJohn[i]['time'],
          'speaker': 'John',
        });
      }
      if (i < phrasesJack.length) {
        phrases.add({
          'words': phrasesJack[i]['words'],
          'time': phrasesJack[i]['time'],
          'speaker': 'Jack',
        });
      }
    }

    setState(() {
      _phrases = phrases;
    });
    List<Map<String, dynamic>> done = [];
    transcript['speakers'].forEach((speaker) {
      speaker['phrases'].forEach((phrase) {
        done.add({
          'words': phrase['words'],
          'time': phrase['time'],
          'speaker': speaker['name'],
        });
      });
    });

    setState(() {
      _userShowList = done;
    });
  }

  void _playAudio() {

    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _playNextPhrase();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  int currentIndex = 0;
  void _playNextPhrase() async {
    if (_currentPhraseIndex < _phrases.length) {
      final phrase = _phrases[_currentPhraseIndex];
      await _audioPlayer.play(
        AssetSource("1.mp3"),
        position: Duration(
          seconds: phrase["time"],
        ),
      );
      _audioPlayer.onPositionChanged.listen((event) {
        int index = _phrases
            .indexWhere((element) => element["time"] == event.inSeconds);

        if (index != -1) {
          setState(() {
            _currentPhraseIndex = index;
          });
        }
      });
    }
  }

  void _rewindAudio() async {
    if (_currentPhraseIndex==0) {
      return;
      
    }
    setState(() {
      _currentPhraseIndex--;



      _audioPlayer.seek(Duration(seconds: _phrases[_currentPhraseIndex]['time']));
    });
    // Duration? duration = await _audioPlayer.getCurrentPosition();
    // print(duration!.inSeconds);
  }

  void _forwardAudio() {
    if (_currentPhraseIndex < _phrases.length - 1) {
      setState(() {
        _currentPhraseIndex++;
        _audioPlayer
            .seek(Duration(seconds: _phrases[_currentPhraseIndex]['time']));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Player App'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _userShowList.length,
              itemBuilder: (context, index) {
                int indexU = _userShowList.indexWhere((element) =>
                    element["time"] == _phrases[_currentPhraseIndex]["time"]);

                return ListTile(
                  title: Text(_userShowList[index]['words']),
                  subtitle: Text('Speaker: ${_userShowList[index]['speaker']}'),
                  tileColor:
                      index == indexU ? Colors.blueAccent : Colors.transparent,
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: _rewindAudio,
              ),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: _playAudio,
              ),
              IconButton(
                icon: const Icon(Icons.forward_10),
                onPressed: _forwardAudio,
              ),
            ],
          ),
          const SizedBox(
            height: 40,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
