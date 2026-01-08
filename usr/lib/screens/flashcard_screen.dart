import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/flashcard.dart';
import 'dart:async';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

enum GameState { idle, recording, success, failure }

class _FlashcardScreenState extends State<FlashcardScreen> {
  int _currentIndex = 0;
  List<String> _inputBuffer = [];
  DateTime? _startTime;
  GameState _gameState = GameState.idle;
  String _feedbackMessage = '';
  Color _backgroundColor = Colors.white;
  Timer? _resetTimer;

  // Focus node to capture keyboard events
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Ensure the widget requests focus immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }

  Flashcard get _currentCard => mockFlashcards[_currentIndex];

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    if (_gameState == GameState.success || _gameState == GameState.failure) return;

    // Ignore standalone modifier presses (we only care when they modify another key)
    if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
        event.logicalKey == LogicalKeyboardKey.shiftRight ||
        event.logicalKey == LogicalKeyboardKey.controlLeft ||
        event.logicalKey == LogicalKeyboardKey.controlRight ||
        event.logicalKey == LogicalKeyboardKey.altLeft ||
        event.logicalKey == LogicalKeyboardKey.altRight ||
        event.logicalKey == LogicalKeyboardKey.metaLeft ||
        event.logicalKey == LogicalKeyboardKey.metaRight) {
      return;
    }

    // Start timer on first valid key press
    if (_gameState == GameState.idle) {
      setState(() {
        _gameState = GameState.recording;
        _startTime = DateTime.now();
      });
    }

    final String keyLabel = _getKeyLabel(event);
    _processInput(keyLabel);
  }

  String _getKeyLabel(KeyEvent event) {
    // Handle Control+Key chords (e.g., <C-v>)
    final bool isControlPressed = HardwareKeyboard.instance.isControlPressed;
    
    if (isControlPressed) {
      // If control is pressed, we format it as <C-key>
      // We use the logical key label to get the base key (e.g., 'v')
      // Note: logicalKey.keyLabel might be 'V' or 'v' depending on platform/layout, usually 'v' for alpha
      String char = event.logicalKey.keyLabel.toLowerCase();
      return '<C-$char>';
    }

    // Handle Shifted keys (e.g., 'G', ':', '"')
    // event.character usually returns the correct shifted character (e.g., 'G' if Shift+g is pressed)
    if (event.character != null && event.character!.isNotEmpty) {
      return event.character!;
    }

    // Fallback
    return event.logicalKey.keyLabel;
  }

  void _processInput(String input) {
    final targetSequence = _currentCard.sequence;
    final expectedKey = targetSequence[_inputBuffer.length];

    if (input == expectedKey) {
      // Correct key
      setState(() {
        _inputBuffer.add(input);
      });

      // Check if sequence is complete
      if (_inputBuffer.length == targetSequence.length) {
        _handleSuccess();
      }
    } else {
      // Wrong key
      _handleFailure();
    }
  }

  void _handleSuccess() {
    final endTime = DateTime.now();
    final duration = endTime.difference(_startTime!).inMilliseconds;
    final isSlow = duration > 500;

    setState(() {
      _gameState = GameState.success;
      _feedbackMessage = 'Executed in ${duration}ms.${isSlow ? " (Slow)" : " (New Personal Best!)"}';
      _backgroundColor = Colors.green.shade50;
    });

    // Auto advance after delay
    _resetTimer = Timer(const Duration(seconds: 2), () {
      _nextCard();
    });
  }

  void _handleFailure() {
    setState(() {
      _gameState = GameState.failure;
      _feedbackMessage = 'Incorrect! Resetting...';
      _backgroundColor = Colors.red.shade100;
    });

    // Reset after short delay
    _resetTimer = Timer(const Duration(milliseconds: 800), () {
      _resetCard();
    });
  }

  void _nextCard() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % mockFlashcards.length;
      _resetCardState();
    });
  }

  void _resetCard() {
    setState(() {
      _resetCardState();
    });
  }

  void _resetCardState() {
    _inputBuffer.clear();
    _gameState = GameState.idle;
    _feedbackMessage = '';
    _backgroundColor = Colors.white;
    _startTime = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header / Status
                  Text(
                    'Vim Muscle Memory',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.grey[600],
                          letterSpacing: 1.5,
                        ),
                  ),
                  const SizedBox(height: 60),

                  // Central Prompt
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _currentCard.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Key Slots Visualization
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: List.generate(_currentCard.sequence.length, (index) {
                      final isFilled = index < _inputBuffer.length;
                      final isCurrent = index == _inputBuffer.length;
                      final keyChar = isFilled ? _inputBuffer[index] : '';
                      
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isFilled 
                              ? Colors.black87 
                              : (isCurrent ? Colors.grey[200] : Colors.white),
                          border: Border.all(
                            color: isFilled ? Colors.black87 : Colors.grey[300]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isCurrent && _gameState == GameState.recording
                              ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          keyChar,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Courier New', // Monospace for code feel
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 40),

                  // Feedback Area
                  AnimatedOpacity(
                    opacity: _feedbackMessage.isNotEmpty ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: _gameState == GameState.failure 
                            ? Colors.red.shade50 
                            : (_gameState == GameState.success ? Colors.green.shade50 : Colors.transparent),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _gameState == GameState.failure 
                              ? Colors.red.shade200 
                              : (_gameState == GameState.success ? Colors.green.shade200 : Colors.transparent),
                        ),
                      ),
                      child: Text(
                        _feedbackMessage,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _gameState == GameState.failure 
                              ? Colors.red[700] 
                              : Colors.green[800],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),
                  
                  // Instructions
                  Text(
                    'Type the Vim command sequence...',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
