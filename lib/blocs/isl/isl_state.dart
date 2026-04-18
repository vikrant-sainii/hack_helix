import 'package:equatable/equatable.dart';
import '../../models/enriched_sign.dart';
import '../../models/gloss_item.dart';

abstract class IslState extends Equatable {
  const IslState();

  @override
  List<Object?> get props => [];
}

/// Waiting for user input — avatar plays idle animation.
class IslIdle extends IslState {
  const IslIdle();
}

/// Microphone is open, STT is recording.
/// [liveText] updates in real-time as user speaks.
class IslListening extends IslState {
  final String liveText;
  const IslListening({this.liveText = ''});

  @override
  List<Object?> get props => [liveText];
}

/// STT finished, fetching enriched signs from FastAPI/dummy data.
class IslProcessingText extends IslState {
  final String spokenText;
  const IslProcessingText(this.spokenText);

  @override
  List<Object?> get props => [spokenText];
}

/// n8n returned glosses, now enriching via FastAPI.
class IslEnriching extends IslState {
  final List<GlossItem> glosses;
  final String spokenText;
  const IslEnriching({required this.glosses, required this.spokenText});

  @override
  List<Object?> get props => [glosses, spokenText];
}

/// Avatar is actively signing the gloss sequence.
/// [spokenText] = what the user originally said (shown on screen).
/// [currentIndex] = which sign is being signed right now.
class IslPlayingSequence extends IslState {
  final List<EnrichedSign> signs;
  final int currentIndex;
  final String spokenText;

  const IslPlayingSequence({
    required this.signs,
    required this.currentIndex,
    required this.spokenText,
  });

  EnrichedSign get currentSign => signs[currentIndex];

  @override
  List<Object?> get props => [signs, currentIndex, spokenText];
}

/// Avatar finished the entire sequence.
class IslSequenceDone extends IslState {
  final List<EnrichedSign> signs;
  final String spokenText;

  const IslSequenceDone({required this.signs, required this.spokenText});

  @override
  List<Object?> get props => [signs, spokenText];
}

/// Pipeline error.
class IslError extends IslState {
  final String message;
  const IslError(this.message);

  @override
  List<Object?> get props => [message];
}
