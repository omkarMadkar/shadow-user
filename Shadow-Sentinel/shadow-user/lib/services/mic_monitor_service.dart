import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Information about an application using the microphone.
class MicUsageInfo {
  final String appPath;
  final String appName;
  final DateTime detectedAt;

  const MicUsageInfo({
    required this.appPath,
    required this.appName,
    required this.detectedAt,
  });

  @override
  String toString() => appName;
}

/// Monitors OS-level microphone usage on Windows.
///
/// Uses the Windows CapabilityAccessManager registry to detect which
/// applications are currently accessing the microphone. This runs a
/// lightweight PowerShell check at a configurable interval.
class MicMonitorService {
  Timer? _pollTimer;
  final List<MicUsageInfo> _activeApps = [];
  final _controller = StreamController<List<MicUsageInfo>>.broadcast();
  bool _isMonitoring = false;

  /// Stream of active microphone-using applications.
  Stream<List<MicUsageInfo>> get micUsageStream => _controller.stream;

  /// Current list of apps using the mic.
  List<MicUsageInfo> get activeApps => List.unmodifiable(_activeApps);

  /// Whether any external app is currently using the mic.
  bool get isMicInUseByExternalApp => _activeApps.isNotEmpty;

  /// Whether monitoring is active.
  bool get isMonitoring => _isMonitoring;

  /// Start monitoring microphone usage at the OS level.
  void startMonitoring({Duration interval = const Duration(seconds: 4)}) {
    if (!Platform.isWindows) {
      debugPrint('[MicMonitor] Only Windows is supported for mic monitoring');
      return;
    }

    _pollTimer?.cancel();
    _isMonitoring = true;
    _pollTimer = Timer.periodic(interval, (_) => _checkMicUsage());
    _checkMicUsage(); // Immediate first check
  }

  /// Stop monitoring.
  void stopMonitoring() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isMonitoring = false;
  }

  /// Check which apps are currently using the microphone via Windows registry.
  Future<void> _checkMicUsage() async {
    if (!Platform.isWindows) return;

    try {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        _micCheckScript,
      ]);

      final output = (result.stdout as String).trim();
      final previousCount = _activeApps.length;
      _activeApps.clear();

      if (output.startsWith('ACTIVE:')) {
        final apps = output.substring(7).split('|');
        for (final app in apps) {
          if (app.trim().isEmpty) continue;
          _activeApps.add(
            MicUsageInfo(
              appPath: app.trim(),
              appName: _extractAppName(app.trim()),
              detectedAt: DateTime.now(),
            ),
          );
        }
      }

      // Only emit if there's a change
      if (_activeApps.length != previousCount || _activeApps.isNotEmpty) {
        _controller.add(List.unmodifiable(_activeApps));
      }
    } catch (e) {
      debugPrint('[MicMonitor] Error checking mic usage: $e');
    }
  }

  /// Extract a user-friendly app name from the registry path.
  String _extractAppName(String rawPath) {
    // Registry NonPackaged paths use # instead of \
    final path = rawPath.replaceAll('#', '\\');

    // Get the executable name
    final parts = path.split('\\');
    final exe = parts.lastWhere(
      (p) => p.toLowerCase().endsWith('.exe'),
      orElse: () => parts.last,
    );

    // Clean up the name
    String name = exe.replaceAll('.exe', '').replaceAll('_', ' ');

    // Capitalize first letter of each word
    name = name
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        })
        .join(' ');

    return name;
  }

  void dispose() {
    stopMonitoring();
    _controller.close();
  }

  /// PowerShell script to check Windows CapabilityAccessManager registry
  /// for applications that currently have microphone access.
  ///
  /// When LastUsedTimeStart > LastUsedTimeStop, the mic is actively in use.
  static const String _micCheckScript = r'''
$ErrorActionPreference = "SilentlyContinue"
$basePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone"
$activeApps = @()

# Check NonPackaged (Win32 desktop) apps
$nonPackaged = Get-ChildItem "$basePath\NonPackaged" -ErrorAction SilentlyContinue
foreach ($app in $nonPackaged) {
    $props = Get-ItemProperty $app.PSPath -ErrorAction SilentlyContinue
    if ($null -ne $props.LastUsedTimeStart -and $null -ne $props.LastUsedTimeStop) {
        if ([int64]$props.LastUsedTimeStart -gt [int64]$props.LastUsedTimeStop) {
            $activeApps += $app.PSChildName
        }
    }
}

# Check Packaged (UWP/Store) apps
$packaged = Get-ChildItem "$basePath" -ErrorAction SilentlyContinue |
    Where-Object { $_.PSChildName -ne "NonPackaged" -and $_.PSIsContainer }
foreach ($app in $packaged) {
    $props = Get-ItemProperty $app.PSPath -ErrorAction SilentlyContinue
    if ($null -ne $props.LastUsedTimeStart -and $null -ne $props.LastUsedTimeStop) {
        if ([int64]$props.LastUsedTimeStart -gt [int64]$props.LastUsedTimeStop) {
            $activeApps += $app.PSChildName
        }
    }
}

if ($activeApps.Count -gt 0) {
    Write-Output ("ACTIVE:" + ($activeApps -join "|"))
} else {
    Write-Output "INACTIVE"
}
''';
}
