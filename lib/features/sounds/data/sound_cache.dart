import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Кэш аудио на диске.
///
/// Свой, а не `LockCachingAudioSource` из just_audio: тот помечен
/// экспериментальным и на устройстве не завёлся — каждый запуск уходил
/// в поток, поэтому дорожка тормозила при каждом тапе.
///
/// Здесь всё прямолинейно: файл скачивается целиком, кладётся на диск
/// и дальше играется оттуда — мгновенно, офлайн и без трафика.
class SoundCache {
  static const int maxBytes = 300 * 1024 * 1024;

  Directory? _dir;

  Future<Directory> _cacheDir() async {
    final cached = _dir;
    if (cached != null) return cached;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/sounds');
    if (!await dir.exists()) await dir.create(recursive: true);
    _dir = dir;
    return dir;
  }

  File _fileFor(Directory dir, String soundId) =>
      File('${dir.path}/$soundId.m4a');

  /// Уже лежит на диске — играем сразу, без сети.
  Future<String?> cachedPath(String soundId) async {
    final file = _fileFor(await _cacheDir(), soundId);
    return await file.exists() ? file.path : null;
  }

  /// Скачивает во временный файл и переименовывает уже готовый.
  /// Так оборванная закачка не превращается в битый кэш, который
  /// потом играет секунду и замолкает.
  Future<String> download(String soundId, String url) async {
    final dir = await _cacheDir();
    final target = _fileFor(dir, soundId);
    if (await target.exists()) return target.path;

    final temp = File('${target.path}.part');
    final client = HttpClient();
    try {
      final response =
          await client.getUrl(Uri.parse(url)).then((r) => r.close());
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode} для $soundId');
      }
      await response.pipe(temp.openWrite());
      await temp.rename(target.path);
    } catch (_) {
      if (await temp.exists()) await temp.delete();
      rethrow;
    } finally {
      client.close();
    }
    unawaited(_trim());
    return target.path;
  }

  /// Держим кэш в пределах лимита: вытесняем самое старое по обращению.
  Future<void> _trim() async {
    try {
      final dir = await _cacheDir();
      final files = await dir
          .list()
          .where((e) => e is File && e.path.endsWith('.m4a'))
          .cast<File>()
          .toList();
      var total = 0;
      final stats = <MapEntry<File, FileStat>>[];
      for (final f in files) {
        final st = await f.stat();
        total += st.size;
        stats.add(MapEntry(f, st));
      }
      if (total <= maxBytes) return;
      stats.sort((a, b) => a.value.accessed.compareTo(b.value.accessed));
      for (final e in stats) {
        if (total <= maxBytes) break;
        total -= e.value.size;
        await e.key.delete();
      }
    } catch (e) {
      debugPrint('cache trim failed: $e');
    }
  }
}
