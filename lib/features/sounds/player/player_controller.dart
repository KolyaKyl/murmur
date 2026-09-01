import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:murmur/app/providers.dart';
import 'package:murmur/features/sounds/data/sounds_repository.dart';
import 'package:murmur/features/sounds/models/sound.dart';
import 'package:murmur/features/sounds/player/audio_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Одна дорожка микса.
@immutable
class MixLayer {
  const MixLayer({required this.sound, this.volume = 0.7});

  final Sound sound;
  final double volume;

  MixLayer copyWith({double? volume}) =>
      MixLayer(sound: sound, volume: volume ?? this.volume);
}

@immutable
class MixState {
  const MixState({
    this.layers = const [],
    this.playing = false,
    this.sleepAt,
    this.mixName,
    this.loading = false,
  });

  final List<MixLayer> layers;
  final bool playing;
  final DateTime? sleepAt;
  final String? mixName;
  final bool loading;

  bool get isEmpty => layers.isEmpty;
  bool get isFull => layers.length >= PlayerController.maxLayers;
  bool get isSingle => layers.length == 1;

  bool contains(String id) => layers.any((l) => l.sound.id == id);

  /// «Rain · Fireplace · Wind» — им подписан мини-плеер и экран блокировки.
  String get title => mixName ?? layers.map((l) => l.sound.title).join(' · ');

  Duration? get sleepLeft {
    final at = sleepAt;
    if (at == null) return null;
    final left = at.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  MixState copyWith({
    List<MixLayer>? layers,
    bool? playing,
    Object? sleepAt = _keep,
    Object? mixName = _keep,
    bool? loading,
  }) =>
      MixState(
        layers: layers ?? this.layers,
        playing: playing ?? this.playing,
        sleepAt: sleepAt == _keep ? this.sleepAt : sleepAt as DateTime?,
        mixName: mixName == _keep ? this.mixName : mixName as String?,
        loading: loading ?? this.loading,
      );

  static const _keep = Object();
}

/// Микшер на несколько дорожек плюс фоновое мурчание.
///
/// Каждая дорожка — свой плеер со своей громкостью. Мурчание — отдельный,
/// он звучит, только когда микс пуст и приложение на экране.
class PlayerController extends StateNotifier<MixState> {
  PlayerController(
    this._repo, {
    required MurmurAudioHandler handler,
    bool ambientEnabled = true,
  })  : _handler = handler,
        _ambientEnabled = ambientEnabled,
        super(const MixState()) {
    _start();
  }

  Future<void> _start() async {
    await _configureSession();
    // Кнопки с экрана блокировки приходят сюда и разводятся сразу
    // на все дорожки микса.
    _handler
      ..onPlayPressed = (() {
        if (!state.playing) togglePlay();
      })
      ..onPausePressed = (() {
        if (state.playing) togglePlay();
      })
      ..onStopPressed = clearMix;
    addListener((_) => _publishToSystem(), fireImmediately: false);
    // Плеер пуст — значит с первой секунды мурчит котик.
    await _syncAmbient();
  }

  static const int maxLayers = 3;
  static const String ambientAsset = 'assets/audio/purring_cat.m4a';
  static const Duration fade = Duration(milliseconds: 500);

  final SoundsRepository _repo;
  final MurmurAudioHandler _handler;

  /// Чтобы не дёргать систему на каждое движение ползунка громкости.
  String? _publishedSignature;
  String? _logoArtPath;

  final Map<String, AudioPlayer> _players = {};
  final AudioPlayer _ambient = AudioPlayer();

  Timer? _sleepTimer;
  bool _ambientEnabled;
  bool _appVisible = true;

  Future<void> _configureSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  // ---------- воспроизведение ----------

  /// Тап в библиотеке: микс заменяется целиком одной дорожкой.
  Future<void> playOnly(Sound sound) async {
    await _stopAll();
    state = state.copyWith(layers: [], mixName: null, loading: true);
    await _addPlayer(sound, 0.8);
    state = state.copyWith(
      layers: [MixLayer(sound: sound, volume: 0.8)],
      playing: true,
      loading: false,
      mixName: null,
    );
    unawaited(_repo.pushRecent(sound.id));
    await _syncAmbient();
  }

  /// Из полного плеера: дорожка добавляется к тем, что уже играют.
  Future<void> addLayer(Sound sound) async {
    if (state.isFull || state.contains(sound.id)) return;
    state = state.copyWith(loading: true);
    await _addPlayer(sound, 0.6);
    state = state.copyWith(
      layers: [...state.layers, MixLayer(sound: sound, volume: 0.6)],
      playing: true,
      loading: false,
      mixName: null,
    );
    unawaited(_repo.pushRecent(sound.id));
    await _syncAmbient();
  }

  Future<void> removeLayer(String soundId) async {
    final player = _players.remove(soundId);
    if (player != null) {
      await _fadeTo(player, 0);
      await player.dispose();
    }
    final layers = state.layers.where((l) => l.sound.id != soundId).toList();
    state = state.copyWith(
      layers: layers,
      playing: layers.isEmpty ? false : state.playing,
      mixName: null,
    );
    if (layers.isEmpty) setSleepTimer(null);
    await _syncAmbient();
  }

  Future<void> setVolume(String soundId, double volume) async {
    final v = volume.clamp(0.0, 1.0);
    await _players[soundId]?.setVolume(v);
    state = state.copyWith(
      layers: [
        for (final l in state.layers)
          l.sound.id == soundId ? l.copyWith(volume: v) : l
      ],
    );
  }

  Future<void> togglePlay() async {
    final next = !state.playing;
    state = state.copyWith(playing: next);
    for (final p in _players.values) {
      next ? unawaited(p.play()) : await p.pause();
    }
    // На паузе тишина полная: мурчание не подменяет собой микс.
    await _syncAmbient();
  }

  Future<void> playMix(List<Sound> sounds, Map<String, double> volumes,
      {String? name}) async {
    await _stopAll();
    state = state.copyWith(layers: [], loading: true);
    final layers = <MixLayer>[];
    for (final s in sounds.take(maxLayers)) {
      final v = volumes[s.id] ?? 0.7;
      await _addPlayer(s, v);
      layers.add(MixLayer(sound: s, volume: v));
      unawaited(_repo.pushRecent(s.id));
    }
    state = state.copyWith(
        layers: layers, playing: true, loading: false, mixName: name);
    await _syncAmbient();
  }

  /// Убрать всё из плеера: приходит по «стоп» с экрана блокировки.
  Future<void> clearMix() async {
    await _stopAll();
    state = state.copyWith(layers: [], playing: false, mixName: null);
    await _syncAmbient();
  }

  // ---------- витрина для системы ----------

  Future<void> _publishToSystem() async {
    final signature = '${state.title}|${state.playing}|${state.layers.length}';
    if (signature == _publishedSignature) return;
    _publishedSignature = signature;

    if (state.isEmpty) {
      _handler.clear();
      return;
    }
    // Публикуем сразу, без обложки: она может тянуться из сети,
    // а витрина должна появиться мгновенно.
    _handler.publish(
      title: state.title,
      subtitle: 'MurMur',
      playing: state.playing,
    );
    final art = await _artUri();
    if (!mounted || signature != _publishedSignature) return;
    _handler.publish(
      title: state.title,
      subtitle: 'MurMur',
      playing: state.playing,
      artUri: art,
    );
  }

  /// Одна дорожка — её обложка. Микс — логотип: своей картинки у микса нет.
  Future<Uri?> _artUri() async {
    try {
      if (state.isSingle) {
        final path = state.layers.first.sound.coverPath;
        if (path.isEmpty) return _logoUri();
        return Uri.parse(await _repo.resolveUrl(path));
      }
      return _logoUri();
    } catch (e) {
      debugPrint('artUri failed: $e');
      return null;
    }
  }

  /// Система умеет читать обложку только из файла или по ссылке,
  /// ассет ей не отдать — поэтому логотип один раз копируем во временную папку.
  Future<Uri?> _logoUri() async {
    final cached = _logoArtPath;
    if (cached != null) return Uri.file(cached);
    try {
      final bytes = await rootBundle.load('assets/logo/logo.png');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/murmur_art.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      _logoArtPath = file.path;
      return Uri.file(file.path);
    } catch (e) {
      debugPrint('logoUri failed: $e');
      return null;
    }
  }

  // ---------- таймер сна ----------

  void setSleepTimer(Duration? d) {
    _sleepTimer?.cancel();
    if (d == null) {
      state = state.copyWith(sleepAt: null);
      return;
    }
    state = state.copyWith(sleepAt: DateTime.now().add(d));
    _sleepTimer = Timer(d, () async {
      // Уводим громкость плавно, а не обрываем на полуслове.
      for (final p in _players.values) {
        await _fadeTo(p, 0, duration: const Duration(seconds: 20));
      }
      for (final p in _players.values) {
        await p.pause();
      }
      state = state.copyWith(playing: false, sleepAt: null);
      await _syncAmbient();
    });
  }

  // ---------- мурчание ----------

  Future<void> setAmbientEnabled(bool value) async {
    _ambientEnabled = value;
    await _syncAmbient();
  }

  /// Приложение ушло с экрана — мурчание замолкает. Микс продолжает играть.
  Future<void> setAppVisible(bool visible) async {
    _appVisible = visible;
    await _syncAmbient();
  }

  bool get _ambientShouldPlay =>
      _ambientEnabled && _appVisible && state.isEmpty;

  Future<void> _syncAmbient() async {
    try {
      if (_ambientShouldPlay) {
        if (_ambient.audioSource == null) {
          await _ambient.setAsset(ambientAsset);
          await _ambient.setLoopMode(LoopMode.one);
        }
        if (!_ambient.playing) {
          await _ambient.setVolume(0);
          unawaited(_ambient.play());
          await _fadeTo(_ambient, 0.5);
        }
      } else if (_ambient.playing) {
        await _fadeTo(_ambient, 0);
        await _ambient.pause();
      }
    } catch (e) {
      debugPrint('ambient failed: $e');
    }
  }

  // ---------- механика ----------

  Future<void> _addPlayer(Sound sound, double volume) async {
    final player = AudioPlayer();
    try {
      if (sound.bundled && sound.assetPath.isNotEmpty) {
        await player.setAsset(sound.assetPath);
      } else {
        final url = await _repo.resolveUrl(sound.audioPath);
        // LockCachingAudioSource кладёт файл на диск при первом
        // прослушивании — дальше играет офлайн и без трафика.
        // ignore: experimental_member_use
        await player.setAudioSource(LockCachingAudioSource(Uri.parse(url)));
      }
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(0);
      _players[sound.id] = player;
      unawaited(player.play());
      await _fadeTo(player, volume);
    } catch (e) {
      debugPrint('addPlayer(${sound.id}) failed: $e');
      await player.dispose();
      rethrow;
    }
  }

  Future<void> _stopAll() async {
    for (final p in _players.values) {
      await _fadeTo(p, 0);
      await p.dispose();
    }
    _players.clear();
    _sleepTimer?.cancel();
    state = state.copyWith(sleepAt: null);
  }

  /// Плавное изменение громкости: без него старт и стоп бьют по ушам.
  Future<void> _fadeTo(AudioPlayer player, double target,
      {Duration duration = fade}) async {
    const steps = 20;
    final from = player.volume;
    final stepDelay = duration ~/ steps;
    for (var i = 1; i <= steps; i++) {
      if (!mounted) return;
      await player.setVolume(from + (target - from) * i / steps);
      await Future<void>.delayed(stepDelay);
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    for (final p in _players.values) {
      p.dispose();
    }
    _ambient.dispose();
    super.dispose();
  }
}

final soundsRepositoryProvider = Provider((ref) => SoundsRepository());

final playerProvider = StateNotifierProvider<PlayerController, MixState>(
  (ref) => PlayerController(
    ref.read(soundsRepositoryProvider),
    handler: ref.read(audioHandlerProvider),
    ambientEnabled: ref.read(ambientEnabledProvider),
  ),
);
