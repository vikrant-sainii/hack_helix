import 'package:equatable/equatable.dart';
import '../../models/gloss_item.dart';

/// All events that can be dispatched to [IslBloc].
abstract class IslEvent extends Equatable {
  const IslEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered when user taps mic and starts speaking.
class IslStartListening extends IslEvent {
  const IslStartListening();
}

/// Triggered when STT produces a final transcript.
class IslTextReceived extends IslEvent {
  final String text;

  const IslTextReceived(this.text);

  @override
  List<Object?> get props => [text];
}

/// Triggered when n8n returns the gloss sequence (intermediate state).
class IslGlossesReceived extends IslEvent {
  final List<GlossItem> glosses;

  const IslGlossesReceived(this.glosses);

  @override
  List<Object?> get props => [glosses];
}

/// Triggered when the avatar starts playing a specific sign index.
class IslSignStarted extends IslEvent {
  final int signIndex;

  const IslSignStarted(this.signIndex);

  @override
  List<Object?> get props => [signIndex];
}

/// Triggered when the avatar finishes the entire sign sequence.
class IslSequenceCompleted extends IslEvent {
  const IslSequenceCompleted();
}

/// Triggered to reset back to idle state.
class IslReset extends IslEvent {
  const IslReset();
}

/// Triggered on any error in the pipeline.
class IslErrorOccurred extends IslEvent {
  final String message;

  const IslErrorOccurred(this.message);

  @override
  List<Object?> get props => [message];
}
