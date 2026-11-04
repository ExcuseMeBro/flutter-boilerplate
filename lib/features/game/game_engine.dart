import 'dart:convert';
import 'dart:math';

enum Direction { up, down, left, right }

class TileTravel {
  const TileTravel(this.from, this.to, this.value);
  final int from;
  final int to;
  final int value;
}

class GameSnapshot {
  GameSnapshot(List<int> board, this.score) : board = List.unmodifiable(board);
  final List<int> board;
  final int score;

  Map<String, Object> toJson() => {'board': board, 'score': score};

  static GameSnapshot? fromJson(Object? value) {
    if (value is! Map) return null;
    final cells = value['board'];
    final score = value['score'];
    if (cells is! List ||
        cells.length != 16 ||
        score is! int ||
        score < 0 ||
        cells.any(
          (cell) =>
              cell is! int ||
              cell < 0 ||
              (cell != 0 && (cell < 2 || (cell & (cell - 1)) != 0)),
        )) {
      return null;
    }
    return GameSnapshot(cells.cast<int>(), score);
  }
}

class GameSession {
  GameSession({
    required this.current,
    required this.best,
    this.previous,
    this.wonAcknowledged = false,
  });

  final GameSnapshot current;
  final int best;
  final GameSnapshot? previous;
  final bool wonAcknowledged;

  bool get hasWon => current.board.any((value) => value >= 2048);
  bool get isOver {
    final board = current.board;
    for (var i = 0; i < 16; i++) {
      if (board[i] == 0 ||
          (i % 4 != 3 && board[i] == board[i + 1]) ||
          (i < 12 && board[i] == board[i + 4])) {
        return false;
      }
    }
    return true;
  }

  static GameSession start(Random random, {int best = 0}) {
    final board = List<int>.filled(16, 0);
    _spawn(board, random);
    _spawn(board, random);
    return GameSession(current: GameSnapshot(board, 0), best: best);
  }

  static GameSession? restore(String? raw) {
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is! Map) return null;
      final current = GameSnapshot.fromJson(data['current']);
      final previous = data['previous'] == null
          ? null
          : GameSnapshot.fromJson(data['previous']);
      final best = data['best'];
      final acknowledged = data['wonAcknowledged'];
      if (current == null ||
          (data['previous'] != null && previous == null) ||
          best is! int ||
          best < 0 ||
          acknowledged is! bool) {
        return null;
      }
      return GameSession(
        current: current,
        previous: previous,
        best: max(best, current.score),
        wonAcknowledged: acknowledged,
      );
    } catch (_) {
      return null;
    }
  }

  String encode() => jsonEncode({
    'current': current.toJson(),
    'previous': previous?.toJson(),
    'best': best,
    'wonAcknowledged': wonAcknowledged,
  });

  GameSession acknowledgeWin() => GameSession(
    current: current,
    previous: previous,
    best: best,
    wonAcknowledged: true,
  );

  GameSession undo() => previous == null
      ? this
      : GameSession(
          current: previous!,
          best: best,
          wonAcknowledged: wonAcknowledged,
        );

  MoveResult move(Direction direction, Random random) {
    final board = List<int>.filled(16, 0);
    final travels = <TileTravel>[];
    var points = 0;
    for (var line = 0; line < 4; line++) {
      final positions = List.generate(4, (step) {
        switch (direction) {
          case Direction.left:
            return line * 4 + step;
          case Direction.right:
            return line * 4 + 3 - step;
          case Direction.up:
            return step * 4 + line;
          case Direction.down:
            return (3 - step) * 4 + line;
        }
      });
      final occupied = positions
          .where((index) => current.board[index] != 0)
          .toList();
      var target = 0;
      for (var i = 0; i < occupied.length; i++) {
        final from = occupied[i];
        final value = current.board[from];
        final to = positions[target++];
        travels.add(TileTravel(from, to, value));
        if (i + 1 < occupied.length &&
            current.board[occupied[i + 1]] == value) {
          travels.add(TileTravel(occupied[++i], to, value));
          board[to] = value * 2;
          points += value * 2;
        } else {
          board[to] = value;
        }
      }
    }
    if (_sameBoard(board, current.board)) {
      return MoveResult(this, const [], null);
    }
    final spawnedAt = _spawn(board, random);
    final score = current.score + points;
    return MoveResult(
      GameSession(
        current: GameSnapshot(board, score),
        previous: current,
        best: max(best, score),
        wonAcknowledged: wonAcknowledged,
      ),
      travels,
      spawnedAt,
    );
  }

  static bool _sameBoard(List<int> a, List<int> b) {
    for (var i = 0; i < 16; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static int? _spawn(List<int> board, Random random) {
    final empty = [
      for (var i = 0; i < 16; i++)
        if (board[i] == 0) i,
    ];
    if (empty.isEmpty) return null;
    final index = empty[random.nextInt(empty.length)];
    board[index] = random.nextDouble() < .9 ? 2 : 4;
    return index;
  }
}

class MoveResult {
  const MoveResult(this.session, this.travels, this.spawnedAt);
  final GameSession session;
  final List<TileTravel> travels;
  final int? spawnedAt;
  bool get changed => travels.isNotEmpty;
}
