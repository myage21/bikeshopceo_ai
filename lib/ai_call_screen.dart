import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:bikeshop_ceo_ai/gpt_util.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<StatefulWidget> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {

  late AudioPlayer _player;
  late stt.SpeechToText _speech;
  bool _isConnected = false;
  bool _isListening = true;
  int _callSeconds = 0;
  Timer? _timer;
  String _text = '말을 해보세요!';
  double _confidence = 0.8;
  bool _isAvatarGlowing = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _speech = stt.SpeechToText();

    // 홈화면이 뜨자마자 연결음 재생
    _playRingtone();
  }

  /// 통화연결음 > 통화연결 타이머 동작 > 초기음성 제공
  Future<void> _playRingtone() async {
    await _player.setReleaseMode(ReleaseMode.stop); // 1회만 재생
    await _player.play(AssetSource('standardringtone.mp3'));

    // 연결음 5초 후
    await Future.delayed(const Duration(seconds: 7)); // 5초 지연
    await _player.stop();

    // 상태변경: 연결음 종료 후
    setState(() {
      _isConnected = true;
    });


    // 통화타이머 시작
    _startCallTimer();

    await Future.delayed(const Duration(milliseconds: 500));

    // 여보세요?!
    await Tts.speak("여보세요? 왠일이야?");
  }

  Future<void> _callGPT() async {
    print('질문 : ' + _text);
    String answer = await callGPTApi(_text);
    print('답변 : ' + answer);
    await Tts.speak(answer);
    setState(() => _isListening = true);
  }

  /// 타이머 함수
  void _startCallTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callSeconds += 1;
      });
    });
  }

  /// 타이머 숫자 포맷팅
  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// 음성인식
  Future<void> _listen() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('onStatus: $status'),
      onError: (error) => print('onError: $error'),
    );

    if (available) {
      _speech.listen(
        localeId: 'ko_KR',
        onResult: (result) =>
          setState(() {
            _text = result.recognizedWords;
            _confidence = result.confidence;
          }),
      );
    } else {
      print('Speech recognition not available');
    }

    setState(() => _isListening = false);
  }


  /// 소멸자
  @override
  void dispose() {
    _player.dispose(); // 메모리 해제
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C2A4A), // 어두운 블루 배경
      body: SafeArea(
        child: Column(
          children: [
            // 상태바
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('22:48', style: TextStyle(color: Colors.white)),
                  Icon(Icons.battery_full, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // 상대방 이름
            const Text(
              '자전거 사장님',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              _isConnected ? _formatDuration(_callSeconds) : 'CALLING...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),
            // 프로필 이미지 (버튼)
            GestureDetector(
              onTap: () async {
                setState(() {
                  _isAvatarGlowing = true;
                });
                // 300ms 후에 반짝임 효과 제거
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    setState(() {
                      _isAvatarGlowing = false;
                    });
                  }
                });

                print("_isListening ====> " + _isListening.toString());
                if (_isListening) {
                  // 들어주기
                  await _listen();
                } else {
                  // 물어보고 답변해주기
                  await _callGPT();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: _isAvatarGlowing
                      ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ]
                      : [],
                ),
                child: const CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 60),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // 버튼 그룹
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _iconButton(Icons.contacts, 'Contacts'),
                  _iconButton(Icons.add_call, 'Add call'),
                  _iconButton(Icons.mic_off, 'Mute'),
                  _iconButton(Icons.pause, 'Hold'),
                  _iconButton(Icons.fiber_manual_record, 'Record'),
                  _iconButton(Icons.note, 'Note'),
                ],
              ),
            ),
            // 하단 종료 버튼 + 스피커 버튼
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: Colors.white, size: 36),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 48),
                  ElevatedButton(
                    onPressed: () {
                      // 음성 인식 중단
                      _speech.stop();
                      // 타이머 중단
                      _timer?.cancel();
                      // 상태 초기화
                      setState(() {
                        _isListening = true;
                        _isConnected = false;
                        _callSeconds = 0;
                      });
                      // 화면 종료
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(20),
                      backgroundColor: Colors.red,
                    ),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 36),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}