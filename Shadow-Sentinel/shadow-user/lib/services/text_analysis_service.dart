import 'package:flutter/foundation.dart';

/// Result of analysing a transcribed text segment.
class TextAnalysisResult {
  /// Whether any flagged content was detected.
  final bool isFlagged;

  /// The specific words/phrases that triggered flags.
  final List<String> flaggedWords;

  /// Overall detected tone: neutral, professional, aggressive, hostile,
  /// threatening, profane, stressed, or negative.
  final String tone;

  /// Severity 0–100.  0 = clean, 100 = extremely problematic.
  final int severity;

  /// Human-readable alert message (empty when clean).
  final String alertMessage;

  /// Alert category for the `VoiceLanguageAlert.alertType` field.
  /// One of: profanity, hostility, threat, harassment, negative, none.
  final String alertType;

  const TextAnalysisResult({
    required this.isFlagged,
    required this.flaggedWords,
    required this.tone,
    required this.severity,
    required this.alertMessage,
    required this.alertType,
  });

  static const clean = TextAnalysisResult(
    isFlagged: false,
    flaggedWords: [],
    tone: 'neutral',
    severity: 0,
    alertMessage: '',
    alertType: 'none',
  );
}

/// Analyses transcribed text for profanity, hostility, threats, harassment
/// and overall tone — entirely offline using keyword / pattern matching.
///
/// This is intentionally *conservative*: it will only flag clearly
/// problematic language so that false-positive rates stay low.
class TextAnalysisService {
  // ────────────────────────────────────────────────────────────────
  // Category dictionaries
  // ────────────────────────────────────────────────────────────────

  /// Profane / vulgar language.
  static const _profanity = <String>[
    'fuck',
    'shit',
    'damn',
    'bitch',
    'ass',
    'bastard',
    'crap',
    'dick',
    'piss',
    'slut',
    'whore',
    'moron',
    'idiot',
    'dumbass',
    'bullshit',
    'asshole',
    'motherfucker',
    'wtf',
    'stfu',
  ];

  /// Hostile / aggressive language.
  static const _hostility = <String>[
    'hate you',
    'shut up',
    'get lost',
    'go to hell',
    'screw you',
    'i hate',
    'piss off',
    'back off',
    'drop dead',
    'leave me alone',
    'you suck',
    'piece of garbage',
    'worthless',
    'loser',
    'pathetic',
    'disgusting',
    'useless',
    'incompetent',
    'garbage',
    'terrible person',
  ];

  /// Threatening language.
  static const _threats = <String>[
    'kill you',
    'gonna kill',
    'i will kill',
    'murder',
    'destroy you',
    'beat you up',
    'hurt you',
    'punch you',
    'break your',
    'watch your back',
    'you are dead',
    'you\'re dead',
    'end you',
    'finish you',
    'regret this',
    'pay for this',
    'revenge',
    'bomb',
    'shoot',
    'weapon',
    'gun',
    'knife',
    'stab',
  ];

  /// Harassment / discriminatory language.
  static const _harassment = <String>[
    'retard',
    'faggot',
    'nigger',
    'chink',
    'spic',
    'kike',
    'tranny',
    'cripple',
    'freak',
    'go back to your country',
    'you people',
    'your kind',
    'don\'t belong',
  ];

  /// Negative / stressed / frustrated language (lower severity).
  static const _negative = <String>[
    'i can\'t take this',
    'so frustrated',
    'i give up',
    'this is hopeless',
    'stressed out',
    'overwhelmed',
    'burned out',
    'exhausted',
    'fed up',
    'sick of this',
    'done with this',
    'can\'t stand',
    'terrible',
    'horrible',
    'awful',
    'worst',
    'nightmare',
    'angry',
    'furious',
    'annoyed',
    'irritated',
    'pissed',
  ];

  // ────────────────────────────────────────────────────────────────
  // Public API
  // ────────────────────────────────────────────────────────────────

  /// Analyse [text] for problematic content.
  ///
  /// Returns a [TextAnalysisResult] with the findings.
  static TextAnalysisResult analyse(String text) {
    if (text.trim().isEmpty) return TextAnalysisResult.clean;

    final lower = text.toLowerCase();
    final flagged = <String>[];
    String topCategory = 'none';
    int topSeverity = 0;

    // Priority order: threat → harassment → profanity → hostility → negative
    void _scan(List<String> words, String category, int severity) {
      for (final w in words) {
        if (lower.contains(w)) {
          flagged.add(w);
          if (severity > topSeverity) {
            topSeverity = severity;
            topCategory = category;
          }
        }
      }
    }

    _scan(_threats, 'threat', 90);
    _scan(_harassment, 'harassment', 85);
    _scan(_profanity, 'profanity', 60);
    _scan(_hostility, 'hostility', 70);
    _scan(_negative, 'negative', 30);

    if (flagged.isEmpty) {
      return TextAnalysisResult.clean;
    }

    // Deduplicate
    final uniqueFlagged = flagged.toSet().toList();

    final tone = _toneFromCategory(topCategory, topSeverity);
    final message = _buildAlertMessage(topCategory, uniqueFlagged, topSeverity);

    debugPrint(
      '[TextAnalysis] Flagged: $topCategory (severity $topSeverity) '
      '— words: $uniqueFlagged',
    );

    return TextAnalysisResult(
      isFlagged: true,
      flaggedWords: uniqueFlagged,
      tone: tone,
      severity: topSeverity,
      alertMessage: message,
      alertType: topCategory,
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────────

  static String _toneFromCategory(String category, int severity) {
    if (severity >= 85) return 'hostile';
    if (severity >= 60) return 'aggressive';
    if (severity >= 30) return 'stressed';
    return 'neutral';
  }

  static String _buildAlertMessage(
    String category,
    List<String> flagged,
    int severity,
  ) {
    final preview = flagged.length > 3
        ? '${flagged.take(3).join(", ")} +${flagged.length - 3} more'
        : flagged.join(', ');
    switch (category) {
      case 'threat':
        return '⚠️ THREAT detected — keywords: $preview';
      case 'harassment':
        return '🚫 Harassment / discriminatory language detected — $preview';
      case 'profanity':
        return '🔴 Profane language detected — $preview';
      case 'hostility':
        return '🟠 Hostile / aggressive tone detected — $preview';
      case 'negative':
        return '🟡 Negative / stressed tone detected — $preview';
      default:
        return 'Flagged content detected — $preview';
    }
  }
}
