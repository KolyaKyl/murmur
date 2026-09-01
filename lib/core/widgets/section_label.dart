import 'package:flutter/material.dart';
import 'package:murmur/core/theme/app_theme.dart';

/// Лейбл, который отделяет блок в основной области экрана.
///
/// Всегда с отступом слева: прижатый к краю он читается как часть карточки
/// под ним, а не как заголовок над ней. Отступ задан здесь один раз,
/// чтобы экраны не разъезжались.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  /// Сверх отступа, который уже даёт контейнер контента.
  static const double inset = AppSpacing.sm;

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final label = Text(text, style: Theme.of(context).textTheme.bodyLarge);
    return Padding(
      padding: const EdgeInsets.fromLTRB(inset, 0, inset, AppSpacing.xs + 2),
      child: trailing == null
          ? Align(alignment: Alignment.centerLeft, child: label)
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [label, trailing!],
            ),
    );
  }
}
