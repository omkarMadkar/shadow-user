import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'text_analysis_service.dart';

/// Represents a single global key event from the OS-level hook.
class GlobalKeyEvent {
  final String key;
  final bool isDown;
  final int vkCode;
  final int timestamp;
  final String foregroundWindow;

  const GlobalKeyEvent({
    required this.key,
    required this.isDown,
    required this.vkCode,
    required this.timestamp,
    required this.foregroundWindow,
  });

  @override
  String toString() =>
      'GlobalKeyEvent(key=$key, isDown=$isDown, vk=$vkCode, window=$foregroundWindow)';
}

/// Represents a detected content threat from typed text.
class ContentThreatAlert {
  final String id;
  final String typedText;
  final String deletedText;
  final String foregroundApp;
  final TextAnalysisResult analysis;
  final bool wasDeletedAfterTyping;
  final DateTime timestamp;
  final ContentThreatType threatType;

  const ContentThreatAlert({
    required this.id,
    required this.typedText,
    required this.deletedText,
    required this.foregroundApp,
    required this.analysis,
    required this.wasDeletedAfterTyping,
    required this.timestamp,
    required this.threatType,
  });
}

enum ContentThreatType {
  /// Threatening/abusive text detected in live typing
  liveTyping,

  /// User typed threatening content then backspaced it (cover-up attempt)
  backspaceCoverUp,

  /// Text was sent (Enter pressed) with threatening content
  sentThreatening,
}

/// OS-level global keyboard monitor that:
/// 1. Captures every keystroke system-wide via Win32 hooks
/// 2. Reconstructs typed text per app window
/// 3. Runs real-time threat/abuse analysis on the typed content
/// 4. Detects backspace-based deletion of abusive content (cover-up)
/// 5. Detects when threatening messages are sent (Enter key)
class GlobalKeystrokeMonitorService {
  static const _channel = MethodChannel('com.shadow_sentinel/global_keyboard');

  bool _isHooked = false;
  bool get isHooked => _isHooked;

  // ── Text Reconstruction ───────────────────────────────────
  /// Current buffer of typed text (per foreground window)
  final Map<String, StringBuffer> _windowBuffers = {};

  /// Deleted text buffer — tracks what was backspaced
  final Map<String, StringBuffer> _deletedBuffers = {};

  /// Recent full phrases that were "sent" (Enter pressed)
  final List<SentPhrase> _sentPhrases = [];
  List<SentPhrase> get sentPhrases => List.unmodifiable(_sentPhrases);

  /// Shift state tracking
  bool _shiftDown = false;
  bool _capsLock = false;

  // ── Threat Detection ──────────────────────────────────────
  final List<ContentThreatAlert> _threatAlerts = [];
  List<ContentThreatAlert> get threatAlerts => List.unmodifiable(_threatAlerts);

  int _alertCounter = 0;
  Timer? _analysisDebounce;

  // ── Callbacks ─────────────────────────────────────────────
  /// Called when a new global key event is received.
  void Function(GlobalKeyEvent event)? onKeyEvent;

  /// Called when a content threat is detected.
  void Function(ContentThreatAlert alert)? onThreatDetected;

  /// Called when the typed text buffer changes.
  void Function(String currentText, String windowTitle)? onTextChanged;

  /// Called when a sentence is "sent" (Enter pressed).
  void Function(SentPhrase phrase)? onPhraseSent;

  // ── Lifecycle ─────────────────────────────────────────────

  /// Start the global keyboard hook.
  Future<bool> startHook() async {
    try {
      // Set up the method call handler for incoming events from native
      _channel.setMethodCallHandler(_handleNativeCall);

      final result = await _channel.invokeMethod<bool>('startHook');
      _isHooked = result ?? false;
      debugPrint('[GlobalKeystrokeMonitor] Hook started: $_isHooked');
      return _isHooked;
    } catch (e) {
      debugPrint('[GlobalKeystrokeMonitor] Failed to start hook: $e');
      _isHooked = false;
      return false;
    }
  }

  /// Stop the global keyboard hook.
  Future<void> stopHook() async {
    try {
      await _channel.invokeMethod('stopHook');
      _isHooked = false;
      _analysisDebounce?.cancel();
      debugPrint('[GlobalKeystrokeMonitor] Hook stopped');
    } catch (e) {
      debugPrint('[GlobalKeystrokeMonitor] Failed to stop hook: $e');
    }
  }

  /// Handle method calls from native (C++) side.
  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onGlobalKey') {
      final Map<dynamic, dynamic> data = call.arguments as Map;
      final event = GlobalKeyEvent(
        key: data['key'] as String? ?? '',
        isDown: data['isDown'] as bool? ?? true,
        vkCode: data['vkCode'] as int? ?? 0,
        timestamp: data['timestamp'] as int? ?? 0,
        foregroundWindow: data['foregroundWindow'] as String? ?? '',
      );

      _processKeyEvent(event);
      onKeyEvent?.call(event);
    }
    return null;
  }

  // ── Key Processing ────────────────────────────────────────

  void _processKeyEvent(GlobalKeyEvent event) {
    // Only process key-down events for text reconstruction
    if (!event.isDown) {
      // Track shift release
      if (event.key == 'Shift') _shiftDown = false;
      return;
    }

    final window = event.foregroundWindow;

    // Track modifier state
    if (event.key == 'Shift') {
      _shiftDown = true;
      return;
    }
    if (event.key == 'CapsLock') {
      _capsLock = !_capsLock;
      return;
    }

    // Skip other modifier keys
    if (event.key == 'Control' ||
        event.key == 'Alt' ||
        event.key == 'Escape' ||
        event.key == 'Tab' ||
        event.key.startsWith('F') && event.key.length <= 3 ||
        event.key.startsWith('VK_')) {
      return;
    }

    // Ensure buffer exists for this window
    _windowBuffers.putIfAbsent(window, () => StringBuffer());
    _deletedBuffers.putIfAbsent(window, () => StringBuffer());

    final buffer = _windowBuffers[window]!;

    if (event.key == 'Backspace') {
      _handleBackspace(window, buffer);
    } else if (event.key == 'Enter') {
      _handleEnter(window, buffer);
    } else if (event.key == 'Delete') {
      // Delete key — similar to backspace for threat purposes
      _handleBackspace(window, buffer);
    } else {
      // Regular character
      final char = _resolveCharacter(event.key);
      if (char.isNotEmpty) {
        buffer.write(char);

        // Debounced analysis (analyze after 500ms of no typing)
        _analysisDebounce?.cancel();
        _analysisDebounce = Timer(const Duration(milliseconds: 500), () {
          _analyzeLiveBuffer(window, buffer.toString());
        });

        onTextChanged?.call(buffer.toString(), window);
      }
    }
  }

  /// Handle Backspace: move deleted char to the deleted buffer for analysis.
  void _handleBackspace(String window, StringBuffer buffer) {
    final text = buffer.toString();
    if (text.isEmpty) return;

    // Capture what's being deleted
    final deletedChar = text[text.length - 1];
    _deletedBuffers[window]!.write(deletedChar);

    // Remove last character from buffer
    _windowBuffers[window] = StringBuffer(text.substring(0, text.length - 1));

    final deletedText = _deletedBuffers[window]!.toString();
    final currentText = _windowBuffers[window]!.toString();

    // Analyze the deleted text for cover-up detection
    // Only check if significant amount was deleted (3+ chars)
    if (deletedText.length >= 3) {
      _analyzeDeletedContent(window, deletedText, currentText);
    }

    onTextChanged?.call(currentText, window);
  }

  /// Handle Enter: treat as "send" — analyze the full typed sentence.
  void _handleEnter(String window, StringBuffer buffer) {
    final text = buffer.toString().trim();
    if (text.isEmpty) {
      _resetBuffers(window);
      return;
    }

    // Analyze for threats before marking as sent
    final analysis = TextAnalysisService.analyse(text);

    final phrase = SentPhrase(
      text: text,
      foregroundApp: window,
      timestamp: DateTime.now(),
      isThreatening: analysis.isFlagged,
      analysis: analysis,
    );

    _sentPhrases.insert(0, phrase);
    if (_sentPhrases.length > 50) _sentPhrases.removeLast();

    onPhraseSent?.call(phrase);

    // Generate alert if threatening content was sent
    if (analysis.isFlagged && analysis.severity >= 60) {
      _addThreatAlert(
        typedText: text,
        deletedText: '',
        foregroundApp: window,
        analysis: analysis,
        wasDeletedAfterTyping: false,
        threatType: ContentThreatType.sentThreatening,
      );
    }

    // Reset buffers for this window
    _resetBuffers(window);
  }

  /// Resolve a key label to its actual character based on shift/caps state.
  String _resolveCharacter(String keyLabel) {
    if (keyLabel.length == 1) {
      final isLetter =
          keyLabel.codeUnitAt(0) >= 97 && keyLabel.codeUnitAt(0) <= 122;
      if (isLetter) {
        final upper = _shiftDown ^ _capsLock;
        return upper ? keyLabel.toUpperCase() : keyLabel;
      }
      // Numbers with shift → symbols
      if (_shiftDown) {
        switch (keyLabel) {
          case '1':
            return '!';
          case '2':
            return '@';
          case '3':
            return '#';
          case '4':
            return '\$';
          case '5':
            return '%';
          case '6':
            return '^';
          case '7':
            return '&';
          case '8':
            return '*';
          case '9':
            return '(';
          case '0':
            return ')';
        }
      }
      return keyLabel;
    }
    // Multi-character labels
    if (keyLabel == ' ') return ' ';
    if (keyLabel == '.') return _shiftDown ? '>' : '.';
    if (keyLabel == ',') return _shiftDown ? '<' : ',';
    if (keyLabel == ';') return _shiftDown ? ':' : ';';
    if (keyLabel == '/') return _shiftDown ? '?' : '/';
    if (keyLabel == "'") return _shiftDown ? '"' : "'";
    if (keyLabel == '-') return _shiftDown ? '_' : '-';
    if (keyLabel == '=') return _shiftDown ? '+' : '=';
    if (keyLabel == '[') return _shiftDown ? '{' : '[';
    if (keyLabel == ']') return _shiftDown ? '}' : ']';
    if (keyLabel == '\\') return _shiftDown ? '|' : '\\';
    if (keyLabel == '`') return _shiftDown ? '~' : '`';

    return '';
  }

  // ── Analysis ──────────────────────────────────────────────

  /// Analyze the current live buffer for threatening content.
  void _analyzeLiveBuffer(String window, String text) {
    if (text.length < 5) return; // Too short to analyze

    final analysis = TextAnalysisService.analyse(text);

    if (analysis.isFlagged && analysis.severity >= 50) {
      _addThreatAlert(
        typedText: text,
        deletedText: '',
        foregroundApp: window,
        analysis: analysis,
        wasDeletedAfterTyping: false,
        threatType: ContentThreatType.liveTyping,
      );
    }
  }

  /// Analyze deleted content — detect if abusive text was typed then erased.
  void _analyzeDeletedContent(
    String window,
    String deletedText,
    String currentText,
  ) {
    // Reverse the deleted text (it was captured char-by-char backwards)
    final reversedDeleted = deletedText.split('').reversed.join('');

    final analysis = TextAnalysisService.analyse(reversedDeleted);

    if (analysis.isFlagged && analysis.severity >= 40) {
      _addThreatAlert(
        typedText: currentText,
        deletedText: reversedDeleted,
        foregroundApp: window,
        analysis: analysis,
        wasDeletedAfterTyping: true,
        threatType: ContentThreatType.backspaceCoverUp,
      );
    }
  }

  void _addThreatAlert({
    required String typedText,
    required String deletedText,
    required String foregroundApp,
    required TextAnalysisResult analysis,
    required bool wasDeletedAfterTyping,
    required ContentThreatType threatType,
  }) {
    _alertCounter++;
    final alert = ContentThreatAlert(
      id: 'CT-${DateTime.now().millisecondsSinceEpoch}-$_alertCounter',
      typedText: typedText,
      deletedText: deletedText,
      foregroundApp: foregroundApp,
      analysis: analysis,
      wasDeletedAfterTyping: wasDeletedAfterTyping,
      timestamp: DateTime.now(),
      threatType: threatType,
    );

    _threatAlerts.insert(0, alert);
    if (_threatAlerts.length > 30) _threatAlerts.removeLast();

    debugPrint(
      '[GlobalKeystrokeMonitor] THREAT: ${threatType.name} | '
      'severity=${analysis.severity} | app=$foregroundApp | '
      'words=${analysis.flaggedWords}',
    );

    onThreatDetected?.call(alert);
  }

  void _resetBuffers(String window) {
    _windowBuffers[window] = StringBuffer();
    _deletedBuffers[window] = StringBuffer();
  }

  // ── Accessors ─────────────────────────────────────────────

  /// Get the current typed text for a window.
  String getCurrentText(String window) {
    return _windowBuffers[window]?.toString() ?? '';
  }

  /// Get all window buffers.
  Map<String, String> get allWindowBuffers {
    return _windowBuffers.map((k, v) => MapEntry(k, v.toString()));
  }

  /// Clear all buffers and alerts.
  void clearAll() {
    _windowBuffers.clear();
    _deletedBuffers.clear();
    _threatAlerts.clear();
    _sentPhrases.clear();
    _alertCounter = 0;
  }

  void dispose() {
    _analysisDebounce?.cancel();
    stopHook();
  }
}

/// A phrase that was "sent" (Enter pressed) with analysis results.
class SentPhrase {
  final String text;
  final String foregroundApp;
  final DateTime timestamp;
  final bool isThreatening;
  final TextAnalysisResult analysis;

  const SentPhrase({
    required this.text,
    required this.foregroundApp,
    required this.timestamp,
    required this.isThreatening,
    required this.analysis,
  });
}
