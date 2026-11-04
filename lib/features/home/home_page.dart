import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_boilerplate/app/theme/app_theme.dart';
import 'package:flutter_boilerplate/core/storage/local_storage.dart';
import 'package:flutter_boilerplate/features/game/game_engine.dart';
import 'package:flutter_boilerplate/features/settings/settings_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

final externalLinkOpenerProvider = Provider<Future<bool> Function(Uri)>((ref) {
  return (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
});

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  static const routeName = 'home';
  static const routePath = '/';

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const _saveKey = 'game2048.session.v1';
  final _random = Random();
  final _focusNode = FocusNode();
  late GameSession _session;
  List<TileTravel>? _travel;
  int? _spawnedAt;
  double _dragX = 0, _dragY = 0;
  bool _dialogOpen = false;
  int _generation = 0;

  bool get _reducedMotion => MediaQuery.of(context).disableAnimations;

  @override
  void initState() {
    super.initState();
    _session = GameSession.start(_random);
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final encoded = await ref
        .read(sharedPreferencesAsyncProvider)
        .getString(_saveKey);
    final restored = GameSession.restore(encoded);
    if (restored == null || !mounted) return;
    setState(() => _session = restored);
  }

  @override
  void dispose() {
    _generation++;
    _focusNode.dispose();
    super.dispose();
  }

  void _save() {
    unawaited(
      ref
          .read(sharedPreferencesAsyncProvider)
          .setString(_saveKey, _session.encode()),
    );
  }

  Future<void> _move(Direction direction) async {
    if (_travel != null || _dialogOpen || _session.isOver) return;
    final result = _session.move(direction, _random);
    if (!result.changed) return;
    HapticFeedback.selectionClick();
    final generation = ++_generation;
    if (!_reducedMotion) {
      setState(() => _travel = result.travels);
      await Future<void>.delayed(GameTokens.slideDuration);
    }
    if (!mounted || generation != _generation) return;
    final wasWon = _session.hasWon;
    setState(() {
      _travel = null;
      _session = result.session;
      _spawnedAt = result.spawnedAt;
    });
    _save();
    if ((!wasWon && _session.hasWon && !_session.wonAcknowledged) ||
        _session.isOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && generation == _generation) _showResult();
      });
    }
  }

  Future<void> _openDeveloperWebsite() async {
    var opened = false;
    try {
      opened = await ref.read(externalLinkOpenerProvider)(
        Uri.parse('https://brodev.uz'),
      );
    } catch (_) {
      // A missing browser or platform error gets the same actionable message.
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't open brodev.uz. Try opening it in your browser.",
          ),
        ),
      );
    }
  }

  void _undo() {
    if (_travel != null || _dialogOpen || _session.previous == null) return;
    _generation++;
    setState(() {
      _session = _session.undo();
      _spawnedAt = null;
    });
    HapticFeedback.selectionClick();
    _save();
  }

  Future<void> _newGame() async {
    if (_travel != null || _dialogOpen) return;
    _dialogOpen = true;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a new game?'),
        content: const Text(
          'Your current game will be lost. Your best score will be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start new game'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _dialogOpen = false;
    if (confirm != true) return;
    _restart();
  }

  void _restart() {
    _generation++;
    setState(() {
      _session = GameSession.start(_random, best: _session.best);
      _travel = null;
      _spawnedAt = null;
    });
    _save();
    _focusNode.requestFocus();
  }

  Future<void> _showResult() async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    final won = _session.hasWon && !_session.wonAcknowledged;
    HapticFeedback.mediumImpact();
    final restart = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(won ? 'You reached 2048!' : 'No moves left'),
        content: Text(
          won
              ? 'Keep playing to beat your best score.'
              : 'There are no moves left. Start a new game to try again.',
        ),
        actions: [
          if (won)
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continue playing'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start new game'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _dialogOpen = false;
    if (restart == true) {
      _restart();
    } else if (won) {
      setState(() => _session = _session.acknowledgeWin());
      _save();
      _focusNode.requestFocus();
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final direction = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.keyW => Direction.up,
      LogicalKeyboardKey.arrowDown || LogicalKeyboardKey.keyS => Direction.down,
      LogicalKeyboardKey.arrowLeft || LogicalKeyboardKey.keyA => Direction.left,
      LogicalKeyboardKey.arrowRight ||
      LogicalKeyboardKey.keyD => Direction.right,
      _ => null,
    };
    if (direction == null) return KeyEventResult.ignored;
    _move(direction);
    return KeyEventResult.handled;
  }

  void _onDragEnd() {
    if (max(_dragX.abs(), _dragY.abs()) < 24) return;
    _move(
      _dragX.abs() > _dragY.abs()
          ? (_dragX > 0 ? Direction.right : Direction.left)
          : (_dragY > 0 ? Direction.down : Direction.up),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<GameColors>()!;
    final text = Theme.of(context).textTheme;
    final highest = _session.current.board.reduce(max);
    final target = highest < 2048 ? 2048 : highest * 2;

    return Scaffold(
      body: SafeArea(
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _onKey,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  GameTokens.pagePadding,
                  20,
                  GameTokens.pagePadding,
                  32,
                ),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.grid_view_rounded,
                          size: 23,
                          color: colors.onAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '2048',
                        style: text.titleMedium?.copyWith(
                          color: colors.ink,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Settings',
                        icon: Icon(
                          Icons.settings_outlined,
                          color: colors.muted,
                        ),
                        onPressed: () =>
                            context.goNamed(SettingsPage.routeName),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Small moves. Big wins.',
                    style: text.labelSmall?.copyWith(color: colors.accent),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '2048',
                    style: text.displayLarge?.copyWith(
                      color: colors.ink,
                      height: 1,
                    ),
                  ),
                  Text(
                    'Merge matching tiles.',
                    style: text.bodyMedium?.copyWith(color: colors.muted),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: _ScoreCard(
                          label: 'Score',
                          score: _session.current.score,
                          colors: colors,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ScoreCard(
                          label: 'Best',
                          score: _session.best,
                          colors: colors,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (_) {
                      _dragX = 0;
                      _dragY = 0;
                    },
                    onHorizontalDragUpdate: (details) {
                      _dragX += details.delta.dx;
                    },
                    onHorizontalDragEnd: (_) => _onDragEnd(),
                    onVerticalDragStart: (_) {
                      _dragX = 0;
                      _dragY = 0;
                    },
                    onVerticalDragUpdate: (details) {
                      _dragY += details.delta.dy;
                    },
                    onVerticalDragEnd: (_) => _onDragEnd(),
                    child: Semantics(
                      customSemanticsActions: {
                        const CustomSemanticsAction(label: 'Move left'): () =>
                            _move(Direction.left),
                        const CustomSemanticsAction(label: 'Move right'): () =>
                            _move(Direction.right),
                        const CustomSemanticsAction(label: 'Move up'): () =>
                            _move(Direction.up),
                        const CustomSemanticsAction(label: 'Move down'): () =>
                            _move(Direction.down),
                      },
                      label:
                          '2048 board. Score ${_session.current.score}. '
                          '${_session.current.board.asMap().entries.where((e) => e.value != 0).map((e) => 'Row ${e.key ~/ 4 + 1}, column ${e.key % 4 + 1}: ${e.value}').join(', ')}. '
                          'Swipe or use the arrow keys to move tiles.',
                      child: ExcludeSemantics(
                        child: _GameBoard(
                          board: _session.current.board,
                          travels: _travel,
                          spawnedAt: _spawnedAt,
                          reducedMotion: _reducedMotion,
                          colors: colors,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.undo_rounded,
                          label: 'Undo',
                          onPressed:
                              _session.previous == null || _travel != null
                              ? null
                              : _undo,
                          primary: false,
                          colors: colors,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.add_rounded,
                          label: 'New game',
                          onPressed: _travel != null ? null : _newGame,
                          primary: true,
                          colors: colors,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(
                        GameTokens.cardRadius,
                      ),
                      border: Border.all(color: colors.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_outlined,
                              size: 19,
                              color: colors.accent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Next goal',
                                overflow: TextOverflow.ellipsis,
                                style: text.labelSmall?.copyWith(
                                  color: colors.muted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$highest / $target',
                              style: text.bodyMedium?.copyWith(
                                color: colors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (highest / target).clamp(0, 1),
                            minHeight: 6,
                            backgroundColor: colors.outline,
                            color: colors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Combine matching tiles to reach 2048',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(color: colors.muted),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: _openDeveloperWebsite,
                      style: TextButton.styleFrom(
                        foregroundColor: colors.muted,
                        minimumSize: const Size(0, GameTokens.controlHeight),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Developed by Bro'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.label,
    required this.score,
    required this.colors,
  });
  final String label;
  final int score;
  final GameColors colors;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(GameTokens.cardRadius),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelSmall?.copyWith(color: colors.muted)),
          const SizedBox(height: 5),
          AnimatedSwitcher(
            duration: MediaQuery.of(context).disableAnimations
                ? Duration.zero
                : GameTokens.popDuration,
            child: Text(
              '$score',
              key: ValueKey(score),
              style: text.headlineMedium?.copyWith(color: colors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.primary,
    required this.colors,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final GameColors colors;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(
        Size(0, GameTokens.controlHeight),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: primary ? BorderSide.none : BorderSide(color: colors.outline),
        ),
      ),
    );
    return primary
        ? FilledButton.icon(
            style: style.copyWith(
              backgroundColor: WidgetStatePropertyAll(colors.accent),
              foregroundColor: WidgetStatePropertyAll(colors.onAccent),
            ),
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          )
        : OutlinedButton.icon(
            style: style.copyWith(
              foregroundColor: WidgetStatePropertyAll(colors.ink),
            ),
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          );
  }
}

class _GameBoard extends StatelessWidget {
  const _GameBoard({
    required this.board,
    required this.travels,
    required this.spawnedAt,
    required this.reducedMotion,
    required this.colors,
  });
  final List<int> board;
  final List<TileTravel>? travels;
  final int? spawnedAt;
  final bool reducedMotion;
  final GameColors colors;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cell =
              (constraints.maxWidth -
                  GameTokens.boardPadding * 2 -
                  GameTokens.gap * 3) /
              4;
          double position(int coordinate) =>
              GameTokens.boardPadding + coordinate * (cell + GameTokens.gap);
          Widget tile(int index, int value, {bool spawn = false}) => Positioned(
            left: position(index % 4),
            top: position(index ~/ 4),
            width: cell,
            height: cell,
            child: spawn && !reducedMotion
                ? TweenAnimationBuilder<double>(
                    key: ValueKey('spawn-$index-$value'),
                    tween: Tween(begin: 0, end: 1),
                    duration: GameTokens.popDuration,
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: _Tile(value: value),
                  )
                : _Tile(value: value),
          );
          final moving = travels;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: colors.board,
              borderRadius: BorderRadius.circular(GameTokens.boardRadius),
            ),
            child: Stack(
              children: [
                for (var i = 0; i < 16; i++)
                  Positioned(
                    left: position(i % 4),
                    top: position(i ~/ 4),
                    width: cell,
                    height: cell,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.slot,
                        borderRadius: BorderRadius.circular(
                          GameTokens.tileRadius,
                        ),
                      ),
                    ),
                  ),
                if (moving == null) ...[
                  for (var i = 0; i < 16; i++)
                    if (board[i] != 0) tile(i, board[i], spawn: i == spawnedAt),
                ] else
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: GameTokens.slideDuration,
                    curve: Curves.easeOutCubic,
                    builder: (context, progress, _) => Stack(
                      children: [
                        for (final travel in moving)
                          Positioned(
                            left:
                                position(travel.from % 4) +
                                (position(travel.to % 4) -
                                        position(travel.from % 4)) *
                                    progress,
                            top:
                                position(travel.from ~/ 4) +
                                (position(travel.to ~/ 4) -
                                        position(travel.from ~/ 4)) *
                                    progress,
                            width: cell,
                            height: cell,
                            child: _Tile(value: travel.value),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    final level = value.bitLength - 2;
    final color =
        GameTokens.tileColors[level.clamp(0, GameTokens.tileColors.length - 1)];
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(GameTokens.tileRadius),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '$value',
            style: TextStyle(
              color: GameTokens.tileInk,
              fontWeight: FontWeight.w900,
              fontSize: value < 128 ? 32 : 27,
              letterSpacing: -1.5,
            ),
          ),
        ),
      ),
    );
  }
}
