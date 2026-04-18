import 'package:equatable/equatable.dart';
import '../../models/gloss_item.dart';

/// All events that can be dispatched to [IslBloc].
abstract class IslEvent extends Equatable {
  const IslEvent();

  @override
  List<Object?> get props => [];
}

/// User tapped mic — begin STT recording.
class IslStartListening extends IslEvent {
  const IslStartListening();
}

/// STT partial result — live text update while user is still speaking.
class IslLiveTextUpdated extends IslEvent {
  final String text;
  const IslLiveTextUpdated(this.text);

  @override
  List<Object?> get props => [text];
}

/// User manually stops mic (tap on red stop button).
class IslStopListening extends IslEvent {
  const IslStopListening();
}

/// Sent by n8n gloss flow — override auto-glossing if needed later.
class IslGlossesReceived extends IslEvent {
  final List<GlossItem> glosses;
  const IslGlossesReceived(this.glosses);

  @override
  List<Object?> get props => [glosses];
}

/// Three.js → Flutter: avatar started signing a specific gloss.
class IslSignStarted extends IslEvent {
  final int signIndex;
  const IslSignStarted(this.signIndex);

  @override
  List<Object?> get props => [signIndex];
}

/// Three.js → Flutter: avatar finished the entire sign sequence.
class IslSequenceCompleted extends IslEvent {
  const IslSequenceCompleted();
}

/// Reset back to idle.
class IslReset extends IslEvent {
  const IslReset();
}

/// Any pipeline error.
class IslErrorOccurred extends IslEvent {
  final String message;
  const IslErrorOccurred(this.message);

  @override
  List<Object?> get props => [message];
}
