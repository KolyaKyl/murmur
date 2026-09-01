import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

/// Витрина для системы: экран блокировки, пункт управления, кнопка
/// на наушниках. Сам ничего не играет.
///
/// Так сделано намеренно. У микса три плеера, а медиа-сессия у системы одна —
/// значит сессией должен владеть не плеер, а отдельный объект, который
/// передаёт нажатия наверх, в контроллер микса.
class MurmurAudioHandler extends BaseAudioHandler {
  VoidCallback? onPlayPressed;
  VoidCallback? onPausePressed;
  VoidCallback? onStopPressed;

  @override
  Future<void> play() async => onPlayPressed?.call();

  @override
  Future<void> pause() async => onPausePressed?.call();

  @override
  Future<void> stop() async => onStopPressed?.call();

  /// Перемотки нет: у зацикленных звуков нет длительности.
  @override
  Future<void> seek(Duration position) async {}

  /// Что показать системе. [artUri] — ссылка на обложку дорожки
  /// или файл с логотипом, если играет микс.
  void publish({
    required String title,
    required String subtitle,
    required bool playing,
    Uri? artUri,
  }) {
    mediaItem.add(MediaItem(
      id: 'murmur-mix',
      title: title,
      artist: subtitle,
      artUri: artUri,
      // duration оставляем пустым — иначе система нарисует ползунок,
      // которому нечего показывать.
    ));
    playbackState.add(PlaybackState(
      controls: [playing ? MediaControl.pause : MediaControl.play],
      androidCompactActionIndices: const [0],
      processingState: AudioProcessingState.ready,
      playing: playing,
    ));
  }

  /// Плеер пуст — убираем себя с экрана блокировки. Мурчание сюда
  /// не попадает: оно живёт, только пока приложение открыто.
  void clear() {
    mediaItem.add(null);
    playbackState.add(PlaybackState(
      controls: const [],
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
  }
}
