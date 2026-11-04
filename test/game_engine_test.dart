import 'dart:math';

import 'package:flutter_boilerplate/features/game/game_engine.dart';
import 'package:flutter_test/flutter_test.dart';

GameSession withBoard(List<int> board, {int score = 0, int best = 0}) =>
    GameSession(current: GameSnapshot(board, score), best: best);

void main() {
  test('new game begins with two tiles and round trips through storage', () {
    final session = GameSession.start(Random(1));
    expect(session.current.board.where((n) => n != 0).length, 2);
    expect(
      GameSession.restore(session.encode())!.current.board,
      session.current.board,
    );
    expect(GameSession.restore('{broken'), isNull);
    expect(
      GameSession.restore(
        '{"current":{"board":[],"score":0},"best":0,"wonAcknowledged":false}',
      ),
      isNull,
    );
  });

  test('each pair merges once per move, and scores both merges', () {
    final session = withBoard([2, 2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
    final result = session.move(Direction.left, Random(1));
    expect(result.changed, isTrue);
    expect(result.session.current.board.take(2).toList(), [4, 4]);
    expect(result.session.current.score, 8);
    expect(result.session.best, 8);
    expect(result.travels.length, 4);
    expect(result.session.previous!.board, session.current.board);
  });

  test('a new merge cannot merge again on the same move', () {
    final result = withBoard([
      2,
      2,
      4,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    ]).move(Direction.left, Random(2));
    expect(result.session.current.board.take(2).toList(), [4, 4]);
    expect(result.session.current.score, 4);
  });

  test('all four directions move tiles in the right direction', () {
    for (final direction in Direction.values) {
      final board = List<int>.filled(16, 0)..[5] = 2;
      final result = withBoard(board).move(direction, Random(1));
      final target = switch (direction) {
        Direction.up => 1,
        Direction.down => 13,
        Direction.left => 4,
        Direction.right => 7,
      };
      expect(result.travels.single.to, target);
      expect(result.session.current.board[target], 2);
    }
  });

  test('invalid move never spawns or replaces undo snapshot', () {
    final session = withBoard([2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
    final result = session.move(Direction.left, Random(1));
    expect(result.changed, isFalse);
    expect(identical(result.session, session), isTrue);
  });

  test('undo restores the board and score but keeps the record', () {
    final session = withBoard([
      2,
      2,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    ], score: 10);
    final moved = session.move(Direction.left, Random(1)).session;
    final restored = GameSession.restore(moved.encode())!.undo();
    expect(restored.current.board, session.current.board);
    expect(restored.current.score, 10);
    expect(restored.best, 14);
    expect(restored.previous, isNull);
  });

  test('game over only when no spaces or adjacent equal tiles exist', () {
    final full = [2, 4, 2, 4, 4, 2, 4, 2, 2, 4, 2, 4, 4, 2, 4, 2];
    expect(withBoard(full).isOver, isTrue);
    expect(withBoard([...full]..[0] = 0).isOver, isFalse);
    expect(withBoard([...full]..[0] = 4).isOver, isFalse);
  });
}
