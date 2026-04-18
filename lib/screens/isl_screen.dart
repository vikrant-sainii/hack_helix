import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../blocs/isl/isl_bloc.dart';
import '../blocs/isl/isl_event.dart';
import '../blocs/isl/isl_state.dart';
import '../models/enriched_sign.dart';

/// Main screen for ISL Sign Language synthesis.
///
/// Layout:
///   - Three.js avatar WebView (top, fills most of screen)
///   - Status bar (shows current pipeline stage)
///   - Mic FAB (bottom center)
///
/// Dart → JS bridge: window.playSequence(json) called on [IslPlayingSequence]
class IslScreen extends StatefulWidget {
  const IslScreen({super.key});

  @override
  State<IslScreen> createState() => _IslScreenState();
}

class _IslScreenState extends State<IslScreen> {
  late final WebViewController _webViewController;
  bool _webViewReady = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _webViewReady = true),
        ),
      )
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _handleWebMessage(message.message);
        },
      )
      ..loadFlutterAsset('assets/avatar/index.html');
  }

  /// Handle messages from Three.js → Flutter
  /// e.g. {"type": "signStarted", "index": 1}
  /// e.g. {"type": "sequenceCompleted"}
  void _handleWebMessage(String rawMessage) {
    try {
      final Map<String, dynamic> msg =
          jsonDecode(rawMessage) as Map<String, dynamic>;
      final type = msg['type'] as String?;
      if (type == 'signStarted') {
        final index = msg['index'] as int? ?? 0;
        context.read<IslBloc>().add(IslSignStarted(index));
      } else if (type == 'sequenceCompleted') {
        context.read<IslBloc>().add(const IslSequenceCompleted());
      }
    } catch (_) {}
  }

  /// Send enriched signs to Three.js via window.playSequence(json)
  Future<void> _playSequenceInWebView(List<EnrichedSign> signs) async {
    if (!_webViewReady) return;
    final json = jsonEncode(signs.map((s) => s.toJson()).toList());
    await _webViewController.runJavaScript('window.playSequence($json)');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<IslBloc, IslState>(
      listener: (context, state) {
        if (state is IslPlayingSequence) {
          // Trigger avatar animation when enriched signs are ready
          _playSequenceInWebView(state.signs);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0E1A),
          elevation: 0,
          title: const Text(
            'ISL Sign Language',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Three.js Avatar WebView
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: WebViewWidget(controller: _webViewController),
              ),
            ),
            // Status Bar
            _buildStatusBar(),
            const SizedBox(height: 80),
          ],
        ),
        // Mic FAB
        floatingActionButton: _buildMicFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildStatusBar() {
    return BlocBuilder<IslBloc, IslState>(
      builder: (context, state) {
        String statusText;
        Color statusColor;

        if (state is IslIdle) {
          statusText = 'Tap mic to start speaking';
          statusColor = Colors.white54;
        } else if (state is IslListening) {
          statusText = '🎤 Listening...';
          statusColor = const Color(0xFF00E5FF);
        } else if (state is IslProcessingText) {
          statusText = 'Converting to ISL gloss...';
          statusColor = const Color(0xFFFFD54F);
        } else if (state is IslEnriching) {
          statusText = 'Loading sign keyframes...';
          statusColor = const Color(0xFFFFD54F);
        } else if (state is IslPlayingSequence) {
          statusText =
              '🤟 Signing: ${state.currentSign.gloss} (${state.currentIndex + 1}/${state.signs.length})';
          statusColor = const Color(0xFF69FF47);
        } else if (state is IslSequenceDone) {
          statusText = '✅ Done signing ${state.signs.length} signs';
          statusColor = const Color(0xFF69FF47);
        } else if (state is IslError) {
          statusText = '⚠️ ${state.message}';
          statusColor = Colors.redAccent;
        } else {
          statusText = '';
          statusColor = Colors.white54;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildMicFab() {
    return BlocBuilder<IslBloc, IslState>(
      builder: (context, state) {
        final isListening = state is IslListening;
        final isProcessing =
            state is IslProcessingText || state is IslEnriching;

        return GestureDetector(
          onTap: () {
            if (state is IslIdle || state is IslSequenceDone || state is IslError) {
              context.read<IslBloc>().add(const IslStartListening());
              // TODO: trigger STT start here
            } else if (isListening) {
              // TODO: stop STT and send transcript via IslTextReceived
            } else if (state is IslPlayingSequence || state is IslSequenceDone) {
              context.read<IslBloc>().add(const IslReset());
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isListening
                  ? Colors.redAccent
                  : isProcessing
                      ? const Color(0xFFFFD54F)
                      : const Color(0xFF6C63FF),
              boxShadow: [
                BoxShadow(
                  color: (isListening
                          ? Colors.redAccent
                          : const Color(0xFF6C63FF))
                      .withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              isListening
                  ? Icons.stop_rounded
                  : isProcessing
                      ? Icons.hourglass_top_rounded
                      : Icons.mic_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        );
      },
    );
  }
}
