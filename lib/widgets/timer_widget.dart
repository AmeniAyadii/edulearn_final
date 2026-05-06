// lib/games/guess_game/widgets/timer_widget.dart

import 'package:flutter/material.dart';
import 'dart:async';

class TimerWidget extends StatefulWidget {
  final int duration; // seconds
  final VoidCallback onTimeout;
  
  const TimerWidget({
    Key? key,
    required this.duration,
    required this.onTimeout,
  }) : super(key: key);
  
  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isDisposed = false;
  
  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.duration;
    _startTimer();
  }
  
  void _startTimer() {
    if (_isDisposed) return;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            timer.cancel();
            if (mounted && !_isDisposed) {
              widget.onTimeout();
            }
          }
        });
      }
    });
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    
    Color timerColor = Colors.white;
    if (_remainingSeconds < 10) timerColor = Colors.red;
    else if (_remainingSeconds < 30) timerColor = Colors.orange;
    
    // ✅ TAILLE FIXE pour éviter le débordement
    return SizedBox(
      width: 70,
      height: 32,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: timerColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: timerColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.timer,
              size: 14,
              color: timerColor,
            ),
            const SizedBox(width: 4),
            Text(
              timeString,
              style: TextStyle(
                color: timerColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}