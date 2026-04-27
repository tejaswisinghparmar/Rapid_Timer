import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const PerformanceStopwatchApp());
}

class PerformanceStopwatchApp extends StatelessWidget {
  const PerformanceStopwatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Performance Stopwatch',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2E2E2E),
          surface: Color(0xFF121212),
          onSurface: Color(0xFFEAEAEA),
          onPrimary: Color(0xFFFFFFFF),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Color(0xFFEAEAEA),
        ),
        useMaterial3: true,
      ),
      home: const StopwatchHomePage(),
    );
  }
}

class CaptureEntry {
  const CaptureEntry({required this.index, required this.elapsed});

  final int index;
  final Duration elapsed;

  Map<String, int> toMap() {
    return <String, int>{
      'index': index,
      'elapsedMs': elapsed.inMilliseconds,
    };
  }

  static CaptureEntry? fromMap(Map<String, dynamic> map) {
    final int? idx = map['index'] as int?;
    final int? elapsedMs = map['elapsedMs'] as int?;
    if (idx == null || elapsedMs == null || idx <= 0 || elapsedMs < 0) {
      return null;
    }
    return CaptureEntry(index: idx, elapsed: Duration(milliseconds: elapsedMs));
  }
}

class StopwatchHomePage extends StatefulWidget {
  const StopwatchHomePage({super.key});

  @override
  State<StopwatchHomePage> createState() => _StopwatchHomePageState();
}

class _StopwatchHomePageState extends State<StopwatchHomePage>
    with SingleTickerProviderStateMixin {
  static const _storageKey = 'captured_entries_v1';

  final List<CaptureEntry> _captures = <CaptureEntry>[];

  DateTime _anchorStart = DateTime.now();
  Duration _elapsed = Duration.zero;
  int _nextIndex = 1;
  Ticker? _ticker;

  @override
  void initState() {
    super.initState();
    _loadCaptures();
    _startHighPrecisionTicker();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _startHighPrecisionTicker() {
    _ticker?.dispose();
    _ticker = createTicker((Duration _) {
      final Duration next = DateTime.now().difference(_anchorStart);
      if (!mounted) return;
      setState(() {
        _elapsed = next;
      });
    });
    _ticker?.start();
  }

  Future<void> _loadCaptures() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);

    final List<CaptureEntry> loaded = <CaptureEntry>[];
    if (raw != null && raw.isNotEmpty) {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is List<dynamic>) {
        for (final dynamic item in decoded) {
          if (item is Map<String, dynamic>) {
            final CaptureEntry? parsed = CaptureEntry.fromMap(item);
            if (parsed != null) {
              loaded.add(parsed);
            }
          }
        }
      }
    }

    int next = 1;
    if (loaded.isNotEmpty) {
      next = loaded.map((CaptureEntry e) => e.index).reduce((int a, int b) => a > b ? a : b) + 1;
    }

    if (!mounted) return;
    setState(() {
      _captures
        ..clear()
        ..addAll(loaded);
      _nextIndex = next;
    });
  }

  Future<void> _saveCaptures() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String payload = jsonEncode(
      _captures.map((CaptureEntry e) => e.toMap()).toList(growable: false),
    );
    await prefs.setString(_storageKey, payload);
  }

  Future<void> _captureAndReset() async {
    HapticFeedback.mediumImpact();

    final DateTime now = DateTime.now();
    final Duration captured = now.difference(_anchorStart);

    setState(() {
      _captures.insert(
        0,
        CaptureEntry(index: _nextIndex, elapsed: captured),
      );
      _nextIndex += 1;
      _anchorStart = now;
      _elapsed = Duration.zero;
    });

    await _saveCaptures();
  }

  Future<void> _clearAll() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _captures.clear();
      _nextIndex = 1;
      _anchorStart = DateTime.now();
      _elapsed = Duration.zero;
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All captured times cleared.')),
    );
  }

  Future<void> _copyAll() async {
    if (_captures.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No captures to copy.')),
      );
      return;
    }

    final List<CaptureEntry> ordered = _captures.reversed.toList(growable: false);
    final String text = ordered
        .map((CaptureEntry e) => '${e.index}. ${_formatDuration(e.elapsed)}')
        .join('\n');

    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied all captures to clipboard.')),
    );
  }

  String _formatDuration(Duration d) {
    final int hours = d.inHours;
    final int minutes = d.inMinutes.remainder(60);
    final int seconds = d.inSeconds.remainder(60);

    String two(int n) => n.toString().padLeft(2, '0');

    return '${two(hours)}:${two(minutes)}:${two(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    const Color panel = Color(0xFF121212);
    final String display = _formatDuration(_elapsed);

    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        leading: GestureDetector(
          onLongPress: _clearAll,
          child: const Tooltip(
            message: 'Long press to clear',
            child: Icon(Icons.clear_all_rounded),
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Copy',
            onPressed: _copyAll,
            icon: const Icon(Icons.copy_all_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _copyAll,
        backgroundColor: const Color(0xFF1F1F1F),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.copy_rounded),
        label: const Text('Copy All'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 16),
            Center(
              child: Text(
                display,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _captureAndReset,
                child: Column(
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: panel,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF232323)),
                      ),
                      child: const Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Index',
                              style: TextStyle(
                                color: Color(0xFFB0B0B0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Captured Time',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Color(0xFFB0B0B0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _captures.isEmpty
                          ? const Center(
                              child: Text(
                                'Tap anywhere in this zone to capture and restart.',
                                style: TextStyle(color: Color(0xFF777777)),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                              itemCount: _captures.length,
                              itemBuilder: (BuildContext context, int idx) {
                                final CaptureEntry item = _captures[idx];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: panel,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF1E1E1E)),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          '#${item.index}',
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 18,
                                            color: Color(0xFFE3E3E3),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          _formatDuration(item.elapsed),
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
