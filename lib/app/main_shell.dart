import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:murmur/app/widgets/glass_nav_bar.dart';
import 'package:murmur/features/breathing/breathing_screen.dart';
import 'package:murmur/features/home/home_screen.dart';
import 'package:murmur/features/profile/profile_screen.dart';
import 'package:murmur/features/sounds/screens/sounds_screen.dart';
import 'package:murmur/l10n/app_localizations.dart';
import 'package:murmur/features/sounds/player/player_controller.dart';
import 'package:murmur/features/sounds/widgets/mini_player.dart';

/// Каркас приложения. IndexedStack, а не PageView: табы не пересоздаются
/// при переключении, поэтому переживут будущий плеер, который должен играть
/// независимо от того, где сейчас пользователь.
///
/// У каждого таба свой Navigator — иначе пуш внутри таба выкидывал бы
/// экран поверх бара. Модалки и полноэкранный плеер пойдут на root.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  static const _tabs = <Widget>[
    HomeScreen(),
    SoundsScreen(),
    BreathingScreen(),
    ProfileScreen(),
  ];

  List<GlassNavItem> _items(BuildContext context) => <GlassNavItem>[
        GlassNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: AppL10n.of(context).navHome),
        GlassNavItem(
            icon: Icons.volume_up_outlined,
            activeIcon: Icons.volume_up,
            label: AppL10n.of(context).navSounds),
        GlassNavItem(
            icon: Icons.air_outlined,
            activeIcon: Icons.air,
            label: AppL10n.of(context).navBreathing),
        GlassNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: AppL10n.of(context).navProfile),
      ];

  int _index = 0;
  bool _barCollapsed = false;

  final _navKeys =
      List.generate(_tabs.length, (_) => GlobalKey<NavigatorState>());
  final _scrollControllers =
      List.generate(_tabs.length, (_) => ScrollController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Мурчание слышно, только пока приложение на экране. Микс — всегда.
    ref
        .read(playerProvider.notifier)
        .setAppVisible(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final c in _scrollControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTabTap(int i) {
    if (_index != i) {
      setState(() {
        _index = i;
        _barCollapsed = false;
      });
      return;
    }

    // Повторный тап по активному табу: сначала выбираемся в его корень,
    // и только оттуда — наверх списка.
    final nav = _navKeys[i].currentState;
    if (nav != null && nav.canPop()) {
      nav.popUntil((r) => r.isFirst);
      return;
    }

    final c = _scrollControllers[i];
    // Больше одной позиции — значит к контроллеру прицепился ещё какой-то
    // скролл, и animateTo бросит. Молча ничего не делаем.
    if (c.hasClients && c.positions.length == 1 && c.offset > 0) {
      c.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _onBack(bool didPop) {
    if (didPop) return;

    final nav = _navKeys[_index].currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return;
    }
    if (_index != 0) {
      setState(() => _index = 0);
      return;
    }
    // Корень первого таба — дальше уходить некуда.
    if (Platform.isAndroid) SystemNavigator.pop();
  }

  /// Возвращает false: уведомление идёт дальше, мы только подслушиваем.
  bool _onScroll(UserScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    final collapse = switch (n.direction) {
      ScrollDirection.reverse => true,
      ScrollDirection.forward => false,
      ScrollDirection.idle => _barCollapsed,
    };
    // У самого верха бар всегда развёрнут, иначе залипает сжатым
    // после короткого рывка.
    final next = n.metrics.pixels <= 0 ? false : collapse;
    if (next != _barCollapsed) setState(() => _barCollapsed = next);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _onBack(didPop),
      child: Scaffold(
        // Без extendBody под баром будет пустой фон, и размывать ему нечего.
        extendBody: true,
        body: NotificationListener<UserScrollNotification>(
          onNotification: _onScroll,
          child: IndexedStack(
            index: _index,
            children: [
              for (var i = 0; i < _tabs.length; i++)
                PrimaryScrollController(
                  controller: _scrollControllers[i],
                  child: Navigator(
                    key: _navKeys[i],
                    onGenerateRoute: (settings) => MaterialPageRoute(
                      settings: settings,
                      builder: (_) => _tabs[i],
                    ),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: Builder(
          builder: (context) {
            final mix = ref.watch(playerProvider);
            return GlassNavBar(
              currentIndex: _index,
              onTap: _onTabTap,
              items: _items(context),
              collapsed: _barCollapsed,
              gradientAnimating: mix.playing,
              player: mix.isEmpty ? null : MiniPlayer(collapsed: _barCollapsed),
            );
          },
        ),
      ),
    );
  }
}
