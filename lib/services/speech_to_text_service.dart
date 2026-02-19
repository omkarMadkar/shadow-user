import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Transcribes .wav audio files using Windows built-in Speech Recognition
/// (System.Speech.Recognition via .NET / PowerShell).
///
/// No external API keys or services required — runs entirely offline using
/// the Windows Desktop Speech Recognition engine.
class SpeechToTextService {
  /// Transcribe a PCM `.wav` file at [wavPath] into text.
  ///
  /// Uses `System.Speech.Recognition.SpeechRecognitionEngine` with a
  /// `DictationGrammar` to perform free-form dictation recognition.
  /// Calls `Recognize()` in a loop to capture all phrases in the audio.
  ///
  /// Returns the transcribed text, or an empty string if nothing was
  /// recognised or an error occurred.
  static Future<String> transcribeWav(String wavPath) async {
    try {
      // Verify the file exists and has content
      final file = File(wavPath);
      if (!await file.exists()) {
        debugPrint('[SpeechToText] File not found: $wavPath');
        return '';
      }
      final fileSize = await file.length();
      if (fileSize < 1000) {
        // Too small to contain meaningful audio
        debugPrint('[SpeechToText] File too small ($fileSize bytes): $wavPath');
        return '';
      }

      debugPrint('[SpeechToText] Transcribing: $wavPath ($fileSize bytes)');

      // Write a temp .ps1 script so we avoid all inline escaping issues.
      final tempDir = await getTemporaryDirectory();
      final scriptFile = File(
        p.join(
          tempDir.path,
          'stt_${DateTime.now().millisecondsSinceEpoch}.ps1',
        ),
      );

      // Use single-quoted here-string for the WAV path to avoid
      // PowerShell escape issues with backslashes.
      final scriptContent =
          '''
try {
    Add-Type -AssemblyName System.Speech -ErrorAction Stop
} catch {
    Write-Error "System.Speech assembly not available"
    exit 1
}

try {
    \$wavFile = '$wavPath'
    \$recognizer = New-Object System.Speech.Recognition.SpeechRecognitionEngine
    \$grammar = New-Object System.Speech.Recognition.DictationGrammar
    \$recognizer.LoadGrammar(\$grammar)
    \$recognizer.SetInputToWaveFile(\$wavFile)

    \$allText = @()
    while (\$true) {
        \$result = \$recognizer.Recognize()
        if (\$result -eq \$null) { break }
        if (\$result.Text -ne \$null -and \$result.Text -ne '') {
            \$allText += \$result.Text
        }
    }
    \$recognizer.Dispose()

    if (\$allText.Count -gt 0) {
        Write-Output (\$allText -join ' ')
    }
} catch {
    Write-Error \$_.Exception.Message
    exit 1
}
''';

      await scriptFile.writeAsString(scriptContent);

      final result = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        scriptFile.path,
      ]);

      // Clean up the temp script
      try {
        await scriptFile.delete();
      } catch (_) {}

      if (result.exitCode == 0) {
        final text = (result.stdout as String).trim();
        if (text.isNotEmpty) {
          debugPrint('[SpeechToText] Result: $text');
        } else {
          debugPrint('[SpeechToText] No speech recognised in audio');
        }
        return text;
      } else {
        final err = (result.stderr as String).trim();
        debugPrint(
          '[SpeechToText] PowerShell error (exit ${result.exitCode}): $err',
        );
        return '';
      }
    } catch (e) {
      debugPrint('[SpeechToText] Exception: $e');
      return '';
    }
  }
}
