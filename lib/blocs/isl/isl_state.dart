import 'package:equatable/equatable.dart';
import '../../models/enriched_sign.dart';
import '../../models/gloss_item.dart';

/// All possible states of [IslBloc].
abstract class IslState extends Equatable {
  const IslState();

  @override
  List<Object?> get props => [];
}

/// Initial state — avatar is idle, waiting for user input.
class IslIdle extends IslState {
  const IslIdle();
}

/// Microphone is open, STT is recording.
class IslListening extends IslState {
  const IslListening();
}

/// STT produced text, sending to n8n for gloss conversion.
class IslProcessingText extends IslState {
  final String text;

  const IslProcessingText(this.text);

  @override
  List<Object?> get props => [text];
}

/// n8n returned glosses, now enriching via FastAPI.
class IslEnriching extends IslState {
  final List<GlossItem> glosses;

  const IslEnriching(this.glosses);

  @override
  List<Object?> get props => [glosses];
}

/// FastAPI returned enriched signs — avatar is playing the sequence.
class IslPlayingSequence extends IslState {
  final List<EnrichedSign> signs;
  final int currentIndex; // which sign is currently being shown

  const IslPlayingSequence({
    required this.signs,
    required this.currentIndex,
  });

  EnrichedSign get currentSign => signs[currentIndex];

  @override
  List<Object?> get props => [signs, currentIndex];
}

/// Avatar finished the entire sequence — showing completion.
class IslSequenceDone extends IslState {
  final List<EnrichedSign> signs;

  const IslSequenceDone(this.signs);

  @override
  List<Object?> get props => [signs];
}

/// Something went wrong in the pipeline.
class IslError extends IslState {
  final String message;

  const IslError(this.message);

  @override
  List<Object?> get props => [message];
}
