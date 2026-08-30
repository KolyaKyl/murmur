import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:murmur/core/theme/app_theme.dart';

class GlassNavItem {
  const GlassNavItem({
    required this.label,
    this.icon,
    this.activeIcon,
    this.imagePath,
  }) : assert(icon != null || imagePath != null,
            'Нужна либо иконка, либо картинка');

  final IconData? icon;
  final IconData? activeIcon;

  /// Ассет вместо иконки — для таба с логотипом приложения.
  final String? imagePath;

  final String label;
}

/// Плавающая стеклянная пилюля. В SDK встроенного стекла нет, поэтому
/// собрано вручную: подложка размывает то, что скроллится под ней.
/// Работает только если у Scaffold стоит extendBody: true, иначе под баром
/// пустой фон и размывать нечего — стекло выглядит мутным пластиком.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.collapsed = false,
  });

  static const double height = 62;
  static const double collapsedHeight = 46;
  static const double sideInset = 16;
  static const double bottomInset = 4;
  static const Duration animation = Duration(milliseconds: 220);

  /// Указатель и область нажатия строятся по одним и тем же отступам,
  /// иначе всплеск получается крупнее подложки и они не совпадают.
  static const double _slotInsetH = AppSpacing.sm;
  static const double _slotInsetV = 5;

  /// Сколько места нужно оставить снизу в любом скролле таба,
  /// чтобы последний элемент не оказался под баром.
  static double contentInset(BuildContext context) =>
      height +
      bottomInset +
      MediaQuery.paddingOf(context).bottom +
      AppSpacing.md;

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;

  /// Скроллят вниз — бар ужимается: подписи прячутся, высота падает.
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        sideInset,
        0,
        sideInset,
        bottomInset + MediaQuery.paddingOf(context).bottom,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: AnimatedContainer(
            duration: animation,
            curve: Curves.easeOut,
            height: collapsed ? collapsedHeight : height,
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: isDark ? 0.14 : 0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / items.length;
                return Stack(
                  children: [
                    // Указатель едет под пальцем, а не перерисовывается
                    // на новом месте.
                    AnimatedPositioned(
                      duration: animation,
                      curve: Curves.easeOutCubic,
                      left: itemWidth * currentIndex,
                      top: _slotInsetV,
                      bottom: _slotInsetV,
                      width: itemWidth,
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: _slotInsetH),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            // Нейтральный тон, без акцента: подложка
                            // высветляет стекло, а не красит его.
                            color: scheme.onSurface
                                .withValues(alpha: isDark ? 0.12 : 0.07),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),
                    // Positioned.fill обязателен: без него Row в Stack
                    // получает свободные ограничения, схлопывается по высоте
                    // и прижимается к верху бара.
                    Positioned.fill(
                      child: Row(
                        children: [
                          for (var i = 0; i < items.length; i++)
                            SizedBox(
                              width: itemWidth,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: _slotInsetH,
                                  vertical: _slotInsetV,
                                ),
                                child: _NavButton(
                                  item: items[i],
                                  selected: i == currentIndex,
                                  collapsed: collapsed,
                                  onTap: () => onTap(i),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final GlassNavItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.onSurface : scheme.onSurfaceVariant;

    // GestureDetector, а не InkWell: подсветка нажатия спорила с бегунком.
    // opaque — чтобы ловились тапы по пустому месту ячейки, а не только
    // по иконке с подписью.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Glyph(item: item, selected: selected, color: color),
            // AnimatedAlign с heightFactor схлопывает подпись без переполнения:
            // высота едет к нулю, а не текст ужимается в остаток.
            ClipRect(
              child: AnimatedAlign(
                duration: GlassNavBar.animation,
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                heightFactor: collapsed ? 0 : 1,
                child: AnimatedOpacity(
                  duration: GlassNavBar.animation,
                  opacity: collapsed ? 0 : 1,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                      maxLines: 1,
                      textScaler: const TextScaler.linear(1.0),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glyph extends StatelessWidget {
  const _Glyph({
    required this.item,
    required this.selected,
    required this.color,
  });

  static const double size = 24;

  final GlassNavItem item;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final path = item.imagePath;
    if (path == null) {
      return Icon(
        selected ? (item.activeIcon ?? item.icon) : item.icon,
        color: color,
        size: size,
      );
    }
    // Логотип не перекрашиваем — он цветной по смыслу.
    // Неактивное состояние показываем приглушением.
    return AnimatedOpacity(
      duration: GlassNavBar.animation,
      opacity: selected ? 1 : 0.5,
      child: ClipOval(
        child: Image.asset(path, width: size, height: size, fit: BoxFit.cover),
      ),
    );
  }
}
