// ignore_for_file: avoid_print

import 'dart:io';
import 'package:chesskit/chesskit.dart';

void main(List<String> args) {
  Chess game = Chess.initial;
  print(game.board.toASCII());

  while (!game.isGameOver) {
    print('\n\nInput:');
    final String? moveStr = stdin.readLineSync();
    final Move? move = moveStr != null ? Move.fromUci(moveStr) : null;
    if (move != null && game.isLegal(move)) {
      game = game.playUnchecked(move) as Chess;
      print('\n${game.board.toASCII()}');
    } else {
      print('Bad input. Try again:');
    }
  }
  print("\n${game.outcome!}");
}
