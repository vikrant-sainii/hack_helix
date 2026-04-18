import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../blocs/isl/isl_bloc.dart';
import '../blocs/isl/isl_event.dart';
import '../blocs/isl/isl_state.dart';
import '../models/enriched_sign.dart';

/// Main ISL screen — modeled on CrisisMatch VoiceAssistantScreen.
///
/// Layout phases:
///   IslIdle        → Welcome + mic FAB
///   IslListening   → Large live transcript + pulsing glow bar
///   IslProcessing  → "Translating..." shimmer
///   IslPlaying     → Spoken text + Three.js WebView signing avatar
///   IslDone        → "Done signing" + replay/reset option
class IslScreen extends StatefulWidget {
  const IslScreen({super.key});

  @override
  State<IslScreen> createState() => _IslScreenState();
}

class _IslScreenState extends State<IslScreen>
    with SingleTickerProviderStateMixin {
  // ── Animation ─────────────────────────────────────────────────────────────
  late final AnimationController _pulseCtrl;

  // ── WebView ───────────────────────────────────────────────────────────────
  late final WebViewController _webCtrl;
  bool _webReady = false;
  bool _sequenceSent = false; // guard: only call playSequence once per sequence

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _webCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0A0E1A))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _webReady = true),
        onWebResourceError: (e) =>
            debugPrint('[WebView] Error: ${e.description}'),
      ))
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (msg) => _handleWebMessage(msg.message),
      )
      ..loadFlutterAsset('assets/avatar/index.html');
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Three.js → Flutter bridge ─────────────────────────────────────────────

  void _handleWebMessage(String raw) {
    try {
      final msg = jsonDecode(raw) as Map<String, dynamic>;
      final type = msg['type'] as String?;
      if (type == 'signStarted') {
        final idx = (msg['index'] as num?)?.toInt() ?? 0;
        context.read<IslBloc>().add(IslSignStarted(idx));
      } else if (type == 'sequenceCompleted') {
        context.read<IslBloc>().add(const IslSequenceCompleted());
      } else if (type == 'ready') {
        // WebView finished loading avatar
        debugPrint('[WebView] Avatar ready');
      }
    } catch (e) {
      debugPrint('[WebView] message parse error: $e');
    }
  }

  // ── Flutter → Three.js bridge ─────────────────────────────────────────────

  Future<void> _playSigns(List<EnrichedSign> signs) async {
    if (!_webReady || _sequenceSent) return;
    _sequenceSent = true;
    final json = jsonEncode(signs.map((s) => s.toJson()).toList());
    await _webCtrl.runJavaScript('window.playSequence($json)');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<IslBloc, IslState>(
      listener: (ctx, state) {
        if (state is IslPlayingSequence) {
          _sequenceSent = false; // reset guard for a new sequence
          _playSigns(state.signs);
        }
        if (state is IslIdle) {
          _sequenceSent = false;
          if (_webReady) _webCtrl.runJavaScript('window.resetAvatar()');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF131314),
        body: BlocBuilder<IslBloc, IslState>(
          builder: (ctx, state) => SafeArea(
            child: Stack(
              children: [
                // ── Main content ─────────────────────────────────────
                _buildMainContent(state),

                // ── Top status chip ───────────────────────────────────
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: _buildStatusChip(state),
                ),

                // ── Bottom glow bar (listening/processing only) ───────
                if (state is IslListening || state is IslProcessingText)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildGlowBar(state),
                  ),
              ],
            ),
          ),
        ),
        floatingActionButton: _buildFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  // ── Status chip (top) ─────────────────────────────────────────────────────

  Widget _buildStatusChip(IslState state) {
    String label;
    IconData icon;
    Color iconColor;

    if (state is IslIdle) {
      label = 'ISL Sign Language';
      icon = Icons.sign_language_rounded;
      iconColor = const Color(0xFF6C63FF);
    } else if (state is IslListening) {
      label = state.liveText.isEmpty ? 'Listening...' : 'Listening...';
      icon = Icons.mic_none_outlined;
      iconColor = Colors.redAccent;
    } else if (state is IslProcessingText) {
      label = 'Translating to ISL...';
      icon = Icons.translate_rounded;
      iconColor = const Color(0xFFFFD54F);
    } else if (state is IslPlayingSequence) {
      label =
          'Signing: ${state.currentSign.gloss} (${state.currentIndex + 1}/${state.signs.length})';
      icon = Icons.sign_language_rounded;
      iconColor = const Color(0xFF69FF47);
    } else if (state is IslSequenceDone) {
      label = 'Done — ${state.signs.length} signs';
      icon = Icons.check_circle_outline_rounded;
      iconColor = const Color(0xFF69FF47);
    } else if (state is IslError) {
      label = 'Error';
      icon = Icons.error_outline_rounded;
      iconColor = Colors.redAccent;
    } else {
      label = '';
      icon = Icons.sign_language_rounded;
      iconColor = Colors.white54;
    }

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main content (center of screen) ──────────────────────────────────────

  Widget _buildMainContent(IslState state) {
    if (state is IslIdle) {
      return _buildIdleView();
    } else if (state is IslListening) {
      return _buildListeningView(state);
    } else if (state is IslProcessingText) {
      return _buildProcessingView(state);
    } else if (state is IslPlayingSequence || state is IslSequenceDone) {
      final spokenText = state is IslPlayingSequence
          ? state.spokenText
          : (state as IslSequenceDone).spokenText;
      return _buildAvatarView(spokenText, state);
    } else if (state is IslError) {
      return _buildErrorView(state);
    }
    return const SizedBox.shrink();
  }

  // ── Idle view ─────────────────────────────────────────────────────────────

  Widget _buildIdleView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 80),
        Center(
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF00E5FF)],
            ).createShader(rect),
            child: const Icon(
              Icons.sign_language_rounded,
              size: 80,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'ISL Sign Language',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            'Speak in Hindi or English\nand watch the avatar sign in ISL',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ),
        const Spacer(),
        // Avatar WebView pre-loaded in background
        SizedBox(
          height: 0,
          child: WebViewWidget(controller: _webCtrl),
        ),
        const SizedBox(height: 120),
      ],
    );
  }

  // ── Listening view ────────────────────────────────────────────────────────

  Widget _buildListeningView(IslListening state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 80),
        const Expanded(flex: 2, child: SizedBox()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              state.liveText.isEmpty ? '...' : state.liveText,
              key: ValueKey(state.liveText),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ),
        const Expanded(flex: 4, child: SizedBox()),
        const SizedBox(height: 120),
      ],
    );
  }

  // ── Processing view ───────────────────────────────────────────────────────

  Widget _buildProcessingView(IslProcessingText state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 80),
        const Expanded(flex: 2, child: SizedBox()),
        Center(
          child: Column(
            children: [
              const SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(
                  color: Color(0xFF6C63FF),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '"${state.spokenText}"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const Expanded(flex: 3, child: SizedBox()),
        const SizedBox(height: 80),
      ],
    );
  }

  // ── Avatar view (playing + done) ──────────────────────────────────────────

  Widget _buildAvatarView(String spokenText, IslState state) {
    final isDone = state is IslSequenceDone;
    return Column(
      children: [
        const SizedBox(height: 72),
        // Spoken text display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: Text(
            '"$spokenText"',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 18,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Three.js avatar WebView — fills remaining space
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: WebViewWidget(controller: _webCtrl),
          ),
        ),
        // Done: Show replay option
        if (isDone) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () =>
                context.read<IslBloc>().add(const IslReset()),
            icon: const Icon(Icons.replay_rounded,
                color: Color(0xFF6C63FF)),
            label: const Text(
              'Speak again',
              style: TextStyle(color: Color(0xFF6C63FF), fontSize: 15),
            ),
          ),
        ],
        SizedBox(height: isDone ? 24.0 : 80.0),
      ],
    );
  }

  // ── Error view ────────────────────────────────────────────────────────────

  Widget _buildErrorView(IslError state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            state.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => context.read<IslBloc>().add(const IslReset()),
          child: const Text('Try again',
              style: TextStyle(color: Color(0xFF6C63FF))),
        ),
      ],
    );
  }

  // ── Bottom glow bar (Google Assistant style) ──────────────────────────────

  Widget _buildGlowBar(IslState state) {
    final isThinking = state is IslProcessingText;
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (ctx, _) {
        final pulse = _pulseCtrl.value;
        return Container(
          height: isThinking ? 40 : 60 + pulse * 30,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isThinking
                  ? [
                      Colors.blueAccent,
                      Colors.cyanAccent,
                      Colors.blue,
                      Colors.indigo,
                    ]
                  : [
                      Colors.redAccent,
                      Colors.blueAccent,
                      Colors.yellowAccent,
                      Colors.greenAccent,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.33, 0.66, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: (isThinking ? Colors.blue : Colors.white)
                    .withValues(alpha: 0.3 * pulse),
                blurRadius: 40 + pulse * 20,
                spreadRadius: 10 + pulse * 10,
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(50),
              topRight: Radius.circular(50),
            ),
          ),
        );
      },
    );
  }

  // ── Mic FAB ───────────────────────────────────────────────────────────────

  Widget _buildFab() {
    return BlocBuilder<IslBloc, IslState>(
      builder: (ctx, state) {
        final isListening = state is IslListening;
        final isProcessing = state is IslProcessingText;
        final isPlaying = state is IslPlayingSequence;

        if (isPlaying) return const SizedBox.shrink();

        Color bgColor;
        IconData icon;
        VoidCallback? onTap;

        if (isListening) {
          bgColor = Colors.redAccent;
          icon = Icons.stop_rounded;
          onTap = () => ctx.read<IslBloc>().add(const IslStopListening());
        } else if (isProcessing) {
          bgColor = const Color(0xFFFFD54F);
          icon = Icons.hourglass_top_rounded;
          onTap = null;
        } else if (state is IslSequenceDone) {
          return const SizedBox.shrink(); // handled by replay button
        } else if (state is IslError) {
          bgColor = const Color(0xFF6C63FF);
          icon = Icons.mic_rounded;
          onTap = () => ctx.read<IslBloc>().add(const IslStartListening());
        } else {
          // Idle
          bgColor = const Color(0xFF6C63FF);
          icon = Icons.mic_rounded;
          onTap = () => ctx.read<IslBloc>().add(const IslStartListening());
        }

        return AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context3, _) {
            final glow = isListening ? _pulseCtrl.value : 0.6;
            return GestureDetector(
              onTap: onTap,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  boxShadow: [
                    BoxShadow(
                      color: bgColor.withValues(alpha: glow * 0.6),
                      blurRadius: 20 + glow * 10,
                      spreadRadius: 4 + glow * 4,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
            );
          },
        );
      },
    );
  }
}
