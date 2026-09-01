/// Время в человеческом виде: «4:32», а для длинных итогов «1:07:20».
/// Минуты без секунд врут — практика на 5:04 показывалась как «5 мин».
String formatClock(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(sec)}' : '$m:${two(sec)}';
}
