import 'package:flutter/material.dart';

void showSuccessOverlay(BuildContext context, {bool isDeleted = false}) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).size.height * 0.5,
      left: MediaQuery.of(context).size.width * 0.5 - 50,
      right: MediaQuery.of(context).size.width * 0.5 - 50,
      child: _DoubleCheckIcon(isDeleted: isDeleted),
    ),
  );

  overlay.insert(overlayEntry);

  Future.delayed(const Duration(milliseconds: 1000), () {
    overlayEntry.remove();
  });
}

class _DoubleCheckIcon extends StatefulWidget {
  final bool isDeleted; // Добавляем параметр

  const _DoubleCheckIcon({this.isDeleted = false}); // Делаем необязательным

  @override
  State<_DoubleCheckIcon> createState() => _DoubleCheckIconState();
}

class _DoubleCheckIconState extends State<_DoubleCheckIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceDim,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
                color: Theme.of(context).colorScheme.surfaceBright,
                blurRadius: 8)
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: widget.isDeleted
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Deleted',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                    textScaler: TextScaler.linear(1.0),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.done_all,
                    color: Colors.green,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Saved',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                    textScaler: TextScaler.linear(1.0),
                  ),
                ],
              ),
      ),
    );
  }
}
