import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/isl_repository.dart';
import 'isl_event.dart';
import 'isl_state.dart';

/// BLoC that manages the full ISL synthesis pipeline:
///
/// Flow:
/// [IslStartListening]    → [IslListening]
/// [IslTextReceived]      → [IslProcessingText] → calls n8n → [IslEnriching]
/// [IslGlossesReceived]   → [IslEnriching] → calls FastAPI → [IslPlayingSequence]
/// [IslSignStarted]       → [IslPlayingSequence] (updates currentIndex)
/// [IslSequenceCompleted] → [IslSequenceDone]
/// [IslReset]             → [IslIdle]
/// [IslErrorOccurred]     → [IslError]
class IslBloc extends Bloc<IslEvent, IslState> {
  final IslRepository _repository;

  IslBloc({required IslRepository repository})
      : _repository = repository,
        super(const IslIdle()) {
    on<IslStartListening>(_onStartListening);
    on<IslTextReceived>(_onTextReceived);
    on<IslGlossesReceived>(_onGlossesReceived);
    on<IslSignStarted>(_onSignStarted);
    on<IslSequenceCompleted>(_onSequenceCompleted);
    on<IslReset>(_onReset);
    on<IslErrorOccurred>(_onError);
  }

  void _onStartListening(
    IslStartListening event,
    Emitter<IslState> emit,
  ) {
    emit(const IslListening());
  }

  Future<void> _onTextReceived(
    IslTextReceived event,
    Emitter<IslState> emit,
  ) async {
    emit(IslProcessingText(event.text));
    try {
      // Step 1: text → n8n → glosses (duration in seconds)
      final glosses = await _repository.fetchGlosses(event.text);
      if (glosses.isEmpty) {
        emit(const IslError('No ISL glosses found for the given text.'));
        return;
      }
      // Step 2: glosses → FastAPI → enriched signs (duration in ms)
      emit(IslEnriching(glosses));
      final signs = await _repository.enrichGlosses(glosses);
      if (signs.isEmpty) {
        emit(const IslError('Failed to enrich glosses from Supabase.'));
        return;
      }
      // Ready to play — UI will call window.playSequence(json) on WebView
      emit(IslPlayingSequence(signs: signs, currentIndex: 0));
    } catch (e) {
      emit(IslError(e.toString()));
    }
  }

  void _onGlossesReceived(
    IslGlossesReceived event,
    Emitter<IslState> emit,
  ) async {
    emit(IslEnriching(event.glosses));
    try {
      final signs = await _repository.enrichGlosses(event.glosses);
      emit(IslPlayingSequence(signs: signs, currentIndex: 0));
    } catch (e) {
      emit(IslError(e.toString()));
    }
  }

  void _onSignStarted(
    IslSignStarted event,
    Emitter<IslState> emit,
  ) {
    final current = state;
    if (current is IslPlayingSequence) {
      emit(IslPlayingSequence(
        signs: current.signs,
        currentIndex: event.signIndex,
      ));
    }
  }

  void _onSequenceCompleted(
    IslSequenceCompleted event,
    Emitter<IslState> emit,
  ) {
    final current = state;
    if (current is IslPlayingSequence) {
      emit(IslSequenceDone(current.signs));
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
    _repository.dispose();
    return super.close();
  }
}
