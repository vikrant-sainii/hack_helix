import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../models/enriched_sign.dart';
import '../../repositories/isl_repository.dart';
import 'isl_event.dart';
import 'isl_state.dart';

/// Internal event — not part of public API.
/// Dispatched internally when STT finishes (silence or failsafe).
class _IslSpeechFinished extends IslEvent {
  final String text;
  const _IslSpeechFinished(this.text);

  @override
  List<Object?> get props => [text];
}

/// BLoC that drives the full ISL synthesis pipeline:
///
/// Tap mic
///   → [IslStartListening] → [IslListening] (live STT text)
///   → silence detected (1500ms) or failsafe (10s)
///   → [_IslSpeechFinished] → [IslProcessingText]
///   → dummy enriched signs loaded → [IslPlayingSequence]
///   → Three.js avatar signs gloss by gloss → [IslSignStarted] per sign
///   → all done → [IslSequenceCompleted] → [IslSequenceDone]
///   → [IslReset] → [IslIdle]
class IslBloc extends Bloc<IslEvent, IslState> {
  final IslRepository _repository;

  // ── STT ──────────────────────────────────────────────────────────────────
  final stt.SpeechToText _speech = stt.SpeechToText();
  Timer? _silenceTimer;  // 1.5s rolling silence detection
  Timer? _failsafeTimer; // 10s absolute cutoff
  String _capturedText = '';

  IslBloc({required IslRepository repository})
      : _repository = repository,
        super(const IslIdle()) {
    on<IslStartListening>(_onStartListening);
    on<IslLiveTextUpdated>(_onLiveTextUpdated);
    on<IslStopListening>(_onStopListening);
    on<_IslSpeechFinished>(_onSpeechFinished);
    on<IslSignStarted>(_onSignStarted);
    on<IslSequenceCompleted>(_onSequenceCompleted);
    on<IslReset>(_onReset);
    on<IslErrorOccurred>(_onError);
  }

  // ── STT: Start ────────────────────────────────────────────────────────────

  Future<void> _onStartListening(
    IslStartListening event,
    Emitter<IslState> emit,
  ) async {
    developer.log('IslBloc: _onStartListening');
    _capturedText = '';
    _silenceTimer?.cancel();
    _failsafeTimer?.cancel();

    // Ding to signal start (same pattern as CrisisMatch VoiceAssistant)
    SystemSound.play(SystemSoundType.click);
    emit(const IslListening());

    // Initialize STT if not available
    if (!_speech.isAvailable) {
      final available = await _speech.initialize(
        onStatus: (s) => developer.log('IslBloc: STT status: $s'),
        onError: (e) => developer.log('IslBloc: STT error: ${e.errorMsg}'),
      );
      if (!available) {
        emit(const IslError(
            'Microphone permission denied. Please allow mic access in settings.'));
        return;
      }
    }

    _speech.listen(
      onResult: (result) {
        _capturedText = result.recognizedWords;
        developer.log('IslBloc: Capturing: "$_capturedText"');

        // Push live text to UI
        if (!isClosed) add(IslLiveTextUpdated(_capturedText));

        // Rolling 1.5-second silence detection
        _silenceTimer?.cancel();
        _silenceTimer = Timer(const Duration(milliseconds: 1500), () {
          _endListening();
        });
      },
      listenFor: const Duration(seconds: 30),
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
      ),
    );

    // 10-second absolute failsafe
    _failsafeTimer = Timer(const Duration(seconds: 10), () {
      _endListening();
    });
  }

  // ── STT: User taps stop manually ─────────────────────────────────────────

  void _onStopListening(IslStopListening event, Emitter<IslState> emit) {
    _endListening();
  }

  // ── STT: Internal — called by timers ─────────────────────────────────────

  void _endListening() {
    _silenceTimer?.cancel();
    _failsafeTimer?.cancel();

    try {
      _speech.stop();
    } catch (_) {}

    SystemSound.play(SystemSoundType.click);

    final text = _capturedText.trim();
    developer.log('IslBloc: Final captured: "$text"');
    if (!isClosed) add(_IslSpeechFinished(text));
  }

  // ── STT: Live text update ─────────────────────────────────────────────────

  void _onLiveTextUpdated(IslLiveTextUpdated event, Emitter<IslState> emit) {
    emit(IslListening(liveText: event.text));
  }

  // ── STT → Enrich → Play ───────────────────────────────────────────────────

  Future<void> _onSpeechFinished(
    _IslSpeechFinished event,
    Emitter<IslState> emit,
  ) async {
    // Use what was captured, or default to a demo phrase
    final spokenText =
        event.text.isNotEmpty ? event.text : 'ISL Demo — LIFE MY DANGER';

    emit(IslProcessingText(spokenText));

    // Brief artificial delay to show "Processing..." state
    await Future.delayed(const Duration(milliseconds: 600));

    final List<EnrichedSign> signs;
    try {
      signs = await _repository.processText(spokenText);
      if (signs.isEmpty) {
        emit(const IslError('No signs found for this text.'));
        return;
      }
    } catch (e) {
      developer.log('IslBloc: Error fetching signs: $e');
      emit(IslError('Failed to connect to ISL backend: $e'));
      return;
    }

    emit(IslPlayingSequence(
      signs: signs,
      currentIndex: 0,
      spokenText: spokenText,
    ));
  }

  // ── Avatar playback events from Three.js ──────────────────────────────────

  void _onSignStarted(IslSignStarted event, Emitter<IslState> emit) {
    final current = state;
    if (current is IslPlayingSequence) {
      emit(IslPlayingSequence(
        signs: current.signs,
        currentIndex: event.signIndex,
        spokenText: current.spokenText,
      ));
    }
  }

  void _onSequenceCompleted(
      IslSequenceCompleted event, Emitter<IslState> emit) {
    final current = state;
    if (current is IslPlayingSequence) {
      emit(IslSequenceDone(
        signs: current.signs,
        spokenText: current.spokenText,
      ));
    }
  }

  void _onReset(IslReset event, Emitter<IslState> emit) {
    emit(const IslIdle());
  }

  void _onError(IslErrorOccurred event, Emitter<IslState> emit) {
    emit(IslError(event.message));
  }


  @override
  Future<void> close() {
    _silenceTimer?.cancel();
    _failsafeTimer?.cancel();
    try {
      _speech.stop();
    } catch (_) {}
    _repository.dispose();
    return super.close();
  }
}
