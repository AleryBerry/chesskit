import 'dart:convert';

import 'package:nicochess/nicochess.dart';
import 'package:test/test.dart';

List<Move> _parseMoveFromMapList(List<Map<String, String?>> rawMoves) {
  return rawMoves.map(_parseMoveFromMap).toList();
}

Move _parseMoveFromMap(Map<String, String?> rawMove) {
  return Move(
    to: rawMove['to']!.toChessSquare(),
    from: rawMove['from']!.toChessSquare(),
    color: PieceColor.fromChar(rawMove['color']!),
    piece: rawMove['piece']!.toChessPieceSymbol(),
    san: rawMove['san']!,
    flags: rawMove['flags']
            ?.split('')
            .map((String e) => Flag.fromNotation(e)!)
            .toList() ??
        <Flag>[],
    captured: rawMove['captured'] != null
        ? PieceSymbol.fromChar(rawMove['captured']!)
        : null,
    promotion: rawMove['promotion'] != null
        ? PieceSymbol.fromChar(rawMove['promotion']!)
        : null,
  );
}

void main() {
  group('Checkmate', () {
    test('If recognizes a checkmate position', () {
      final Chess chess = Chess.create();

      const List<String> checkmates = <String>[
        '8/5r2/4K1q1/4p3/3k4/8/8/8 w - - 0 7',
        '4r2r/p6p/1pnN2p1/kQp5/3pPq2/3P4/PPP3PP/R5K1 b - - 0 2',
        'r3k2r/ppp2p1p/2n1p1p1/8/2B2P1q/2NPb1n1/PP4PP/R2Q3K w kq - 0 8',
        '8/6R1/pp1r3p/6p1/P3R1Pk/1P4P1/7K/8 b - - 0 4',
      ];

      for (final String checkmate in checkmates) {
        chess.load(checkmate);
        expect(chess.inCheckmate(), isTrue);
      }
    });
  });
  group('Stalemate', () {
    test('If recognizes a stalemate position', () {
      const List<String> stalemates = <String>[
        '1R6/8/8/8/8/8/7R/k6K b - - 0 1',
        '8/8/5k2/p4p1p/P4K1P/1r6/8/8 w - - 0 2',
      ];

      for (final String stalemate in stalemates) {
        final Chess chess = Chess.create();
        chess.load(stalemate);

        expect(chess.inStalemate(), isTrue);
      }
    });
  });
  group('Insufficient Material', () {
    test('If recognizes a position with no sufficient material', () {
      const List<Map<String, dynamic>> positions = <Map<String, dynamic>>[
        <String, dynamic>{
          'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
          'draw': false,
        },
        <String, dynamic>{
          'fen': '8/8/8/8/8/8/8/k6K w - - 0 1',
          'draw': true,
        },
        <String, dynamic>{
          'fen': '8/2p5/8/8/8/8/8/k6K w - - 0 1',
          'draw': false,
        },
        <String, dynamic>{
          'fen': '8/2N5/8/8/8/8/8/k6K w - - 0 1',
          'draw': true,
        },
        <String, dynamic>{
          'fen': '8/2b5/8/8/8/8/8/k6K w - - 0 1',
          'draw': true,
        },
        <String, dynamic>{
          'fen': '8/b7/3B4/8/8/8/8/k6K w - - 0 1',
          'draw': true,
        },
        <String, dynamic>{
          'fen': '8/b7/B7/8/8/8/8/k6K w - - 0 1',
          'draw': false,
        },
        <String, dynamic>{
          'fen': '8/b1B1b1B1/1b1B1b1B/8/8/8/8/1k5K w - - 0 1',
          'draw': true,
        },
        <String, dynamic>{
          'fen': '8/bB2b1B1/1b1B1b1B/8/8/8/8/1k5K w - - 0 1',
          'draw': false,
        },
        <String, dynamic>{
          'fen': kDefaultPosition,
          'draw': false,
        },
      ];

      for (final Map<String, dynamic> position in positions) {
        final Chess chess = Chess.create();
        chess.load(position['fen'] as String);

        if (position['draw'] as bool) {
          expect(chess.insufficientMaterial() && chess.inDraw(), isTrue);
        } else {
          expect(!chess.insufficientMaterial() && !chess.inDraw(), isTrue);
        }
      }
    });
  });
  group('Threefold Repetition', () {
    test('If recognizes a position with Threefold Repetition', () {
      const List<Map<String, dynamic>> positions = <Map<String, dynamic>>[
        <String, dynamic>{
          'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
          'moves': <String>[
            'Nf3',
            'Nf6',
            'Ng1',
            'Ng8',
            'Nf3',
            'Nf6',
            'Ng1',
            'Ng8'
          ],
        },
        // Fischer - Petrosian, Buenos Aires, 1971
        <String, dynamic>{
          'fen': '8/pp3p1k/2p2q1p/3r1P2/5R2/7P/P1P1QP2/7K b - - 2 30',
          'moves': <String>[
            'Qe5',
            'Qh5',
            'Qf6',
            'Qe2',
            'Re5',
            'Qd3',
            'Rd5',
            'Qe2',
          ],
        },
      ];

      for (final Map<String, dynamic> position in positions) {
        final Chess chess = Chess.create();
        chess.load(position['fen'] as String);

        for (final String move in position['moves'] as List<String>) {
          expect(chess.inThreefoldRepetition(), isFalse);
          chess.move(san: move);
        }

        expect(chess.inThreefoldRepetition(), isTrue);
        expect(chess.inDraw(), isTrue);
      }
    });
  });
  test('Perft', () {
    final List<Map<String, dynamic>> perfts = <Map<String, dynamic>>[
      <String, dynamic>{
        'fen':
            'r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1',
        'depth': 3,
        'nodes': 97862,
      },
      <String, dynamic>{
        'fen': '8/PPP4k/8/8/8/8/4Kppp/8 w - - 0 1',
        'depth': 4,
        'nodes': 89363,
      },
      <String, dynamic>{
        'fen': '8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1',
        'depth': 4,
        'nodes': 43238,
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/p3pppp/2p5/1pPp4/3P4/8/PP2PPPP/RNBQKBNR w KQkq b6 0 4',
        'depth': 3,
        'nodes': 23509,
      },
    ];

    for (final Map<String, dynamic> perft in perfts) {
      final Chess chess = Chess.create();
      chess.load(perft['fen'] as String);

      final int nodes = chess.perft(perft['depth'] as int);

      expect(nodes, perft['nodes']);
    }
  });
  group('Single Square Move Generation', () {
    test('san', () {
      final List<Map<String, dynamic>> positions = <Map<String, dynamic>>[
        <String, dynamic>{
          'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
          'square': 'e2',
          'verbose': false,
          'moves': <String>['e3', 'e4'],
        },
        // invalid square
        <String, dynamic>{
          'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
          'square': 'e9',
          'verbose': false,
          'moves': <String>[],
        },
        // pinned piece
        <String, dynamic>{
          'fen':
              'rnbqk1nr/pppp1ppp/4p3/8/1b1P4/2N5/PPP1PPPP/R1BQKBNR w KQkq - 2 3',
          'square': 'c3',
          'verbose': false,
          'moves': <String>[],
        },
        // promotion
        <String, dynamic>{
          'fen': '8/k7/8/8/8/8/7p/K7 b - - 0 1',
          'square': 'h2',
          'verbose': false,
          'moves': <String>['h1=Q+', 'h1=R+', 'h1=B', 'h1=N'],
        },
        // castling
        <String, dynamic>{
          'fen':
              'r1bq1rk1/1pp2ppp/p1np1n2/2b1p3/2B1P3/2NP1N2/PPPBQPPP/R3K2R w KQ - 0 8',
          'square': 'e1',
          'verbose': false,
          'moves': <String>['Kf1', 'Kd1', 'O-O', 'O-O-O'],
        },
        // no castling
        <String, dynamic>{
          'fen':
              'r1bq1rk1/1pp2ppp/p1np1n2/2b1p3/2B1P3/2NP1N2/PPPBQPPP/R3K2R w - - 0 8',
          'square': 'e1',
          'verbose': false,
          'moves': <String>['Kf1', 'Kd1'],
        },
        // trapped king
        <String, dynamic>{
          'fen': '8/7K/8/8/1R6/k7/1R1p4/8 b - - 0 1',
          'square': 'a3',
          'verbose': false,
          'moves': <String>[],
        },
      ];

      for (final Map<String, dynamic> position in positions) {
        final Chess chess = Chess.create();
        chess.load(position['fen'] as String);

        final String failMessage =
            'Failed for: ${position['fen']} ${position['square']}';

        final List<Move> moves = chess.moves(position['square'] as String?);
        expect(
          moves.length,
          (position['moves'] as List<String>).length,
          reason: failMessage,
        );
        expect(
          moves.map((Move e) => e.san),
          unorderedEquals(position['moves'] as List<String>),
          reason: failMessage,
        );
      }
    });

    test('verbose', () {
      final List<Map<String, dynamic>> positions = <Map<String, dynamic>>[
        // verbose
        <String, dynamic>{
          'fen': '8/7K/8/8/1R6/k7/1R1p4/8 b - - 0 1',
          'square': 'd2',
          'verbose': true,
          'moves': <Map<String, String?>>[
            <String, String?>{
              'color': 'b',
              'from': 'd2',
              'to': 'd1',
              'flags': 'np',
              'piece': 'p',
              'promotion': 'q',
              'san': 'd1=Q',
            },
            <String, String?>{
              'color': 'b',
              'from': 'd2',
              'to': 'd1',
              'flags': 'np',
              'piece': 'p',
              'promotion': 'r',
              'san': 'd1=R',
            },
            <String, String?>{
              'color': 'b',
              'from': 'd2',
              'to': 'd1',
              'flags': 'np',
              'piece': 'p',
              'promotion': 'b',
              'san': 'd1=B',
            },
            <String, String?>{
              'color': 'b',
              'from': 'd2',
              'to': 'd1',
              'flags': 'np',
              'piece': 'p',
              'promotion': 'n',
              'san': 'd1=N',
            },
          ],
        },
        // issue #30
        <String, dynamic>{
          'fen':
              'rnbqk2r/ppp1pp1p/5n1b/3p2pQ/1P2P3/B1N5/P1PP1PPP/R3KBNR b KQkq - 3 5',
          'square': 'f1',
          'verbose': true,
          'moves': <Map<String, String?>>[],
        },
      ];

      for (final Map<String, dynamic> position in positions) {
        final Chess chess = Chess.create();
        chess.load(position['fen'] as String);

        final String failMessage = '${position['fen']} ${position['square']}';

        final List<Move> moves = chess.moves(position['square'] as String);
        expect(
          moves.length,
          (position['moves'] as List<Map<String, String?>>).length,
          reason: failMessage,
        );
        expect(
          moves,
          unorderedEquals(
            _parseMoveFromMapList(
              position['moves'] as List<Map<String, String?>>,
            ),
          ),
          reason: failMessage,
        );
      }
    });
  });
  group('Algebraic notation', () {
    test('If move generation works properly', () {
      const List<Map<String, dynamic>> positions = <Map<String, dynamic>>[
        <String, dynamic>{
          'fen': '7k/3R4/3p2Q1/6Q1/2N1N3/8/8/3R3K w - - 0 1',
          'moves': <String>[
            'Rd8#',
            'Re7',
            'Rf7',
            'Rg7',
            'Rh7#',
            'R7xd6',
            'Rc7',
            'Rb7',
            'Ra7',
            'Qf7',
            'Qe8#',
            'Qg7#',
            'Qg8#',
            'Qh7#',
            'Q6h6#',
            'Q6h5#',
            'Q6f5',
            'Q6f6#',
            'Qe6',
            'Qxd6',
            'Q5f6#',
            'Qe7',
            'Qd8#',
            'Q5h6#',
            'Q5h5#',
            'Qh4#',
            'Qg4',
            'Qg3',
            'Qg2',
            'Qg1',
            'Qf4',
            'Qe3',
            'Qd2',
            'Qc1',
            'Q5f5',
            'Qe5+',
            'Qd5',
            'Qc5',
            'Qb5',
            'Qa5',
            'Na5',
            'Nb6',
            'Ncxd6',
            'Ne5',
            'Ne3',
            'Ncd2',
            'Nb2',
            'Na3',
            'Nc5',
            'Nexd6',
            'Nf6',
            'Ng3',
            'Nf2',
            'Ned2',
            'Nc3',
            'Rd2',
            'Rd3',
            'Rd4',
            'Rd5',
            'R1xd6',
            'Re1',
            'Rf1',
            'Rg1',
            'Rc1',
            'Rb1',
            'Ra1',
            'Kg2',
            'Kh2',
            'Kg1',
          ],
        },
        <String, dynamic>{
          'fen': '1r3k2/P1P5/8/8/8/8/8/R3K2R w KQ - 0 1',
          'moves': <String>[
            'a8=Q',
            'a8=R',
            'a8=B',
            'a8=N',
            'axb8=Q+',
            'axb8=R+',
            'axb8=B',
            'axb8=N',
            'c8=Q+',
            'c8=R+',
            'c8=B',
            'c8=N',
            'cxb8=Q+',
            'cxb8=R+',
            'cxb8=B',
            'cxb8=N',
            'Ra2',
            'Ra3',
            'Ra4',
            'Ra5',
            'Ra6',
            'Rb1',
            'Rc1',
            'Rd1',
            'Kd2',
            'Ke2',
            'Kf2',
            'Kf1',
            'Kd1',
            'Rh2',
            'Rh3',
            'Rh4',
            'Rh5',
            'Rh6',
            'Rh7',
            'Rh8+',
            'Rg1',
            'Rf1+',
            'O-O+',
            'O-O-O',
          ],
        },
        <String, dynamic>{
          'fen': '5rk1/8/8/8/8/8/2p5/R3K2R w KQ - 0 1',
          'moves': <String>[
            'Ra2',
            'Ra3',
            'Ra4',
            'Ra5',
            'Ra6',
            'Ra7',
            'Ra8',
            'Rb1',
            'Rc1',
            'Rd1',
            'Kd2',
            'Ke2',
            'Rh2',
            'Rh3',
            'Rh4',
            'Rh5',
            'Rh6',
            'Rh7',
            'Rh8+',
            'Rg1+',
            'Rf1',
          ],
        },
        <String, dynamic>{
          'fen': '5rk1/8/8/8/8/8/2p5/R3K2R b KQ - 0 1',
          'moves': <String>[
            'Rf7',
            'Rf6',
            'Rf5',
            'Rf4',
            'Rf3',
            'Rf2',
            'Rf1+',
            'Re8+',
            'Rd8',
            'Rc8',
            'Rb8',
            'Ra8',
            'Kg7',
            'Kf7',
            'c1=Q+',
            'c1=R+',
            'c1=B',
            'c1=N',
          ],
        },
        <String, dynamic>{
          'fen':
              'r3k2r/p2pqpb1/1n2pnp1/2pPN3/1p2P3/2N2Q1p/PPPB1PPP/R3K2R w KQkq c6 0 2',
          'moves': <String>[
            'gxh3',
            'Qxf6',
            'Qxh3',
            'Nxd7',
            'Nxf7',
            'Nxg6',
            'dxc6',
            'dxe6',
            'Rg1',
            'Rf1',
            'Ke2',
            'Kf1',
            'Kd1',
            'Rb1',
            'Rc1',
            'Rd1',
            'g3',
            'g4',
            'Be3',
            'Bf4',
            'Bg5',
            'Bh6',
            'Bc1',
            'b3',
            'a3',
            'a4',
            'Qf4',
            'Qf5',
            'Qg4',
            'Qh5',
            'Qg3',
            'Qe2',
            'Qd1',
            'Qe3',
            'Qd3',
            'Na4',
            'Nb5',
            'Ne2',
            'Nd1',
            'Nb1',
            'Nc6',
            'Ng4',
            'Nd3',
            'Nc4',
            'd6',
            'O-O',
            'O-O-O',
          ],
        },
        <String, dynamic>{
          'fen': 'k7/8/K7/8/3n3n/5R2/3n4/8 b - - 0 1',
          'moves': <String>[
            'N2xf3',
            'Nhxf3',
            'Nd4xf3',
            'N2b3',
            'Nc4',
            'Ne4',
            'Nf1',
            'Nb1',
            'Nhf5',
            'Ng6',
            'Ng2',
            'Nb5',
            'Nc6',
            'Ne6',
            'Ndf5',
            'Ne2',
            'Nc2',
            'N4b3',
            'Kb8',
          ],
        },
      ];

      for (final Map<String, dynamic> position in positions) {
        final Chess chess = Chess.create();
        chess.load(position['fen'] as String);

        final List<Move> moves = chess.moves();

        expect(moves.length, (position['moves'] as List<String>).length);

        final List<String> expectedMoves =
            List<String>.from(position['moves'] as List<String>);

        expect(moves.map((Move e) => e.san), unorderedEquals(expectedMoves));
      }
    });
  });
  group('FEN', () {
    test('Try parse FEN string', () {
      const List<Map<String, dynamic>> positions = <Map<String, dynamic>>[
        <String, dynamic>{
          'fen': '8/8/8/8/8/8/8/8 w - - 0 1',
          'shouldPass': true,
        },
        <String, dynamic>{
          'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
          'shouldPass': true,
        },
        <String, dynamic>{
          'fen': 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
          'shouldPass': true,
        },
        <String, dynamic>{
          'fen': '1nbqkbn1/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/1NBQKBN1 b - - 1 2',
          'shouldPass': true,
        },
        // incomplete FEN string
        <String, dynamic>{
          'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBN w KQkq - 0 1',
          'shouldPass': false,
        },
        // bad digit (9)
        <String, dynamic>{
          'fen': 'rnbqkbnr/pppppppp/9/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
          'shouldPass': false,
        },
        // bad piece (X)
        <String, dynamic>{
          'fen': '1nbqkbn1/pppp1ppX/8/4p3/4P3/8/PPPP1PPP/1NBQKBN1 b - - 1 2',
          'shouldPass': false,
        },
      ];

      for (final Map<String, dynamic> position in positions) {
        final Chess chess = Chess.create();

        chess.load(position['fen'] as String);

        expect(chess.fen() == position['fen'], position['shouldPass']);
      }
    });
  });
  group('Get/Put/Remove board piece', () {
    test('If we can move pieces properly', () {
      final Chess chess = Chess.create();

      final List<Map<String, dynamic>> positions = <Map<String, dynamic>>[
        <String, dynamic>{
          'pieces': <Map<String, dynamic>>[
            <String, dynamic>{
              'square': Square.a7,
              'piece':
                  Piece.fromSymbolAndColor(PieceSymbol.pawn, PieceColor.white),
            },
            <String, dynamic>{
              'square': Square.b7,
              'piece':
                  Piece.fromSymbolAndColor(PieceSymbol.pawn, PieceColor.black),
            },
            <String, dynamic>{
              'square': Square.c7,
              'piece': Piece.fromSymbolAndColor(
                PieceSymbol.knight,
                PieceColor.white,
              ),
            },
            <String, dynamic>{
              'square': Square.d7,
              'piece': Piece.fromSymbolAndColor(
                PieceSymbol.knight,
                PieceColor.black,
              ),
            },
            <String, dynamic>{
              'square': Square.e7,
              'piece': Piece.fromSymbolAndColor(
                PieceSymbol.bishop,
                PieceColor.white,
              ),
            },
            <String, dynamic>{
              'square': Square.f7,
              'piece': Piece.fromSymbolAndColor(
                PieceSymbol.bishop,
                PieceColor.black,
              ),
            },
            <String, dynamic>{
              'square': Square.g7,
              'piece':
                  Piece.fromSymbolAndColor(PieceSymbol.rook, PieceColor.white),
            },
            <String, dynamic>{
              'square': Square.h7,
              'piece':
                  Piece.fromSymbolAndColor(PieceSymbol.rook, PieceColor.black),
            },
            <String, dynamic>{
              'square': Square.a6,
              'piece':
                  Piece.fromSymbolAndColor(PieceSymbol.queen, PieceColor.white),
            },
            <String, dynamic>{
              'square': Square.b6,
              'piece':
                  Piece.fromSymbolAndColor(PieceSymbol.queen, PieceColor.black),
            },
            <String, dynamic>{
              'square': Square.a4,
              'piece':
                  Piece.fromSymbolAndColor(PieceSymbol.king, PieceColor.white),
            },
            <String, dynamic>{
              'square': Square.h4,
              'piece':
                  Piece.fromSymbolAndColor(PieceSymbol.king, PieceColor.black),
            },
          ],
          'shouldPass': true,
        },
        // disallow two kings (black)
        <String, dynamic>{
          'pieces': <Map<String, dynamic>>[
            <String, dynamic>{
              'square': Square.a7,
              'piece':
                  Piece.fromSymbolAndColor(PieceSymbol.king, PieceColor.black)
            },
            <String, dynamic>{
              'square': Square.h2,
              'piece':
                  Piece.fromSymbolAndColor(PieceSymbol.king, PieceColor.white)
            },
            <String, dynamic>{
              'square': Square.a8,
              'piece':
                  Piece.fromSymbolAndColor(PieceSymbol.king, PieceColor.black)
            },
          ],
          'shouldPass': false,
        },
        // disallow two kings (white)
        <String, dynamic>{
          'pieces': <Map<String, dynamic>>[
            <String, dynamic>{
              'square': Square.a7,
              'piece':
                  Piece.fromSymbolAndColor(PieceSymbol.king, PieceColor.black)
            },
            <String, dynamic>{
              'square': Square.h2,
              'piece':
                  Piece.fromSymbolAndColor(PieceSymbol.king, PieceColor.white)
            },
            <String, dynamic>{
              'square': Square.h1,
              'piece':
                  Piece.fromSymbolAndColor(PieceSymbol.king, PieceColor.white)
            },
          ],
          'shouldPass': false,
        },
        // allow two kings if overwriting the exact same square
        <String, dynamic>{
          'pieces': <Map<String, dynamic>>[
            <String, dynamic>{
              'square': Square.a7,
              'piece':
                  Piece.fromSymbolAndColor(PieceSymbol.king, PieceColor.black)
            },
            <String, dynamic>{
              'square': Square.h2,
              'piece':
                  Piece.fromSymbolAndColor(PieceSymbol.king, PieceColor.white)
            },
            <String, dynamic>{
              'square': Square.h2,
              'piece':
                  Piece.fromSymbolAndColor(PieceSymbol.king, PieceColor.white)
            },
          ],
          'shouldPass': true,
        },
      ];

      for (final Map<String, dynamic> position in positions) {
        chess.clear();

        final Map<Square, Piece> pieceDict = <Square, Piece>{};

        for (final Map<String, dynamic> item in position['pieces']) {
          pieceDict[item['square'] as Square] = item['piece'] as Piece;
        }

        // places the pieces
        bool passed = true;

        for (final Map<String, dynamic> e in position['pieces']) {
          final Square square = e['square'] as Square;
          final Piece piece = e['piece'] as Piece;

          final bool inserted = chess.put(piece, square.notation);

          passed = passed && inserted;
        }

        // iterate over every square to make sure get returns the proper piece values/color
        for (final Square square in Square.values) {
          if (!pieceDict.containsKey(square)) {
            if (chess.get(square.notation) != null) {
              passed = false;
              break;
            }
          } else {
            final Piece? piece = chess.get(square.notation);
            if (!(piece != null &&
                piece.symbol == pieceDict[square]?.symbol &&
                piece.color == pieceDict[square]?.color)) {
              passed = false;
              break;
            }
          }
        }

        if (passed) {
          // remove the pieces
          for (final Square square in Square.values) {
            final Piece? piece = chess.remove(square.notation);
            if (!pieceDict.containsKey(square) && piece != null) {
              passed = false;
              break;
            }

            if (piece != null &&
                (pieceDict[square]?.symbol != piece.symbol ||
                    pieceDict[square]?.color != piece.color)) {
              passed = false;
              break;
            }
          }
        }

        // finally, check for an empty board
        passed = passed && chess.fen() == '8/8/8/8/8/8/8/8 w - - 0 1';

        expect(passed, position['shouldPass']);
      }
    });
  });
  test('ASCII Generation', () {
    final Chess chess = Chess.create();

    expect(
      chess.ascii(),
      '  +------------------------+\n'
      '8 | r  n  b  q  k  b  n  r |\n'
      '7 | p  p  p  p  p  p  p  p |\n'
      '6 | .  .  .  .  .  .  .  . |\n'
      '5 | .  .  .  .  .  .  .  . |\n'
      '4 | .  .  .  .  .  .  .  . |\n'
      '3 | .  .  .  .  .  .  .  . |\n'
      '2 | P  P  P  P  P  P  P  P |\n'
      '1 | R  N  B  Q  K  B  N  R |\n'
      '  +------------------------+\n'
      '    a  b  c  d  e  f  g  h',
    );
  });
  group('Move Dry-Run', () {
    test('does not update the state', () {
      final Chess chess = Chess.create();
      final String fen = chess.fen();

      for (final Move move in chess.moves()) {
        // run all possible moves.
        chess.move(san: move.from.notation, dryRun: true);
      }

      // and check if the fen (state) remains the same.
      expect(chess.fen(), fen);
    });
  });
  group('Validate Moves', () {
    test('valid moves', () {
      final Chess chess = Chess.create();
      final List<String> moves = <String>['e4', 'e5', 'Nf3', 'Nc6'];
      final List<Map<String, String?>> expected = <Map<String, String?>>[
        <String, String?>{
          'color': 'w',
          'flags': 'b',
          'from': 'e2',
          'piece': 'p',
          'san': 'e4',
          'to': 'e4',
        },
        <String, String?>{
          'color': 'b',
          'flags': 'b',
          'from': 'e7',
          'piece': 'p',
          'san': 'e5',
          'to': 'e5',
        },
        <String, String?>{
          'color': 'w',
          'flags': 'n',
          'from': 'g1',
          'piece': 'n',
          'san': 'Nf3',
          'to': 'f3',
        },
        <String, String?>{
          'color': 'b',
          'flags': 'n',
          'from': 'b8',
          'piece': 'n',
          'san': 'Nc6',
          'to': 'c6',
        },
      ];

      expect(chess.validateMoves(moves), _parseMoveFromMapList(expected));
    });
  });
  group('Promotion', () {
    test('Move', () {
      final List<Map<String, dynamic>> positions = <Map<String, dynamic>>[
        // legal promotion
        <String, dynamic>{
          'fen': '8/2P2k2/8/8/8/5K2/8/8 w - - 0 1',
          'san': 'c8',
          'move': <String, Square>{'from': Square.c7, 'to': Square.c8},
        },
      ];

      for (final Map<String, dynamic> position in positions) {
        final String fen = position['fen'] as String;
        final String san = position['san'] as String;
        final Map<String, dynamic> move =
            position['move'] as Map<String, dynamic>;
        final Square from = move['from'] as Square;
        final Square to = move['to'] as Square;
        final String failMessage = '$fen ($from $to)';

        final Chess chess = Chess.create();
        // illegal move, no promotion passed
        expect(chess.move(san: san), null, reason: failMessage); // san
        expect(chess.move(san: '$from$to'), null); // sloppy
        expect(chess.move(from: from, to: to), null); // move obj

        // promotion passed
        final List<PieceSymbol> pieces = <String>['q', 'r', 'b', 'n']
            .map((String e) => PieceSymbol.fromChar(e)!)
            .toList();

        for (final PieceSymbol promotion in pieces) {
          chess.load(fen);

          // san
          expect(
            chess.move(from: from, to: to, promotion: promotion)!.promotion,
            promotion,
          );

          chess.load(fen);
          // sloppy
          expect(
            chess
                .move(from: from, to: to, promotion: promotion, sloppy: true)!
                .promotion,
            promotion,
          );
          chess.load(fen);
          expect(
            chess.move(from: from, to: to, promotion: promotion)!.promotion,
            promotion,
          );
        }
      }
    });
  });
  test('isPromotion', () {
    const List<Map<String, dynamic>> positions = <Map<String, dynamic>>[
      // legal move non-promotion
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        'san': 'e4',
        'move': <String, dynamic>{'from': Square.e2, 'to': Square.e4},
        'promotion': false,
      },
      // illegal move
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        'san': 'e8',
        'move': <String, dynamic>{'from': Square.e2, 'to': Square.e8},
        'promotion': false,
      },
      // no piece on from
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        'san': 'e4',
        'move': <String, dynamic>{'from': Square.e3, 'to': Square.e4},
        'promotion': false,
      },
      // illegal promotion due to discovery
      <String, dynamic>{
        'fen': '1K6/2P2k2/8/8/5b2/8/8/8 w - - 0 1',
        'san': 'c8',
        'move': <String, dynamic>{'from': Square.c7, 'to': Square.c8},
        'promotion': false,
      },
      // illegal move non-capturing diagonal
      <String, dynamic>{
        'fen': '8/2P2k2/8/8/8/5K2/8/8 w - - 0 1',
        'san': 'b8',
        'move': <String, dynamic>{'from': Square.c7, 'to': Square.b8},
        'promotion': false,
      },
      // legal promotion
      <String, dynamic>{
        'fen': '8/2P2k2/8/8/8/5K2/8/8 w - - 0 1',
        'san': 'c8',
        'move': <String, dynamic>{'from': Square.c7, 'to': Square.c8},
        'promotion': true,
      },
      // legal capturing promotion
      <String, dynamic>{
        'fen': '1b6/2P2k2/8/8/5K2/8/8/8 w - - 0 1',
        'san': 'cxb8',
        'move': <String, dynamic>{'from': Square.c7, 'to': Square.b8},
        'promotion': true,
      },
    ];

    for (final Map<String, dynamic> position in positions) {
      final String fen = position['fen'] as String;
      final String san = position['san'] as String;
      final Map<String, dynamic> move =
          position['move'] as Map<String, dynamic>;
      final bool promotion = position['promotion'] as bool;

      final Square from = move['from'] as Square;
      final Square to = move['to'] as Square;

      final String failMessage = '$fen ($from $to $promotion)';

      final Chess chess = Chess.create();

      chess.load(fen);

      // san
      expect(
        chess.isPromotion(san: san),
        promotion,
        reason: failMessage,
      );

      // sloppy
      expect(
        chess.isPromotion(san: '${from.notation}${to.notation}', sloppy: true),
        promotion,
        reason: failMessage,
      );

      // move obj
      expect(
        chess.isPromotion(from: from, to: to),
        promotion,
        reason: failMessage,
      );
    }
  });
  test('Load PGN', () {
    final Chess chess = Chess.create();
    const List<Map<String, dynamic>> tests = <Map<String, dynamic>>[
      <String, dynamic>{
        'pgn': <String>[
          '[Event "Reykjavik WCh"]',
          '[Site "Reykjavik WCh"]',
          '[Date "1972.01.07"]',
          '[EventDate "?"]',
          '[Round "6"]',
          '[Result "1-0"]',
          '[White "Robert James Fischer"]',
          '[Black "Boris Spassky"]',
          '[ECO "D59"]',
          '[WhiteElo "?"]',
          '[BlackElo "?"]',
          '[PlyCount "81"]',
          '',
          '1. c4 e6 2. Nf3 d5 3. d4 Nf6 4. Nc3 Be7 5. Bg5 O-O 6. e3 h6',
          '7. Bh4 b6 8. cxd5 Nxd5 9. Bxe7 Qxe7 10. Nxd5 exd5 11. Rc1 Be6',
          '12. Qa4 c5 13. Qa3 Rc8 14. Bb5 a6 15. dxc5 bxc5 16. O-O Ra7',
          '17. Be2 Nd7 18. Nd4 Qf8 19. Nxe6 fxe6 20. e4 d4 21. f4 Qe7',
          '22. e5 Rb8 23. Bc4 Kh8 24. Qh3 Nf8 25. b3 a5 26. f5 exf5',
          '27. Rxf5 Nh7 28. Rcf1 Qd8 29. Qg3 Re7 30. h4 Rbb7 31. e6 Rbc7',
          '32. Qe5 Qe8 33. a4 Qd8 34. R1f2 Qe8 35. R2f3 Qd8 36. Bd3 Qe8',
          '37. Qe4 Nf6 38. Rxf6 gxf6 39. Rxf6 Kg8 40. Bc4 Kh8 41. Qf4 1-0',
        ],
        'expect': true,
      },
      <String, dynamic>{
        'fen': '1n1Rkb1r/p4ppp/4q3/4p1B1/4P3/8/PPP2PPP/2K5 b k - 1 17',
        'pgn': <String>[
          '[Event "Paris"]',
          '[Site "Paris"]',
          '[Date "1858.??.??"]',
          '[EventDate "?"]',
          '[Round "?"]',
          '[Result "1-0"]',
          '[White "Paul Morphy"]',
          '[Black "Duke Karl / Count Isouard"]',
          '[ECO "C41"]',
          '[WhiteElo "?"]',
          '[BlackElo "?"]',
          '[PlyCount "33"]',
          '',
          '1.e4 e5 2.Nf3 d6 3.d4 Bg4 {This is a weak move',
          'already.--Fischer} 4.dxe5 Bxf3 5.Qxf3 dxe5 6.Bc4 Nf6 7.Qb3 Qe7',
          "8.Nc3 c6 9.Bg5 {Black is in what's like a zugzwang position",
          "here. He can't develop the [Queen's] knight because the pawn",
          'is hanging, the bishop is blocked because of the',
          'Queen.--Fischer} b5 10.Nxb5 cxb5 11.Bxb5+ Nbd7 12.O-O-O Rd8',
          '13.Rxd7 Rxd7 14.Rd1 Qe6 15.Bxd7+ Nxd7 16.Qb8+ Nxb8 17.Rd8# 1-0',
        ],
        'expect': true,
      },
      // Github Issue #134 - Load PGN with comment before first move
      <String, dynamic>{
        'fen':
            'r1bqk2r/pp1nbppp/2p1pn2/3p4/2PP4/5NP1/PP2PPBP/RNBQ1RK1 w kq - 4 7',
        'pgn': <String>[
          '[Event "2012 ROCHESTER GRAND WINTER OPEN"]',
          '[Site "Rochester"]',
          '[Date "2012.02.04"]',
          '[Round "1"]',
          '[White "Jensen, Matthew"]',
          '[Black "Gaustad, Kevin"]',
          '[Result "1-0"]',
          '[ECO "E01"]',
          '[WhiteElo "2131"]',
          '[BlackElo "1770"]',
          '[Annotator "Jensen, Matthew"]',
          '',
          '{ Kevin and I go way back.  I checked the USCF player stats and my previous',
          'record against Kevin was 4 losses and 1 draw out of 5 games.  All of our',
          'previous games were between 1992-1998. }',
          '1.d4 Nf6 2.c4 e6 3.g3 { Avrukh says',
          'to play 3.g3 instead of 3.Nf3 in case the Knight later comes to e2, as in the',
          'Bogo-Indian. } 3...d5 4.Bg2 c6 5.Nf3 Be7 6.O-O Nbd7',
          '1-0',
        ],
        'expect': true,
      },
      <String, dynamic>{
        'pgn': <String>[
          '1. e4 e5 2. f4 exf4 3. Nf3 g5 4. h4 g4 5. Ne5 Nf6 6. Nxg4 Nxe4',
          '7. d3 Ng3 8. Bxf4 Nxh1 9. Qe2+ Qe7 10. Nf6+ Kd8 11. Bxc7+ Kxc7',
          '12. Nd5+ Kd8 13. Nxe7 Bxe7 14. Qg4 d6 15. Qf4 Rg8 16. Qxf7 Bxh4+',
          '17. Kd2 Re8 18. Na3 Na6 19. Qh5 Bf6 20. Qxh1 Bxb2 21. Qh4+ Kd7',
          '22. Rb1 Bxa3 23. Qa4+',
        ],
        'expect': true,
      },
      /* regression test - broken PGN parser ended up here:
     * fen = rnbqk2r/pp1p1ppp/4pn2/1N6/1bPN4/8/PP2PPPP/R1BQKB1R b KQkq - 2 6 */
      <String, dynamic>{
        'pgn': <String>[
          '1. d4 Nf6 2. c4 e6 3. Nf3 c5 4. Nc3 cxd4 5. Nxd4 Bb4 6. Nb5'
        ],
        'fen':
            'rnbqk2r/pp1p1ppp/4pn2/1N6/1bP5/2N5/PP2PPPP/R1BQKB1R b KQkq - 2 6',
        'expect': true,
      },
      <String, dynamic>{
        'pgn': <String>['1. e4 Qxd7 1/2-1/2'],
        'expect': false
      },
      <String, dynamic>{
        'pgn': <String>['1. e4!! e5?! 2. d4?? d5!?'],
        'fen': 'rnbqkbnr/ppp2ppp/8/3pp3/3PP3/8/PPP2PPP/RNBQKBNR w KQkq d6 0 3',
        'expect': true,
      },
      <String, dynamic>{
        'pgn': <String>['1. e4!+'],
        'expect': false
      },
      <String, dynamic>{
        'pgn': <String>[
          '1.e4 e6 2.d4 d5 3.exd5 c6?? 4.dxe6 Nf6?! 5.exf7+!! Kd7!? 6.Nf3 Bd6 7.f8=N+!! Qxf8',
        ],
        'fen': 'rnb2q1r/pp1k2pp/2pb1n2/8/3P4/5N2/PPP2PPP/RNBQKB1R w KQ - 0 8',
        'expect': true,
      },
      <String, dynamic>{
        'pgn': <String>["1. e4 ( 1. d4 { Queen's pawn } d5 ( 1... Nf6 ) ) e5"],
        'fen': 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2',
        'expect': true,
      },
      <String, dynamic>{
        'pgn': <String>[
          '1. e4 c5 2. Nf3 e6 { Sicilian Defence, French Variation } 3. Nc3 a6',
          '4. Be2 Nc6 5. d4 cxd4 6. Nxd4 Qc7 7. O-O Nf6 8. Be3 Be7 9. f4 d6',
          '10. Kh1 O-O 11. Qe1 Nxd4 12. Bxd4 b5 13. Qg3 Bb7 14. a3 Rad8',
          '15. Rae1 Rd7 16. Bd3 Qd8 17. Qh3 g6? { (0.05 → 1.03) Inaccuracy.',
          'The best move was h6. } (17... h6 18. Rd1 Re8 19. Qg3 Nh5 20. Qg4',
          'Nf6 21. Qh3 Bc6 22. Kg1 Qb8 23. Qg3 Nh5 24. Qf2 Bf6 25. Be2 Bxd4',
          '26. Rxd4 Nf6 27. g3) 18. f5 e5',
        ],
        'fen':
            '3q1rk1/1b1rbp1p/p2p1np1/1p2pP2/3BP3/P1NB3Q/1PP3PP/4RR1K w - - 0 19',
        'expect': true,
      },
      <String, dynamic>{
        'pgn': <String>[
          '1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5 4. b4 Bb6 5. a4 a6 6. c3 Nf6 7. d3 d6',
          '8. Nbd2 O-O 9. O-O Ne7 10. d4 Ng6 11. dxe5 Nxe5 12. Nxe5 dxe5 13. Qb3 Ne8',
          r'14. Nf3 Nd6 15. Rd1 Bg4 16. Be2 Qf6 17. c4 Bxf3 18. Bxf3 Bd4 19. Rb1 b5 $2',
          r'20. c5 Nc4 21. Rf1 Qg6 22. Qc2 c6 23. Be2 Rfd8 24. a5 h5 $2 (24... Rd7 $11)',
          r'25. Rb3 $1 h4 26. Rh3 Qf6 27. Rf3',
        ],
        'fen':
            'r2r2k1/5pp1/p1p2q2/PpP1p3/1PnbP2p/5R2/2Q1BPPP/2B2RK1 b - - 3 27',
        'expect': true,
      },
      <String, dynamic>{
        'pgn': <String>[
          '1. d4 d5 2. Bf4 Nf6 3. e3 g6 4. Nf3 (4. Nc3 Bg7 5. Nf3 O-O 6. Be2 c5)',
          '4... Bg7 5. h3 { 5. Be2 O-O 6. O-O c5 7. c3 Nc6 } 5... O-O',
        ],
        'fen':
            'rnbq1rk1/ppp1ppbp/5np1/3p4/3P1B2/4PN1P/PPP2PP1/RN1QKB1R w KQ - 1 6',
        'expect': true,
      },

      // test the sloppy PGN parser
      <String, dynamic>{
        'pgn': <String>[
          '1.e4 e5 2.Nf3 d6 3.d4 Bg4 4.dxe5 Bxf3 5.Qxf3 dxe5 6.Qf5 Nc6 7.Bb5 Nge7',
          '8.Qxe5 Qd7 9.O-O Nxe5 10.Bxd7+ Nxd7 11.Rd1 O-O-O 12.Nc3 Ng6 13.Be3 a6',
          '14.Ba7 b6 15.Na4 Kb7 16.Bxb6 cxb6 17.b3 b5 18.Nb2 Nge5 19.f3 Rc8',
          '20.Rac1 Ba3 21.Rb1 Rxc2 22.f4 Ng4 23.Rxd7+ Kc6 24.Rxf7 Bxb2 25.Rxg7',
          'Ne3 26.Rg3 Bd4 27.Kh1 Rxa2 28.Rc1+ Kb6 29.e5 Rf8 30.e6 Rxf4 31.e7 Re4',
          '32.Rg7 Bxg7',
        ],
        'fen': '8/4P1bp/pk6/1p6/4r3/1P2n3/r5PP/2R4K w - - 0 33',
        'expect': false,
        'sloppy': false,
      },

      <String, dynamic>{
        'pgn': <String>[
          '1.e4 e5 2.Nf3 d6 3.d4 Bg4 4.dxe5 Bxf3 5.Qxf3 dxe5 6.Qf5 Nc6 7.Bb5 Nge7',
          '8.Qxe5 Qd7 9.O-O Nxe5 10.Bxd7+ Nxd7 11.Rd1 O-O-O 12.Nc3 Ng6 13.Be3 a6',
          '14.Ba7 b6 15.Na4 Kb7 16.Bxb6 cxb6 17.b3 b5 18.Nb2 Nge5 19.f3 Rc8',
          '20.Rac1 Ba3 21.Rb1 Rxc2 22.f4 Ng4 23.Rxd7+ Kc6 24.Rxf7 Bxb2 25.Rxg7',
          'Ne3 26.Rg3 Bd4 27.Kh1 Rxa2 28.Rc1+ Kb6 29.e5 Rf8 30.e6 Rxf4 31.e7 Re4',
          '32.Rg7 Bxg7',
        ],
        'fen': '8/4P1bp/pk6/1p6/4r3/1P2n3/r5PP/2R4K w - - 0 33',
        'expect': true,
        'sloppy': true,
      },

      // the sloppy PGN parser should still accept correctly disambiguated moves
      <String, dynamic>{
        'pgn': <String>[
          '1.e4 e5 2.Nf3 d6 3.d4 Bg4 4.dxe5 Bxf3 5.Qxf3 dxe5 6.Qf5 Nc6 7.Bb5 Ne7',
          '8.Qxe5 Qd7 9.O-O Nxe5 10.Bxd7+ Nxd7 11.Rd1 O-O-O 12.Nc3 Ng6 13.Be3 a6',
          '14.Ba7 b6 15.Na4 Kb7 16.Bxb6 cxb6 17.b3 b5 18.Nb2 Nge5 19.f3 Rc8',
          '20.Rac1 Ba3 21.Rb1 Rxc2 22.f4 Ng4 23.Rxd7+ Kc6 24.Rxf7 Bxb2 25.Rxg7',
          'Ne3 26.Rg3 Bd4 27.Kh1 Rxa2 28.Rc1+ Kb6 29.e5 Rf8 30.e6 Rxf4 31.e7 Re4',
          '32.Rg7 Bxg7',
        ],
        'fen': '8/4P1bp/pk6/1p6/4r3/1P2n3/r5PP/2R4K w - - 0 33',
        'expect': true,
        'sloppy': true,
      },

      <String, dynamic>{
        'pgn': <String>[
          '1.e4 e5 2.Nf3 Nc6 3.Bc4 Nf6 4.Ng5 d5 5.exd5 Nxd5 6.Nxf7 Kxf7 7.Qf3+',
          'Ke6 8.Nc3 Nb4',
        ],
        'fen':
            'r1bq1b1r/ppp3pp/4k3/3np3/1nB5/2N2Q2/PPPP1PPP/R1B1K2R w KQ - 4 9',
        'expect': true,
        'sloppy': true,
      },

      // the sloppy parser should handle lazy disambiguation (e.g. Rc1c4 below)
      <String, dynamic>{
        'pgn': <String>[
          '1.e4 e5 2. Nf3 d5 3. Nxe5 f6 4. Bb5+ c6 5. Qh5+ Ke7',
          'Qf7+ Kd6 7. d3 Kxe5 8. Qh5+ g5 9. g3 cxb5 10. Bf4+ Ke6',
          'exd5+ Qxd5 12. Qe8+ Kf5 13. Rg1 gxf4 14. Nc3 Qc5 15. Ne4 Qxf2+',
          'Kxf2 fxg3+ 17. Rxg3 Nd7 18. Qh5+ Ke6 19. Qe8+ Kd5 20. Rg4 Rb8',
          'c4+ Kc6 22. Qe6+ Kc7 23. cxb5 Ne7 24. Rc1+ Kd8 25. Nxf6 Ra8',
          'Kf1 Rb8 27. Rc1c4 b6 28. Rc4-d4 Rb7 29. Qf7 Rc7 30. Qe8# 1-0',
        ],
        'fen': '2bkQb1r/p1rnn2p/1p3N2/1P6/3R2R1/3P4/PP5P/5K2 b - - 5 30',
        'expect': true,
        'sloppy': true,
      },

      // sloppy parse should parse long algebraic notation
      <String, dynamic>{
        'pgn': <String>[
          'e2e4 d7d5 e4d5 d8d5 d2d4 g8f6 c2c4 d5d8 g1f3 c8g4 f1e2 e7e6 b1c3 f8e7',
          'c1e3 e8g8 d1b3 b8c6 a1d1 a8b8 e1g1 d8c8 h2h3 g4h5 d4d5 e6d5 c4d5 h5f3',
          'e2f3 c6e5 f3e2 a7a6 e3a7 b8a8 a7d4 e7d6 b3c2 f8e8 f2f4 e5d7 e2d3 c7c5',
          'd4f2 d6f4 c3e4 f6d5 e4d6 f4d6 d3h7',
        ],
        'fen': 'r1q1r1k1/1p1n1ppB/p2b4/2pn4/8/7P/PPQ2BP1/3R1RK1 b - - 0 25',
        'expect': true,
        'sloppy': true,
      },

      // sloppy parse should parse extended long algebraic notation w/ en passant
      <String, dynamic>{
        'pgn': <String>[
          '1. d2d4 f7f5 2. b2b3 e7e6 3. c1b2 d7d5 4. g1f3 f8d6 5. e2e3 g8f6 6. b1d2',
          'e8g8 7. c2c4 c7c6 8. f1d3 b8d7 9. e1g1 f6e4 10. a1c1 g7g5 11. h2h3 d8e8 12.',
          'd3e4 d5e4 13. f3g5 e8g6 14. h3h4 h7h6 15. g5h3 d7f6 16. f2f4 e4f3 17. d2f3',
          'f6g4 18. d1e2 d6g3 19. h3f4 g6g7 20. d4d5 g7f7 21. d5e6 c8e6 22. f3e5 g4e5',
          '23. b2e5 g8h7 24. h4h5 f8g8 25. e2f3 g3f4 26. e5f4 g8g4 27. g2g3 a8g8 28.',
          'c1c2 b7b5 29. c4b5 e6d5 30. f3d1 f7h5 31. c2h2 g4g3+ 32. f4g3 g8g3+ 33.',
          'g1f2 h5h2+ 34. f2e1 g3g2 35. d1d3 d5e4 36. d3d7+ h7g6 37. b5c6 g2e2+ 38.',
          'e1d1 e2a2 0-1',
        ],
        'fen': '8/p2Q4/2P3kp/5p2/4b3/1P2P3/r6q/3K1R2 w - - 0 39',
        'expect': true,
        'sloppy': true,
      },

      // sloppy parse should parse long algebraic notation w/ underpromotions
      <String, dynamic>{
        'pgn': <String>[
          '1. e2e4 c7c5 2. g1f3 d7d6 3. d2d4 c5d4 4. f3d4 g8f6 5. f1d3 a7a6 6. c1e3',
          'e7e5 7. d4f5 c8f5 8. e4f5 d6d5 9. e3g5 f8e7 10. d1e2 e5e4 11. g5f6 e7f6 12.',
          'd3e4 d5e4 13. e2e4+ d8e7 14. e4e7+ f6e7 15. e1g1 e8g8 16. f1e1 e7f6 17.',
          'c2c3 b8c6 18. b1d2 a8d8 19. d2e4 f8e8 20. e1e3 c6e5 21. a1e1 e5d3 22. e4f6+',
          'g7f6 23. e3e8+ d8e8 24. e1e8+ g8g7 25. b2b4 d3e5 26. a2a4 b7b5 27. a4b5',
          'a6b5 28. e8b8 e5g4 29. b8b5 g4e5 30. b5c5 g7f8 31. b4b5 f8e7 32. f2f4 e5d7',
          '33. c5c7 e7d6 34. c7c8 d7b6 35. c8c6+ d6d7 36. c6b6 h7h5 37. b6f6 h5h4 38.',
          'f6f7+ d7d6 39. f7h7 h4h3 40. h7h3 d6e7 41. b5b6 e7f6 42. h3h5 f6g7 43. b6b7',
          'g7g8 44. b7b8N g8g7 45. c3c4 g7f6 46. c4c5 f6e7 47. c5c6 e7f6 48. c6c7 f6e7',
          '49. c7c8B e7d6 50. b8a6 d6e7 51. c8e6 e7f6 52. a6c5 f6g7 53. c5e4 g7f8 54.',
          'h5h8+ f8g7 55. h8g8+ g7h6 56. g8g6+ h6h7 57. e4f6+ h7h8 58. f6e4 h8h7 59.',
          'f5f6 h7g6 60. f6f7 g6h5 61. f7f8R h5h6 62. f4f5 h6h7 63. f8f7+ h7h6 64.',
          'f5f6 h6g6 65. f7g7+ g6h5 66. f6f7 h5h4 67. f7f8Q h4h5 68. f8h8# 1-0',
        ],
        'fen': '7Q/6R1/4B3/7k/4N3/8/6PP/6K1 b - - 2 68',
        'expect': true,
        'sloppy': true,
      },

      // sloppy parse should parse abbreviated long algebraic notation
      <String, dynamic>{
        'pgn': <String>[
          '1. d2d4 f7f5 2. Bc1g5 d7d6 3. e2e3 Nb8d7 4. c2c4 Ng8f6 5. Nb1c3 e7e5 6.',
          'd4e5 d6e5 7. g2g3 Bf8e7 8. Bf1h3 h7h6 9. Bg5f6 Nd7f6 10. Qd1d8+ Be7d8 11.',
          'Ng1f3 e5e4 12. Nf3d4 g7g6 13. e1g1 c7c5 14. Nd4b5 e8g8 15. Nb5d6 Bd8c7 16.',
          'Nd6c8 Ra8c8 17. Rf1d1 Rc8d8 18. Bh3f1 b7b6 19. Nc3d5 Nf6d5 20. c4d5 Rf8e8',
          '21. Bf1b5 Re8e5 22. Bb5c6 Kg8f7 23. Kg1f1 Kf7f6 24. h2h4 g6g5 25. h4g5+',
          'h6g5 26. Kf1e2 Rd8h8 27. Rd1h1 Rh8h1 28. Ra1h1 Kf6g7 29. Rh1h5 Kg7g6 30.',
          'Rh5h8 Re5e7 31. Rh8a8 a7a5 32. Ra8a7 Kg6f6 33. Ra7b7 Kf6e5 34. Ke2d2 f5f4',
          '35. g3f4+ g5f4 36. Kd2c3 f4e3 37. f2e3 Re7f7 38. Kc3c4 Ke5d6 39. a2a3 Rf7f3',
          '40. b2b4 a5b4 41. a3b4 c5b4 42. Kc4b4 Rf3e3 43. Kb4c4 Re3a3 44. Kc4b4 e4e3',
          '45. Bc6b5 Ra3a1 46. Kb4c3 Ra1a3+ 47. Kc3d4 Ra3b3 48. Bb5e2 Rb3b4+ 49. Kd4e3',
          'Rb4h4 50. Be2f3 Rh4h3 51. Rb7a7 Rh3f3+ 52. Ke3f3 b6b5 53. Kf3e4 Kd6c5 54.',
          'Ra7b7 Bc7b6 55. Ke4e5 b5b4 56. d5d6 b4b3 57. Rb7b6 Kc5b6 58. d6d7 Kb6c7 59.',
          'Ke5e6 1-0',
        ],
        'fen': '8/2kP4/4K3/8/8/1p6/8/8 b - - 2 59',
        'expect': true,
        'sloppy': true,
      },

      // sloppy parse should parse extended long algebraic notation
      <String, dynamic>{
        'pgn': <String>[
          '1. e2-e4 c7-c5 2. Ng1-f3 d7-d6 3. d2-d4 c5xd4 4. Nf3xd4 Ng8-f6 5. Bf1-d3',
          'a7-a6 6. Bc1-e3 e7-e5 7. Nd4-f5 Bc8xf5 8. e4xf5 d6-d5 9. Be3-g5 Bf8-e7 10.',
          'Qd1-e2 e5-e4 11. Bg5xf6 Be7xf6 12. Bd3xe4 d5xe4 13. Qe2xe4+ Qd8-e7 14.',
          'Qe4xe7+ Bf6xe7 15. e1-g1 e8-g8 16. Rf1-e1 Be7-f6 17. c2-c3 Nb8-c6 18.',
          'Nb1-d2 Ra8-d8 19. Nd2-e4 Rf8-e8 20. Re1-e3 Nc6-e5 21. Ra1-e1 Ne5-d3 22.',
          'Ne4xf6+ g7xf6 23. Re3xe8+ Rd8xe8 24. Re1xe8+ Kg8-g7 25. b2-b4 Nd3-e5 26.',
          'a2-a4 b7-b5 27. a4xb5 a6xb5 28. Re8-b8 Ne5-g4 29. Rb8xb5 Ng4-e5 30. Rb5-c5',
          'Kg7-f8 31. b4-b5 Kf8-e7 32. f2-f4 Ne5-d7 33. Rc5-c7 Ke7-d6 34. Rc7-c8',
          'Nd7-b6 35. Rc8-c6+ Kd6-d7 36. Rc6xb6 h7-h5 37. Rb6xf6 h5-h4 38. Rf6xf7+',
          'Kd7-d6 39. Rf7-h7 h4-h3 40. Rh7xh3 Kd6-e7 41. b5-b6 Ke7-f6 42. Rh3-h5',
          'Kf6-g7 43. b6-b7 Kg7-g8 44. b7-b8N Kg8-g7 45. c3-c4 Kg7-f6 46. c4-c5 Kf6-e7',
          '47. c5-c6 Ke7-f6 48. c6-c7 Kf6-e7 49. c7-c8B Ke7-d6 50. Nb8-a6 Kd6-e7 51.',
          'Bc8-e6 Ke7-f6 52. Na6-c5 Kf6-g7 53. Nc5-e4 Kg7-f8 54. Rh5-h8+ Kf8-g7 55.',
          'Rh8-g8+ Kg7-h6 56. Rg8-g6+ Kh6-h7 57. Ne4-f6+ Kh7-h8 58. Nf6-e4 Kh8-h7 59.',
          'f5-f6 Kh7xg6 60. f6-f7 Kg6-h5 61. f7-f8R Kh5-h6 62. f4-f5 Kh6-h7 63.',
          'Rf8-f7+ Kh7-h6 64. f5-f6 Kh6-g6 65. Rf7-g7+ Kg6-h5 66. f6-f7 Kh5-h4 67.',
          'f7-f8Q Kh4-h5 68. Qf8-h8# 1-0',
        ],
        'fen': '7Q/6R1/4B3/7k/4N3/8/6PP/6K1 b - - 2 68',
        'expect': true,
        'sloppy': true,
      },
    ];

    final List<String> newlineChars = <String>['\n', '<br />', '\r\n', 'BLAH'];

    for (int i = 20; i < tests.length; i++) {
      final Map<String, dynamic> t = tests[i];

      for (int j = 0; j < newlineChars.length; j++) {
        final String newline = newlineChars[j];

        final String failMessage =
            'Failed at test case $i when new line is [${String.fromCharCode(97 + j)}]';

        final bool sloppy = (t['sloppy'] as bool?) ?? false;

        final bool result = chess.loadPgn(
          (t['pgn'] as List<String>).join(newline),
          newlineChar: newline,
          sloppy: sloppy,
        );

        final bool shouldPass = t['expect'] as bool;

        /* some tests are expected to fail */
        if (shouldPass) {
          /* some PGN's tests contain comments which are stripped during parsing,
           * so we'll need compare the results of the load against a FEN string
           * (instead of the reconstructed PGN [e.g. test.pgn.join(newline)])
           */
          if (t.containsKey('fen')) {
            expect(
              result && chess.fen() == t['fen'],
              true,
              reason: failMessage,
            );
          } else {
            final String expectedPgn = (t['pgn'] as List<String>).join(newline);
            final String output = chess.pgn(
              maxWidth: 65,
              newlineChar: newline,
            );
            expect(
              result && output == expectedPgn,
              true,
              reason: failMessage,
            );
          }
        } else {
          /* this test should fail, so make sure it does */
          expect(result == shouldPass, true, reason: failMessage);
        }
      }
    }

    // special case dirty file containing a mix of \n and \r\n
    const String pgn = '[Event "Reykjavik WCh"]\n'
        '[Site "Reykjavik WCh"]\n'
        '[Date "1972.01.07"]\n'
        '[EventDate "?"]\n'
        '[Round "6"]\n'
        '[Result "1-0"]\n'
        '[White "Robert James Fischer"]\r\n'
        '[Black "Boris Spassky"]\n'
        '[ECO "D59"]\n'
        '[WhiteElo "?"]\n'
        '[BlackElo "?"]\n'
        '[PlyCount "81"]\n'
        '\r\n'
        '1. c4 e6 2. Nf3 d5 3. d4 Nf6 4. Nc3 Be7 5. Bg5 O-O 6. e3 h6\n'
        '7. Bh4 b6 8. cxd5 Nxd5 9. Bxe7 Qxe7 10. Nxd5 exd5 11. Rc1 Be6\n'
        '12. Qa4 c5 13. Qa3 Rc8 14. Bb5 a6 15. dxc5 bxc5 16. O-O Ra7\n'
        '17. Be2 Nd7 18. Nd4 Qf8 19. Nxe6 fxe6 20. e4 d4 21. f4 Qe7\r\n'
        '22. e5 Rb8 23. Bc4 Kh8 24. Qh3 Nf8 25. b3 a5 26. f5 exf5\n'
        '27. Rxf5 Nh7 28. Rcf1 Qd8 29. Qg3 Re7 30. h4 Rbb7 31. e6 Rbc7\n'
        '32. Qe5 Qe8 33. a4 Qd8 34. R1f2 Qe8 35. R2f3 Qd8 36. Bd3 Qe8\n'
        '37. Qe4 Nf6 38. Rxf6 gxf6 39. Rxf6 Kg8 40. Bc4 Kh8 41. Qf4 1-0\n';

    // ignore: avoid_redundant_argument_values
    final bool result = chess.loadPgn(pgn, newlineChar: '\r?\n');
    expect(result, true);
    expect(
      chess.loadPgn(pgn),
      true,
    );
    expect(RegExp(r'^\[\[').firstMatch(chess.pgn()) == null, true);
  });
  test('PGN', () {
    bool passed = true;
    late String errorMessage;
    const List<Map<String, dynamic>> positions = <Map<String, dynamic>>[
      <String, dynamic>{
        'moves': <String>[
          'd4',
          'd5',
          'Nf3',
          'Nc6',
          'e3',
          'e6',
          'Bb5',
          'g5',
          'O-O',
          'Qf6',
          'Nc3',
          'Bd7',
          'Bxc6',
          'Bxc6',
          'Re1',
          'O-O-O',
          'a4',
          'Bb4',
          'a5',
          'b5',
          'axb6',
          'axb6',
          'Ra8+',
          'Kd7',
          'Ne5+',
          'Kd6',
          'Rxd8+',
          'Qxd8',
          'Nxf7+',
          'Ke7',
          'Nxd5+',
          'Qxd5',
          'c3',
          'Kxf7',
          'Qf3+',
          'Qxf3',
          'gxf3',
          'Bxf3',
          'cxb4',
          'e5',
          'dxe5',
          'Ke6',
          'b3',
          'Kxe5',
          'Bb2+',
          'Ke4',
          'Bxh8',
          'Nf6',
          'Bxf6',
          'h5',
          'Bxg5',
          'Bg2',
          'Kxg2',
          'Kf5',
          'Bh4',
          'Kg4',
          'Bg3',
          'Kf5',
          'e4+',
          'Kg4',
          'e5',
          'h4',
          'Bxh4',
          'Kxh4',
          'e6',
          'c5',
          'bxc5',
          'bxc5',
          'e7',
          'c4',
          'bxc4',
          'Kg4',
          'e8=Q',
          'Kf5',
          'Qe5+',
          'Kg4',
          'Re4#',
        ],
        'header': <String, String>{
          'White': 'Jeff Hlywa',
          'Black': 'Steve Bragg',
          'GreatestGameEverPlayed?': 'True',
        },
        'maxWidth': 19,
        'newlineChar': '<br />',
        'pgn':
            '[White "Jeff Hlywa"]<br />[Black "Steve Bragg"]<br />[GreatestGameEverPlayed? "True"]<br /><br />1. d4 d5 2. Nf3 Nc6<br />3. e3 e6 4. Bb5 g5<br />5. O-O Qf6<br />6. Nc3 Bd7<br />7. Bxc6 Bxc6<br />8. Re1 O-O-O<br />9. a4 Bb4 10. a5 b5<br />11. axb6 axb6<br />12. Ra8+ Kd7<br />13. Ne5+ Kd6<br />14. Rxd8+ Qxd8<br />15. Nxf7+ Ke7<br />16. Nxd5+ Qxd5<br />17. c3 Kxf7<br />18. Qf3+ Qxf3<br />19. gxf3 Bxf3<br />20. cxb4 e5<br />21. dxe5 Ke6<br />22. b3 Kxe5<br />23. Bb2+ Ke4<br />24. Bxh8 Nf6<br />25. Bxf6 h5<br />26. Bxg5 Bg2<br />27. Kxg2 Kf5<br />28. Bh4 Kg4<br />29. Bg3 Kf5<br />30. e4+ Kg4<br />31. e5 h4<br />32. Bxh4 Kxh4<br />33. e6 c5<br />34. bxc5 bxc5<br />35. e7 c4<br />36. bxc4 Kg4<br />37. e8=Q Kf5<br />38. Qe5+ Kg4<br />39. Re4#',
        'fen': '8/8/8/4Q3/2P1R1k1/8/5PKP/8 b - - 4 39',
      },
      <String, dynamic>{
        'moves': <String>[
          'c4',
          'e6',
          'Nf3',
          'd5',
          'd4',
          'Nf6',
          'Nc3',
          'Be7',
          'Bg5',
          'O-O',
          'e3',
          'h6',
          'Bh4',
          'b6',
          'cxd5',
          'Nxd5',
          'Bxe7',
          'Qxe7',
          'Nxd5',
          'exd5',
          'Rc1',
          'Be6',
          'Qa4',
          'c5',
          'Qa3',
          'Rc8',
          'Bb5',
          'a6',
          'dxc5',
          'bxc5',
          'O-O',
          'Ra7',
          'Be2',
          'Nd7',
          'Nd4',
          'Qf8',
          'Nxe6',
          'fxe6',
          'e4',
          'd4',
          'f4',
          'Qe7',
          'e5',
          'Rb8',
          'Bc4',
          'Kh8',
          'Qh3',
          'Nf8',
          'b3',
          'a5',
          'f5',
          'exf5',
          'Rxf5',
          'Nh7',
          'Rcf1',
          'Qd8',
          'Qg3',
          'Re7',
          'h4',
          'Rbb7',
          'e6',
          'Rbc7',
          'Qe5',
          'Qe8',
          'a4',
          'Qd8',
          'R1f2',
          'Qe8',
          'R2f3',
          'Qd8',
          'Bd3',
          'Qe8',
          'Qe4',
          'Nf6',
          'Rxf6',
          'gxf6',
          'Rxf6',
          'Kg8',
          'Bc4',
          'Kh8',
          'Qf4',
        ],
        'header': <String, String>{
          'Event': 'Reykjavik WCh',
          'Site': 'Reykjavik WCh',
          'Date': '1972.01.07',
          'EventDate': '?',
          'Round': '6',
          'Result': '1-0',
          'White': 'Robert James Fischer',
          'Black': 'Boris Spassky',
          'ECO': 'D59',
          'WhiteElo': '?',
          'BlackElo': '?',
          'PlyCount': '81',
        },
        'maxWidth': 65,
        'pgn':
            '[Event "Reykjavik WCh"]\n[Site "Reykjavik WCh"]\n[Date "1972.01.07"]\n[EventDate "?"]\n[Round "6"]\n[Result "1-0"]\n[White "Robert James Fischer"]\n[Black "Boris Spassky"]\n[ECO "D59"]\n[WhiteElo "?"]\n[BlackElo "?"]\n[PlyCount "81"]\n\n1. c4 e6 2. Nf3 d5 3. d4 Nf6 4. Nc3 Be7 5. Bg5 O-O 6. e3 h6\n7. Bh4 b6 8. cxd5 Nxd5 9. Bxe7 Qxe7 10. Nxd5 exd5 11. Rc1 Be6\n12. Qa4 c5 13. Qa3 Rc8 14. Bb5 a6 15. dxc5 bxc5 16. O-O Ra7\n17. Be2 Nd7 18. Nd4 Qf8 19. Nxe6 fxe6 20. e4 d4 21. f4 Qe7\n22. e5 Rb8 23. Bc4 Kh8 24. Qh3 Nf8 25. b3 a5 26. f5 exf5\n27. Rxf5 Nh7 28. Rcf1 Qd8 29. Qg3 Re7 30. h4 Rbb7 31. e6 Rbc7\n32. Qe5 Qe8 33. a4 Qd8 34. R1f2 Qe8 35. R2f3 Qd8 36. Bd3 Qe8\n37. Qe4 Nf6 38. Rxf6 gxf6 39. Rxf6 Kg8 40. Bc4 Kh8 41. Qf4 1-0',
        'fen': '4q2k/2r1r3/4PR1p/p1p5/P1Bp1Q1P/1P6/6P1/6K1 b - - 4 41',
      },
      <String, dynamic>{
        'moves': <String>[
          'f3',
          'e5',
          'g4',
          'Qh4#'
        ], // testing maxWidth being small and having no comments
        'maxWidth': 1,
        'pgn': '1. f3 e5\n2. g4 Qh4#',
        'fen': 'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3',
      },
      <String, dynamic>{
        'moves': <String>[
          'Ba5',
          'O-O',
          'd6',
          'd4'
        ], // testing a non-starting position
        'maxWidth': 20,
        'pgn':
            '[SetUp "1"]\n[FEN "r1bqk1nr/pppp1ppp/2n5/4p3/1bB1P3/2P2N2/P2P1PPP/RNBQK2R b KQkq - 0 1"]\n\n1. ... Ba5 2. O-O d6\n3. d4',
        'startingPosition':
            'r1bqk1nr/pppp1ppp/2n5/4p3/1bB1P3/2P2N2/P2P1PPP/RNBQK2R b KQkq - 0 1',
        'fen':
            'r1bqk1nr/ppp2ppp/2np4/b3p3/2BPP3/2P2N2/P4PPP/RNBQ1RK1 b kq d3 0 3',
      },
    ];

    for (int i = 0; i < positions.length; i++) {
      final Map<String, dynamic> position = positions[i];
      String failMessage = 'Position: $i';

      final Chess chess = position.containsKey('startingPosition')
          ? Chess.create(position['startingPosition'] as String)
          : Chess.create();

      final List<String> moves = position['moves'] as List<String>;

      passed = true;
      errorMessage = '';

      for (int j = 0; j < moves.length; j++) {
        if (chess.move(san: moves[j]) == null) {
          errorMessage = 'move() did not accept ${moves[j]} : ';
          break;
        }
      }

      final Map<String, String>? header =
          position['header'] as Map<String, String>?;

      if (header != null) {
        chess.header = header;
      }

      final String pgn = chess.pgn(
        maxWidth: position['maxWidth'] as int? ?? 0,
        newlineChar: position['newlineChar'] as String? ?? '\n',
      );

      final String fen = chess.fen();

      passed = pgn == position['pgn'] && fen == position['fen'];

      failMessage += '\nError message: $errorMessage';

      expect(
        passed && errorMessage.isEmpty,
        true,
        reason: failMessage,
      );
    }
  });
  group('Parse PGN Headers', () {
    test('Whitespace before closing bracket', () {
      const List<String> pgn = <String>[
        '[Event "Reykjavik WCh"]',
        '[Site "Reykjavik WCh"]',
        '[Date "1972.01.07" ]',
        '[EventDate "?"]',
        '[Round "6"]',
        '[Result "1-0"]',
        '[White "Robert James Fischer"]',
        '[Black "Boris Spassky"]',
        '[ECO "D59"]',
        '[WhiteElo "?"]',
        '[BlackElo "?"]',
        '[PlyCount "81"]',
        '',
        '1. c4 e6 2. Nf3 d5 3. d4 Nf6 4. Nc3 Be7 5. Bg5 O-O 6. e3 h6',
        '7. Bh4 b6 8. cxd5 Nxd5 9. Bxe7 Qxe7 10. Nxd5 exd5 11. Rc1 Be6',
        '12. Qa4 c5 13. Qa3 Rc8 14. Bb5 a6 15. dxc5 bxc5 16. O-O Ra7',
        '17. Be2 Nd7 18. Nd4 Qf8 19. Nxe6 fxe6 20. e4 d4 21. f4 Qe7',
        '22. e5 Rb8 23. Bc4 Kh8 24. Qh3 Nf8 25. b3 a5 26. f5 exf5',
        '27. Rxf5 Nh7 28. Rcf1 Qd8 29. Qg3 Re7 30. h4 Rbb7 31. e6 Rbc7',
        '32. Qe5 Qe8 33. a4 Qd8 34. R1f2 Qe8 35. R2f3 Qd8 36. Bd3 Qe8',
        '37. Qe4 Nf6 38. Rxf6 gxf6 39. Rxf6 Kg8 40. Bc4 Kh8 41. Qf4 1-0',
      ];

      final Chess chess = Chess.create();
      chess.loadPgn(pgn.join('\n'));
      expect(chess.header['Date'], '1972.01.07');
    });
  });
  group('Format Comments', () {
    test('wrap comments', () {
      final Chess chess = Chess.create();
      chess.move(san: 'e4');

      final String e4 = chess.fen();
      chess.setComment('good   move', e4);
      chess.move(san: 'e5');
      chess.setComment('classical response');

      expect(
        chess.pgn(),
        equals('1. e4 {good   move} e5 {classical response}'),
      );
      expect(
        chess.pgn(maxWidth: 16),
        equals(
          <String>[
            '1. e4 {good',
            'move} e5',
            '{classical',
            'response}',
          ].join('\n'),
        ),
      );
      expect(
        chess.pgn(maxWidth: 2),
        equals(
          <String>[
            '1.',
            'e4',
            '{good',
            'move}',
            'e5',
            '{classical',
            'response}'
          ].join('\n'),
        ),
      );
    });
  });
  group('Board Tests', () {
    const List<Map<String, dynamic>> tests = <Map<String, dynamic>>[
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        'board': <List<Map<String, dynamic>?>>[
          <Map<String, dynamic>?>[
            <String, dynamic>{'type': 'r', 'color': 'b'},
            <String, dynamic>{'type': 'n', 'color': 'b'},
            <String, dynamic>{'type': 'b', 'color': 'b'},
            <String, dynamic>{'type': 'q', 'color': 'b'},
            <String, dynamic>{'type': 'k', 'color': 'b'},
            <String, dynamic>{'type': 'b', 'color': 'b'},
            <String, dynamic>{'type': 'n', 'color': 'b'},
            <String, dynamic>{'type': 'r', 'color': 'b'},
          ],
          <Map<String, dynamic>?>[
            <String, dynamic>{'type': 'p', 'color': 'b'},
            <String, dynamic>{'type': 'p', 'color': 'b'},
            <String, dynamic>{'type': 'p', 'color': 'b'},
            <String, dynamic>{'type': 'p', 'color': 'b'},
            <String, dynamic>{'type': 'p', 'color': 'b'},
            <String, dynamic>{'type': 'p', 'color': 'b'},
            <String, dynamic>{'type': 'p', 'color': 'b'},
            <String, dynamic>{'type': 'p', 'color': 'b'},
          ],
          <Map<String, dynamic>?>[
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null
          ],
          <Map<String, dynamic>?>[
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null
          ],
          <Map<String, dynamic>?>[
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null
          ],
          <Map<String, dynamic>?>[
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null
          ],
          <Map<String, dynamic>?>[
            <String, dynamic>{'type': 'p', 'color': 'w'},
            <String, dynamic>{'type': 'p', 'color': 'w'},
            <String, dynamic>{'type': 'p', 'color': 'w'},
            <String, dynamic>{'type': 'p', 'color': 'w'},
            <String, dynamic>{'type': 'p', 'color': 'w'},
            <String, dynamic>{'type': 'p', 'color': 'w'},
            <String, dynamic>{'type': 'p', 'color': 'w'},
            <String, dynamic>{'type': 'p', 'color': 'w'},
          ],
          <Map<String, dynamic>>[
            <String, dynamic>{'type': 'r', 'color': 'w'},
            <String, dynamic>{'type': 'n', 'color': 'w'},
            <String, dynamic>{'type': 'b', 'color': 'w'},
            <String, dynamic>{'type': 'q', 'color': 'w'},
            <String, dynamic>{'type': 'k', 'color': 'w'},
            <String, dynamic>{'type': 'b', 'color': 'w'},
            <String, dynamic>{'type': 'n', 'color': 'w'},
            <String, dynamic>{'type': 'r', 'color': 'w'},
          ],
        ],
      },
      // checkmate
      <String, dynamic>{
        'fen': 'r3k2r/ppp2p1p/2n1p1p1/8/2B2P1q/2NPb1n1/PP4PP/R2Q3K w kq - 0 8',
        'board': <List<Map<String, dynamic>?>>[
          <Map<String, dynamic>?>[
            <String, dynamic>{'type': 'r', 'color': 'b'},
            null,
            null,
            null,
            <String, dynamic>{'type': 'k', 'color': 'b'},
            null,
            null,
            <String, dynamic>{'type': 'r', 'color': 'b'},
          ],
          <Map<String, dynamic>?>[
            <String, dynamic>{'type': 'p', 'color': 'b'},
            <String, dynamic>{'type': 'p', 'color': 'b'},
            <String, dynamic>{'type': 'p', 'color': 'b'},
            null,
            null,
            <String, dynamic>{'type': 'p', 'color': 'b'},
            null,
            <String, dynamic>{'type': 'p', 'color': 'b'},
          ],
          <Map<String, dynamic>?>[
            null,
            null,
            <String, dynamic>{'type': 'n', 'color': 'b'},
            null,
            <String, dynamic>{'type': 'p', 'color': 'b'},
            null,
            <String, dynamic>{'type': 'p', 'color': 'b'},
            null,
          ],
          <Map<String, dynamic>?>[
            null,
            null,
            null,
            null,
            null,
            null,
            null,
            null
          ],
          <Map<String, dynamic>?>[
            null,
            null,
            <String, dynamic>{'type': 'b', 'color': 'w'},
            null,
            null,
            <String, dynamic>{'type': 'p', 'color': 'w'},
            null,
            <String, dynamic>{'type': 'q', 'color': 'b'},
          ],
          <Map<String, dynamic>?>[
            null,
            null,
            <String, dynamic>{'type': 'n', 'color': 'w'},
            <String, dynamic>{'type': 'p', 'color': 'w'},
            <String, dynamic>{'type': 'b', 'color': 'b'},
            null,
            <String, dynamic>{'type': 'n', 'color': 'b'},
            null,
          ],
          <Map<String, dynamic>?>[
            <String, dynamic>{'type': 'p', 'color': 'w'},
            <String, dynamic>{'type': 'p', 'color': 'w'},
            null,
            null,
            null,
            null,
            <String, dynamic>{'type': 'p', 'color': 'w'},
            <String, dynamic>{'type': 'p', 'color': 'w'},
          ],
          <Map<String, dynamic>?>[
            <String, dynamic>{'type': 'r', 'color': 'w'},
            null,
            null,
            <String, dynamic>{'type': 'q', 'color': 'w'},
            null,
            null,
            null,
            <String, dynamic>{'type': 'k', 'color': 'w'},
          ],
        ],
      },
    ];

    for (final Map<String, dynamic> t in tests) {
      test('Board - ${t['fen'] as String? ?? ''}', () {
        final Chess chess = Chess.create(t['fen'] as String);

        // The board is presented using the enum [Piece] but for testing we need
        // to convert it to json, so first we need to convert to Map<String, String?>.
        Map<String, String>? parseBoardSquareToMap(Piece? e) => e == null
            ? null
            : <String, String>{
                'type': e.symbol.notation,
                'color': e.color.notation,
              };

        List<Map<String, String>?> parseBoardRankToMap(List<Piece?> e) =>
            e.map(parseBoardSquareToMap).toList();

        final List<List<Map<String, String>?>> parsedBoard =
            chess.board().map(parseBoardRankToMap).toList();

        expect(jsonEncode(parsedBoard) == jsonEncode(t['board']), true);
      });
    }
  });
  group('Load Comments', () {
    const List<Map<String, dynamic>> tests = <Map<String, dynamic>>[
      <String, dynamic>{
        'name': 'bracket comments',
        'input': '1. e4 {good move} e5 {classical response}',
        'output': '1. e4 {good move} e5 {classical response}',
      },
      <String, dynamic>{
        'name': 'semicolon comments',
        'input': '1. e4 e5; romantic era\n 2. Nf3 Nc6; common continuation',
        'output': '1. e4 e5 {romantic era} 2. Nf3 Nc6 {common continuation}',
      },
      <String, dynamic>{
        'name': 'bracket and semicolon comments',
        'input': '1. e4 {good!} e5; standard response\n 2. Nf3 Nc6 {common}',
        'output': '1. e4 {good!} e5 {standard response} 2. Nf3 Nc6 {common}',
      },
      <String, dynamic>{
        'name': 'bracket comments with newlines',
        'input': '1. e4 {good\nmove} e5 {classical\nresponse}',
        'output': '1. e4 {good move} e5 {classical response}',
      },
      <String, dynamic>{
        'name': 'initial comment',
        'input': '{ great game }\n1. e4 e5',
        'output': '{ great game } 1. e4 e5',
      },
      <String, dynamic>{
        'name': 'empty bracket comment',
        'input': '1. e4 {}',
        'output': '1. e4 {}',
      },
      <String, dynamic>{
        'name': 'empty semicolon comment',
        'input': '1. e4;\ne5',
        'output': '1. e4 {} e5',
      },
      <String, dynamic>{
        'name': 'unicode comment',
        'input': '1. e4 {Δ, Й, ק ,م, ๗, あ, 叶, 葉, and 말}',
        'output': '1. e4 {Δ, Й, ק ,م, ๗, あ, 叶, 葉, and 말}',
      },
      <String, dynamic>{
        'name': 'semicolon in bracket comment',
        'input': '1. e4 { a classic; well-studied } e5',
        'output': '1. e4 { a classic; well-studied } e5',
      },
      <String, dynamic>{
        'name': 'bracket in semicolon comment',
        'input': '1. e4 e5 ; a classic {well-studied}',
        'output': '1. e4 e5 {a classic {well-studied}}',
      },
      <String, dynamic>{
        'name': 'markers in bracket comment',
        'input': r'1. e4 e5 {($1) 1. e4 is good}',
        'output': r'1. e4 e5 {($1) 1. e4 is good}',
      },
      <String, dynamic>{
        'name': 'markers in semicolon comment',
        'input': r'1. e4 e5; ($1) 1. e4 is good',
        'output': r'1. e4 e5 {($1) 1. e4 is good}',
      },
    ];

    for (final Map<String, dynamic> t in tests) {
      test('load ${t['name']}', () {
        final Chess chess = Chess.create();
        chess.loadPgn(t['input'] as String);
        expect(chess.pgn(), equals(t['output'] as String));
      });
    }
  });
  test('Validate FEN', () {
    const List<Map<String, dynamic>> positions = <Map<String, dynamic>>[
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNRw KQkq - 0 1',
        'errorNumber': 1,
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 x',
        'errorNumber': 2,
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 0',
        'errorNumber': 2,
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 -1',
        'errorNumber': 2,
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - x 1',
        'errorNumber': 3,
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - -1 1',
        'errorNumber': 3,
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq e2 0 1',
        'errorNumber': 4,
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq e7 0 1',
        'errorNumber': 4,
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq x 0 1',
        'errorNumber': 4,
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQxkq - 0 1',
        'errorNumber': 5,
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w kqKQ - 0 1',
        'errorNumber': 5,
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR ? KQkq - 0 1',
        'errorNumber': 6,
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP w KQkq - 0 1',
        'errorNumber': 7
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/17/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        'errorNumber': 8,
      },
      <String, dynamic>{
        'fen': 'rnbqk?nr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        'errorNumber': 9,
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/7/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        'errorNumber': 10,
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/p1p1p1p1p/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        'errorNumber': 10,
      },
      <String, dynamic>{
        'fen': 'r1bqkbnr/2pppppp/n7/1p6/8/4P3/PPPP1PPP/RNBQK1NR b KQkq b6 0 4',
        'errorNumber': 11,
      },
      <String, dynamic>{
        'fen':
            'rnbqkbnr/1p1ppppp/B1p5/8/6P1/4P3/PPPP1P1P/RNBQK1NR w KQkq g3 0 3',
        'errorNumber': 11,
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppp1ppp/8/4p3/2P5/8/PP1PPPPP/RNBQKBNR w KQkq e6 0 2',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            '3r2k1/p1q2pp1/2nr1n1p/2p1p3/4P2B/P1P2Q1P/B4PP1/1R2R1K1 b - - 3 20',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': 'r2q1rk1/3bbppp/p3pn2/1p1pB3/3P4/1QNBP3/PP3PPP/R4RK1 w - - 4 13',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'rnbqk2r/ppp1bppp/4pn2/3p4/2PP4/2N2N2/PP2PPPP/R1BQKB1R w KQkq - 1 5',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '1k1rr3/1p5p/p1Pp2q1/3nppp1/PB6/3P4/3Q1PPP/1R3RK1 b - - 0 28',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r3r1k1/3n1pp1/2q1p2p/2p5/p1p2P2/P3P2P/1PQ2BP1/1R2R1K1 w - - 0 27',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': 'r3rbk1/1R3p1p/3Pq1p1/6B1/p6P/5Q2/5PP1/3R2K1 b - - 3 26',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r1bqkb1r/1ppp1ppp/p1n2n2/4p3/B3P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 5',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r1b2rk1/4bppp/p1np4/q3p1P1/1p2P2P/4BP2/PPP1N1Q1/1K1R1B1R w - - 0 17',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r2q1rk1/ppp1bppp/2np1nb1/4p3/P1B1P1P1/3P1N1P/1PP2P2/RNBQR1K1 w - - 1 10',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r2qkb1r/pb1n1p2/4pP2/1ppP2B1/2p5/2N3P1/PP3P1P/R2QKB1R b KQkq - 0 13',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '3k1b1r/p2n1p2/5P2/2pN4/P1p2B2/1p3qP1/1P2KP2/3R4 w - - 0 29',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'rnbq1rk1/1pp1ppbp/p2p1np1/8/2PPP3/2N1BP2/PP2N1PP/R2QKB1R b KQ - 1 7',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'rn1qkb1r/pb1p1ppp/1p2pn2/4P3/2Pp4/5NP1/PP1N1PBP/R1BQK2R b KQkq - 0 8',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'rnbqkbnr/pp1p1ppp/4p3/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 0 3',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r1bq1rk1/pp2ppbp/3p1np1/8/3pPP2/3B4/PPPPN1PP/R1BQ1RK1 w - - 4 10',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': 'r1b3k1/5pbp/2N1p1p1/p6q/2p2P2/2P1B3/PPQ3PP/3R2K1 b - - 0 22',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': 'rnbqkb1r/ppp1pppp/3p1n2/8/3PP3/8/PPP2PPP/RNBQKBNR w KQkq - 1 3',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r1bqkb1r/pppp1ppp/2n2n2/4p3/2PP4/2N2N2/PP2PPPP/R1BQKB1R b KQkq d3 0 4',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r1bqk2r/ppp1bppp/2n5/3p4/3Pn3/3B1N2/PPP2PPP/RNBQ1RK1 w kq - 4 8',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '4kb1r/1p3pp1/p3p3/4P1BN/1n1p1PPP/PR6/1P4r1/1KR5 b k - 0 24',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r3kb1r/pbpp1ppp/1qp1n3/4P3/2P5/1N2Q3/PP1B1PPP/R3KB1R w KQkq - 7 13',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': 'r1b1r1k1/p4p1p/2pb2p1/3pn3/N7/4BP2/PPP2KPP/3RRB2 b - - 3 18',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': 'r1b2rk1/p2nqp1p/3P2p1/2p2p2/2B5/1PB3N1/P4PPP/R2Q2K1 b - - 0 18',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'rnb1k2r/1p3ppp/p3Pn2/8/3N2P1/2q1B3/P1P1BP1P/R2Q1K1R b kq - 1 12',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'rnb1k2r/1pq1bppp/p2ppn2/8/3NPP2/2N1B3/PPP1B1PP/R2QK2R w KQkq - 1 9',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '4r3/1pr3pk/p2p2q1/3Pppbp/8/1NPQ1PP1/PP2R2P/1K1R4 w - - 8 28',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': 'b2r3r/4kp2/p3p1p1/1p2P3/1P1n1P2/P1NB4/KP4P1/3R2R1 b - - 2 26',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'rnbqk2r/ppppppbp/5np1/8/2PPP3/2N5/PP3PPP/R1BQKBNR b KQkq e3 0 4',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'rn1q1rk1/pbp2pp1/1p3b1p/3p4/3P4/2NBPN2/PP3PPP/2RQK2R b K - 1 11',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            '2rq1rk1/pp1bppbp/3p1np1/8/2BNP3/2N1BP2/PPPQ2PP/1K1R3R b - - 0 13',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r2qkb1r/1p1bpppp/p1np4/6B1/B3P1n1/2PQ1N2/PP3PPP/RN2R1K1 b kq - 0 10',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': 'r1bq1rk1/1p2npb1/p6p/3p2p1/3P3B/2N5/PP2BPPP/R2QR1K1 w - - 0 15',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r3r1k1/pbq1bppp/4pnn1/2p1B1N1/2P2P2/1P1B2N1/P3Q1PP/4RRK1 b - - 4 17',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '4k3/5p2/p1q1pbp1/1pr1P3/3n1P2/1B2B2Q/PP3P2/3R3K w - - 1 28',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '2k4r/pp1r1p1p/8/2Pq1p2/1Pn2P2/PQ3NP1/3p1NKP/R7 b - - 0 28',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'rnbqkb1r/ppp2ppp/3p1n2/4N3/4P3/8/PPPP1PPP/RNBQKB1R w KQkq - 0 4',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '3r1rk1/Qpp2p1p/7q/1P2P1p1/2B1Rn2/6NP/P4P1P/5RK1 b - - 0 22',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'rn2kb1r/2qp1ppp/b3pn2/2pP2B1/1pN1P3/5P2/PP4PP/R2QKBNR w KQkq - 4 11',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r3k2r/pp1nbp1p/2p2pb1/3p4/3P3N/2N1P3/PP3PPP/R3KB1R w KQkq - 4 12',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'rn1qr1k1/pbppbppp/1p3n2/3P4/8/P1N1P1P1/1P2NPBP/R1BQK2R b KQ - 2 10',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r1bqk2r/pp1nbppp/2p2n2/3p2B1/3P4/2N1PN2/PP3PPP/R2QKB1R w KQkq - 1 8',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r1bqk2r/pppp1pp1/2n2n1p/8/1bPN3B/2N5/PP2PPPP/R2QKB1R b KQkq - 1 7',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r1bqk2r/1pppbppp/p1n2n2/4p3/B3P3/5N2/PPPP1PPP/RNBQ1RK1 w kq - 4 6',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r1b1kb1r/p2p1ppp/1qp1p3/3nP3/2P1NP2/8/PP4PP/R1BQKB1R b KQkq c3 0 10',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '8/R7/2b5/3k2K1/P1p1r3/2B5/1P6/8 b - - 8 74',
        'errorNumber': 0
      },
      <String, dynamic>{
        'fen': '2q5/5pk1/5p1p/4b3/1p1pP3/7P/1Pr3P1/R2Q1RK1 w - - 14 37',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': 'r4rk1/1bqnbppp/p2p4/1p2p3/3BPP2/P1NB4/1PP3PP/3RQR1K w - - 0 16',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r1bqk2r/pp1n1ppp/2pbpn2/6N1/3P4/3B1N2/PPP2PPP/R1BQK2R w KQkq - 2 8',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r1b1kb1r/pp3ppp/1qnppn2/8/2B1PB2/1NN5/PPP2PPP/R2QK2R b KQkq - 1 8',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '1r3r1k/2q1n1pb/pn5p/1p2pP2/6B1/PPNRQ2P/2P1N1P1/3R3K b - - 0 28',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'rnbqk2r/ppp1bppp/4pn2/3p2B1/2PP4/2N2N2/PP2PPPP/R2QKB1R b KQkq - 3 5',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '2r3k1/5pp1/p2p3p/1p1Pp2P/5b2/8/qP1K2P1/3QRB1R w - - 0 26',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '6k1/1Q3p2/2p1r3/B1Pn2p1/3P1b1p/5P1P/5P2/5K2 w - - 6 47',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '8/k7/Pr2R3/7p/8/4n1P1/1r2p1P1/4R1K1 w - - 0 59',
        'errorNumber': 0
      },
      <String, dynamic>{
        'fen': '8/3k4/1nbPp2p/1pK2np1/p7/PP1R1P2/2P4P/4R3 b - - 7 34',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '4rbk1/rnR2p1p/pp2pnp1/3p4/3P4/1P2PB1P/P2BNPP1/R5K1 b - - 0 20',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '5r2/6pk/8/p3P1p1/1R6/7Q/1Pr2P1K/2q5 b - - 2 48',
        'errorNumber': 0
      },
      <String, dynamic>{
        'fen':
            '1br2rk1/2q2pp1/p3bnp1/1p1p4/8/1PN1PBPP/PB1Q1P2/R2R2K1 b - - 0 19',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '4r1k1/b4p2/p4pp1/1p6/3p1N1P/1P2P1P1/P4P2/3R2K1 w - - 0 30',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '3rk3/1Q4p1/p3p3/4RPqp/4p2P/P7/KPP5/8 b - h3 0 33',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '6k1/1p1r1pp1/5qp1/p1pBP3/Pb3n2/1Q1RB2P/1P3PP1/6K1 b - - 0 28',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '3r2k1/pp2bp2/1q4p1/3p1b1p/4PB1P/2P2PQ1/P2R2P1/3R2K1 w - - 1 28',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '3r4/p1qn1pk1/1p1R3p/2P1pQpP/8/4B3/5PP1/6K1 w - - 0 35',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'rnb1k1nr/pp2q1pp/2pp4/4pp2/2PPP3/8/PP2NPPP/R1BQKB1R w KQkq f6 0 8',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pp1ppppp/2p5/8/3PP3/8/PPP2PPP/RNBQKBNR b KQkq d3 0 2',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '4q1k1/6p1/p2rnpPp/1p2p3/7P/1BP5/PP3Q2/1K3R2 w - - 0 34',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            '3r2k1/p1q2pp1/1n2rn1p/1B2p3/P1p1P3/2P3BP/4QPP1/1R2R1K1 b - - 1 25',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '8/p7/1b2BkR1/5P2/4K3/7r/P7/8 b - - 9 52',
        'errorNumber': 0
      },
      <String, dynamic>{
        'fen': '2rq2k1/p4p1p/1p1prp2/1Ppb4/8/P1QPP1P1/1B3P1P/R3R1K1 w - - 2 20',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '8/1pQ3bk/p2p1qp1/P2Pp2p/NP6/7P/5PP1/6K1 w - - 1 36',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '8/1pQ3bk/p2p2p1/P2Pp2p/1P5P/2N3P1/2q2PK1/8 b - - 0 39',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r1bq1rk1/pp2n1bp/2pp1np1/3PppN1/1PP1P3/2N2B2/P4PPP/R1BQR1K1 w - - 0 13',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '1r4k1/5p2/3P2pp/p3Pp2/5q2/2Q2P1P/5P2/4R1K1 w - - 0 29',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pp2pppp/3p4/8/3pP3/5N2/PPP2PPP/RNBQKB1R w KQkq - 0 4',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'R2qk2r/2p2ppp/1bnp1n2/1p2p3/3PP1b1/1BP2N2/1P3PPP/1NBQ1RK1 b k - 0 11',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '6k1/4qp2/3p2p1/3Pp2p/7P/4Q1P1/5PBK/8 b - - 20 57',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '3k4/r3q3/3p1p2/2pB4/P7/7P/6P1/1Q4K1 b - - 6 43',
        'errorNumber': 0
      },
      <String, dynamic>{
        'fen': '5k2/1n4p1/2p2p2/p2q1B1P/P4PK1/6P1/1Q6/8 b - - 4 46',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '6k1/pr2pb2/5pp1/1B1p4/P7/4QP2/1PP3Pq/2KR4 w - - 1 27',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            '1rbqk2r/2pp1ppp/2n2n2/1pb1p3/4P3/1BP2N2/1P1P1PPP/RNBQ1RK1 b k - 0 9',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '6r1/2p5/pbpp1k1r/5b2/3P1N1p/1PP2N1P/P4R2/2K1R3 w - - 4 33',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': 'rnbqkb1r/pppppppp/5n2/8/3P4/5N2/PPP1PPPP/RNBQKB1R b KQkq - 2 2',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': 'rnbqkb1r/pppppppp/5n2/8/2PP4/8/PP2PPPP/RNBQKBNR b KQkq c3 0 2',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '4b3/5p1k/r7/p3BNQp/4P1pP/1r1n4/1P3P1N/7K b - - 2 40',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r2q1rk1/pb1p2pp/1p1bpnn1/5p2/2PP4/PPN1BP1P/2B1N1P1/1R1Q1R1K b - - 2 16',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/ppp1pppp/8/8/2pP4/5N2/PP2PPPP/RNBQKB1R b KQkq - 1 3',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '4rrk1/8/p1pR4/1p6/1PPKNq2/3P1p2/PB5n/R2Q4 b - - 6 40',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r1bqk1nr/1p2bppp/p1np4/4p3/2P1P3/N1N5/PP3PPP/R1BQKB1R b KQkq - 1 8',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r1bqk2r/pp2bppp/2n1p3/3n4/3P4/2NB1N2/PP3PPP/R1BQ1RK1 b kq - 3 9',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r1bqkbnr/pppp2pp/2n5/1B2p3/3Pp3/5N2/PPP2PPP/RNBQK2R w KQkq - 0 5',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '2n1r3/p1k2pp1/B1p3b1/P7/5bP1/2N1B3/1P2KP2/2R5 b - - 4 25',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': 'r4rk1/2q3pp/4p3/p1Pn1p2/1p1P4/4PP2/1B1Q2PP/R3R1K1 w - - 0 22',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '8/8/1p6/3b4/1P1k1p2/8/3KBP2/8 w - - 2 68',
        'errorNumber': 0
      },
      <String, dynamic>{
        'fen': '2b2k2/1p5p/2p5/p1p1q3/2PbN3/1P5P/P5B1/3RR2K w - - 4 33',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '1b6/5kp1/5p2/1b1p4/1P6/4PPq1/2Q2RNp/7K b - - 2 41',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen':
            'r3r1k1/p2nqpp1/bpp2n1p/3p4/B2P4/P1Q1PP2/1P2NBPP/R3K2R w KQ - 6 16',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': 'r3k2r/8/p4p2/3p2p1/4b3/2R2PP1/P6P/4R1K1 b kq - 0 27',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': 'r1rb2k1/5ppp/pqp5/3pPb2/QB1P4/2R2N2/P4PPP/2R3K1 b - - 7 23',
        'errorNumber': 0,
      },
      <String, dynamic>{
        'fen': '3r1r2/3P2pk/1p1R3p/1Bp2p2/6q1/4Q3/PP3P1P/7K w - - 4 30',
        'errorNumber': 0,
      },
    ];

    for (int i = 0; i < positions.length; i++) {
      final Map<String, dynamic> position = positions[i];

      final String failMessage =
          'Index: $i, ${position['fen'] as String} (valid: ${(position['errorNumber'] as int) == 0})';

      final FenValidation? result =
          validateFenStructure(position['fen'] as String);

      if (result == null) {
        expect(position['errorNumber'], equals(0), reason: failMessage);
      } else {
        expect(
          result.errorCode,
          position['errorNumber'],
          reason: failMessage,
        );
      }
    }
  });
  test('Make Move', () {
    const List<Map<String, dynamic>> positions = <Map<String, dynamic>>[
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        'legal': true,
        'move': 'e4',
        'next': 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        'legal': false,
        'move': 'e5',
      },
      <String, dynamic>{
        'fen': '7k/3R4/3p2Q1/6Q1/2N1N3/8/8/3R3K w - - 0 1',
        'legal': true,
        'move': 'Rd8#',
        'next': '3R3k/8/3p2Q1/6Q1/2N1N3/8/8/3R3K b - - 1 1',
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pp3ppp/2pp4/4pP2/4P3/8/PPPP2PP/RNBQKBNR w KQkq e6 0 1',
        'legal': true,
        'move': 'fxe6',
        'next': 'rnbqkbnr/pp3ppp/2ppP3/8/4P3/8/PPPP2PP/RNBQKBNR b KQkq - 0 1',
        'captured': 'p',
      },
      <String, dynamic>{
        'fen': 'rnbqkbnr/pppp2pp/8/4p3/4Pp2/2PP4/PP3PPP/RNBQKBNR b KQkq e3 0 1',
        'legal': true,
        'move': 'fxe3',
        'next': 'rnbqkbnr/pppp2pp/8/4p3/8/2PPp3/PP3PPP/RNBQKBNR w KQkq - 0 2',
        'captured': 'p',
      },

      // strict move parser
      <String, dynamic>{
        'fen': 'r2qkbnr/ppp2ppp/2n5/1B2pQ2/4P3/8/PPP2PPP/RNB1K2R b KQkq - 3 7',
        'legal': true,
        'next':
            'r2qkb1r/ppp1nppp/2n5/1B2pQ2/4P3/8/PPP2PPP/RNB1K2R w KQkq - 4 8',
        'move': 'Ne7',
      },

      // strict move parser should reject over disambiguation
      <String, dynamic>{
        'fen': 'r2qkbnr/ppp2ppp/2n5/1B2pQ2/4P3/8/PPP2PPP/RNB1K2R b KQkq - 3 7',
        'legal': false,
        'move': 'Nge7',
      },

      // sloppy move parser
      <String, dynamic>{
        'fen': 'r2qkbnr/ppp2ppp/2n5/1B2pQ2/4P3/8/PPP2PPP/RNB1K2R b KQkq - 3 7',
        'legal': true,
        'sloppy': true,
        'move': 'Nge7',
        'next':
            'r2qkb1r/ppp1nppp/2n5/1B2pQ2/4P3/8/PPP2PPP/RNB1K2R w KQkq - 4 8',
      },

      // the sloppy parser should still accept correctly disambiguated moves
      <String, dynamic>{
        'fen': 'r2qkbnr/ppp2ppp/2n5/1B2pQ2/4P3/8/PPP2PPP/RNB1K2R b KQkq - 3 7',
        'legal': true,
        'sloppy': true,
        'move': 'Ne7',
        'next':
            'r2qkb1r/ppp1nppp/2n5/1B2pQ2/4P3/8/PPP2PPP/RNB1K2R w KQkq - 4 8',
      },
    ];

    for (final Map<String, dynamic> position in positions) {
      final Chess chess = Chess.create();
      chess.load(position['fen'] as String);

      final String failMessage =
          '${position['fen'] as String} (${position['move'] as String} ${position['legal'] as bool})';

      final bool sloppy = (position['sloppy'] as bool?) ?? false;
      final Move? result =
          chess.move(san: position['move'] as String, sloppy: sloppy);

      if (position['legal'] as bool) {
        expect(result, isNotNull, reason: failMessage);
        expect(chess.fen(), equals(position['next']), reason: failMessage);
        expect(
          result!.captured?.notation,
          equals(position['captured']),
          reason: failMessage,
        );
      } else {
        expect(
          result,
          isNull,
          reason: failMessage,
        );
      }
    }
  });

  group('Regression Tests', () {
    test('Github Issue #32 - castling flag reappearing', () {
      final Chess chess =
          Chess.create('b3k2r/5p2/4p3/1p5p/6p1/2PR2P1/BP3qNP/6QK b k - 2 28');

      chess.move(from: Square.a8, to: Square.g2);

      expect(
        chess.fen() == '4k2r/5p2/4p3/1p5p/6p1/2PR2P1/BP3qbP/6QK w k - 0 29',
        true,
      );
    });

    test('Github Issue #58 - placing more than one king', () {
      final Chess chess = Chess.create('N3k3/8/8/8/8/8/5b2/4K3 w - - 0 1');

      expect(
        chess.put(Piece.fromSymbolAndColorChar('kw')!, 'a1'),
        false,
      );

      chess.put(Piece.fromSymbolAndColorChar('qw')!, 'a1');
      chess.remove('a1');

      expect(
        chess.moves().map((Move e) => e.san).join(' '),
        'Kd2 Ke2 Kxf2 Kf1 Kd1',
      );
    });

    test(
        'Github Issue #85 (white) - SetUp and FEN should be accepted in loadPgn',
        () {
      final Chess chess = Chess.create();

      const List<String> pgn = <String>[
        '[SetUp "1"]',
        '[FEN "7k/5K2/4R3/8/8/8/8/8 w KQkq - 0 1"]',
        '',
        '1. Rh6#',
      ];

      final bool result = chess.loadPgn(pgn.join('\n'));

      expect(result, true);
      expect(chess.fen(), '7k/5K2/7R/8/8/8/8/8 b KQkq - 1 1');
    });

    test(
        'Github Issue #85 (black) - SetUp and FEN should be accepted in loadPgn',
        () {
      final Chess chess = Chess.create();

      const List<String> pgn = <String>[
        '[SetUp "1"]',
        '[FEN "r4r1k/1p4b1/3p3p/5qp1/1RP5/6P1/3NP3/2Q2RKB b KQkq - 0 1"]',
        '',
        '1. ... Qc5+',
      ];

      final bool result = chess.loadPgn(pgn.join('\n'));

      expect(result, true);
      expect(
        chess.fen(),
        'r4r1k/1p4b1/3p3p/2q3p1/1RP5/6P1/3NP3/2Q2RKB w KQkq - 1 2',
      );
    });

    test(
      'Github Issue #98 (white) - Wrong movement number after setting a position via FEN',
      () {
        final Chess chess = Chess.create();
        chess.load('4r3/8/2p2PPk/1p6/pP2p1R1/P1B5/2P2K2/3r4 w - - 1 45');
        chess.move(san: 'f7');

        final String result = chess.pgn();

        final RegExpMatch? match = RegExp(r'(45\. f7)$').firstMatch(result);
        expect(match, isNotNull);
        expect(result.substring(match!.start, match.end), '45. f7');
      },
    );

    test(
      'Github Issue #98 (black) - Wrong movement number after setting a position via FEN',
      () {
        final Chess chess = Chess.create();
        chess.load('4r3/8/2p2PPk/1p6/pP2p1R1/P1B5/2P2K2/3r4 b - - 1 45');
        chess.move(san: 'Rf1+');
        final String result = chess.pgn();
        final RegExpMatch? match =
            RegExp(r'(45\. \.\.\. Rf1\+)$').firstMatch(result);
        expect(match, isNotNull);
        expect(result.substring(match!.start, match.end), '45. ... Rf1+');
      },
    );

    test(
        'Github Issue #129 loadPgn() should not clear headers if PGN contains SetUp and FEN tags',
        () {
      const List<String> pgn = <String>[
        '[Event "Test Olympiad"]',
        '[Site "Earth"]',
        '[Date "????.??.??"]',
        '[Round "6"]',
        '[White "Testy"]',
        '[Black "McTest"]',
        '[Result "*"]',
        '[FEN "rnbqkb1r/1p3ppp/p2ppn2/6B1/3NP3/2N5/PPP2PPP/R2QKB1R w KQkq - 0 1"]',
        '[SetUp "1"]',
        '',
        '1.Qd2 Be7 *',
      ];

      final Chess chess = Chess.create();

      expect(chess.loadPgn(pgn.join('\n')), true);

      const Map<String, String> expected = <String, String>{
        'Event': 'Test Olympiad',
        'Site': 'Earth',
        'Date': '????.??.??',
        'Round': '6',
        'White': 'Testy',
        'Black': 'McTest',
        'Result': '*',
        'FEN':
            'rnbqkb1r/1p3ppp/p2ppn2/6B1/3NP3/2N5/PPP2PPP/R2QKB1R w KQkq - 0 1',
        'SetUp': '1',
      };

      expect(chess.header, equals(expected));
    });

    test(
        'Github Issue #129 clear() should clear the board and delete all headers with the exception of SetUp and FEN',
        () {
      const List<String> pgn = <String>[
        '[Event "Test Olympiad"]',
        '[Site "Earth"]',
        '[Date "????.??.??"]',
        '[Round "6"]',
        '[White "Testy"]',
        '[Black "McTest"]',
        '[Result "*"]',
        '[FEN "rnbqkb1r/1p3ppp/p2ppn2/6B1/3NP3/2N5/PPP2PPP/R2QKB1R w KQkq - 0 1"]',
        '[SetUp "1"]',
        '',
        '1.Qd2 Be7 *',
      ];

      final Chess chess = Chess.create();

      expect(chess.loadPgn(pgn.join('\n')), true);

      chess.clear();

      const Map<String, String> expected = <String, String>{
        'FEN': '8/8/8/8/8/8/8/8 w - - 0 1',
        'SetUp': '1',
      };

      expect(chess.header, equals(expected));
    });
  });

  group('Manipulate Comments', () {
    Map<String, String> parseFenCommentToMap(FenComment e) =>
        <String, String>{'fen': e.fen, 'comment': e.comment};

    test(
      'no comments',
      () {
        final Chess chess = Chess.create();

        expect(chess.getComment(), isNull);
        expect(chess.getComments(), equals(<FenComment>[]));

        chess.move(san: 'e4');
        expect(chess.getComment(), isNull);
        expect(chess.getComments(), equals(<FenComment>[]));
        expect(chess.pgn(), '1. e4');
      },
    );

    test('comment for initial position', () {
      final Chess chess = Chess.create();
      final String fen = chess.fen();
      chess.setComment('starting position');
      expect(chess.getComment(), 'starting position');
      expect(chess.getComment(fen), 'starting position');
      expect(
        chess.getComments().map(parseFenCommentToMap).toList(),
        equals(<Map<String, String>>[
          <String, String>{'fen': chess.fen(), 'comment': 'starting position'},
        ]),
      );
      expect(chess.pgn(), '{starting position}');
    });

    test('comment for first move', () {
      final Chess chess = Chess.create();
      chess.move(san: 'e4');

      final String e4 = chess.fen();
      chess.setComment('good move');

      expect(chess.getComment(), 'good move');
      expect(chess.getComment(e4), 'good move');
      expect(
        chess.getComments().map(parseFenCommentToMap).toList(),
        equals(
          <Map<String, String>>[
            <String, String>{'fen': e4, 'comment': 'good move'}
          ],
        ),
      );

      chess.move(san: 'e5');

      expect(chess.getComment(), isNull);
      expect(chess.getComment(e4), 'good move');
      expect(
        chess.getComments().map(parseFenCommentToMap).toList(),
        equals(
          <Map<String, String>>[
            <String, String>{'fen': e4, 'comment': 'good move'}
          ],
        ),
      );
      expect(chess.pgn(), '1. e4 {good move} e5');
    });

    test('comment for last move', () {
      final Chess chess = Chess.create();
      chess.move(san: 'e4');
      chess.move(san: 'e6');
      final String e6 = chess.fen();
      chess.setComment('dubious move');
      expect(chess.getComment(), 'dubious move');
      expect(chess.getComment(e6), 'dubious move');
      expect(
        chess.getComments().map(parseFenCommentToMap).toList(),
        equals(
          <Map<String, String>>[
            <String, String>{'fen': chess.fen(), 'comment': 'dubious move'},
          ],
        ),
      );
      expect(chess.pgn(), '1. e4 e6 {dubious move}');
    });

    test('comment with brackets', () {
      final Chess chess = Chess.create();
      chess.setComment('{starting position}');
      expect(chess.getComment(), '[starting position]');
    });

    test('comments for everything', () {
      final Chess chess = Chess.create();

      final String initial = chess.fen();
      chess.setComment('starting position');
      expect(chess.getComment(), 'starting position');
      expect(
        chess.getComments().map(parseFenCommentToMap).toList(),
        equals(
          <Map<String, String>>[
            <String, String>{'fen': initial, 'comment': 'starting position'},
          ],
        ),
      );
      expect(chess.pgn(), '{starting position}');

      chess.move(san: 'e4');
      final String e4 = chess.fen();
      chess.setComment('good move');
      expect(chess.getComment(), 'good move');
      expect(chess.getComment(e4), 'good move');
      expect(
        chess.getComments().map(parseFenCommentToMap).toList(),
        equals(
          <Map<String, String>>[
            <String, String>{'fen': initial, 'comment': 'starting position'},
            <String, String>{'fen': e4, 'comment': 'good move'},
          ],
        ),
      );
      expect(chess.pgn(), '{starting position} 1. e4 {good move}');

      chess.move(san: 'e6');
      final String e6 = chess.fen();
      chess.setComment('dubious move');
      expect(chess.getComment(), 'dubious move');
      expect(chess.getComment(e6), 'dubious move');
      expect(
        chess.getComments().map(parseFenCommentToMap).toList(),
        equals(
          <Map<String, String>>[
            <String, String>{'fen': initial, 'comment': 'starting position'},
            <String, String>{'fen': e4, 'comment': 'good move'},
            <String, String>{'fen': e6, 'comment': 'dubious move'},
          ],
        ),
      );
      expect(
        chess.pgn(),
        '{starting position} 1. e4 {good move} e6 {dubious move}',
      );
    });

    test('delete comments', () {
      final Chess chess = Chess.create();
      final String init = chess.fen();
      expect(chess.deleteComment(), isNull);
      expect(chess.deleteComment(init), isNull);
      expect(chess.deleteComments(), equals(<FenComment>[]));

      final String initial = chess.fen();
      chess.setComment('starting position');
      chess.move(san: 'e4');
      final String e4 = chess.fen();
      chess.setComment('good move');
      chess.move(san: 'e6');
      final String e6 = chess.fen();
      chess.setComment('dubious move');

      expect(
        chess.getComments().map(parseFenCommentToMap).toList(),
        equals(
          <Map<String, dynamic>>[
            <String, dynamic>{'fen': initial, 'comment': 'starting position'},
            <String, dynamic>{'fen': e4, 'comment': 'good move'},
            <String, dynamic>{'fen': e6, 'comment': 'dubious move'},
          ],
        ),
      );
      expect(chess.deleteComment(e6), 'dubious move');
      expect(chess.pgn(), '{starting position} 1. e4 {good move} e6');
      expect(chess.deleteComment(), isNull);
      expect(
        chess.deleteComments().map(parseFenCommentToMap).toList(),
        equals(
          <Map<String, String>>[
            <String, String>{'fen': initial, 'comment': 'starting position'},
            <String, String>{'fen': e4, 'comment': 'good move'},
          ],
        ),
      );
      expect(chess.pgn(), '1. e4 e6');
    });

    test('prune comments', () {
      final Chess chess = Chess.create();
      chess.move(san: 'e4');
      chess.setComment('tactical');
      chess.undo();
      chess.move(san: 'd4');
      chess.setComment('positional');
      expect(
        chess.getComments().map(parseFenCommentToMap).toList(),
        equals(
          <Map<String, dynamic>>[
            <String, dynamic>{'fen': chess.fen(), 'comment': 'positional'},
          ],
        ),
      );
      expect(chess.pgn(), '1. d4 {positional}');
    });

    test('clear comments', () {
      void test(void Function(Chess chess) fn) {
        final Chess chess = Chess.create();
        chess.move(san: 'e4');
        chess.setComment('good move');
        expect(
          chess.getComments().map(parseFenCommentToMap).toList(),
          equals(<Map<String, dynamic>>[
            <String, dynamic>{'fen': chess.fen(), 'comment': 'good move'},
          ]),
        );
        fn(chess);
        expect(chess.getComments(), equals(<FenComment>[]));
      }

      test((Chess chess) {
        chess.reset();
      });
      test((Chess chess) {
        chess.clear();
      });
      test((Chess chess) {
        chess.load(chess.fen());
      });
      test((Chess chess) {
        chess.loadPgn('1. e4');
      });
    });
  });

  group('History', () {
    test('default', () {
      final Chess chess = Chess.create();
      const String fen =
          '4q2k/2r1r3/4PR1p/p1p5/P1Bp1Q1P/1P6/6P1/6K1 b - - 4 41';
      const List<String> moves = <String>[
        'c4',
        'e6',
        'Nf3',
        'd5',
        'd4',
        'Nf6',
        'Nc3',
        'Be7',
        'Bg5',
        'O-O',
        'e3',
        'h6',
        'Bh4',
        'b6',
        'cxd5',
        'Nxd5',
        'Bxe7',
        'Qxe7',
        'Nxd5',
        'exd5',
        'Rc1',
        'Be6',
        'Qa4',
        'c5',
        'Qa3',
        'Rc8',
        'Bb5',
        'a6',
        'dxc5',
        'bxc5',
        'O-O',
        'Ra7',
        'Be2',
        'Nd7',
        'Nd4',
        'Qf8',
        'Nxe6',
        'fxe6',
        'e4',
        'd4',
        'f4',
        'Qe7',
        'e5',
        'Rb8',
        'Bc4',
        'Kh8',
        'Qh3',
        'Nf8',
        'b3',
        'a5',
        'f5',
        'exf5',
        'Rxf5',
        'Nh7',
        'Rcf1',
        'Qd8',
        'Qg3',
        'Re7',
        'h4',
        'Rbb7',
        'e6',
        'Rbc7',
        'Qe5',
        'Qe8',
        'a4',
        'Qd8',
        'R1f2',
        'Qe8',
        'R2f3',
        'Qd8',
        'Bd3',
        'Qe8',
        'Qe4',
        'Nf6',
        'Rxf6',
        'gxf6',
        'Rxf6',
        'Kg8',
        'Bc4',
        'Kh8',
        'Qf4',
      ];

      for (final String move in moves) {
        chess.move(san: move);
      }

      final List<Move> history = chess.history();

      expect(fen, chess.fen());
      expect(history.length, moves.length);
      expect(moves, equals(history.map((Move e) => e.san).toList()));
    });

    test('verbose', () {
      final Chess chess = Chess.create();
      const String fen =
          '4q2k/2r1r3/4PR1p/p1p5/P1Bp1Q1P/1P6/6P1/6K1 b - - 4 41';
      const List<Map<String, String>> moves = <Map<String, String>>[
        <String, String>{
          'color': 'w',
          'from': 'c2',
          'to': 'c4',
          'flags': 'b',
          'piece': 'p',
          'san': 'c4'
        },
        <String, String>{
          'color': 'b',
          'from': 'e7',
          'to': 'e6',
          'flags': 'n',
          'piece': 'p',
          'san': 'e6'
        },
        <String, String>{
          'color': 'w',
          'from': 'g1',
          'to': 'f3',
          'flags': 'n',
          'piece': 'n',
          'san': 'Nf3'
        },
        <String, String>{
          'color': 'b',
          'from': 'd7',
          'to': 'd5',
          'flags': 'b',
          'piece': 'p',
          'san': 'd5'
        },
        <String, String>{
          'color': 'w',
          'from': 'd2',
          'to': 'd4',
          'flags': 'b',
          'piece': 'p',
          'san': 'd4'
        },
        <String, String>{
          'color': 'b',
          'from': 'g8',
          'to': 'f6',
          'flags': 'n',
          'piece': 'n',
          'san': 'Nf6'
        },
        <String, String>{
          'color': 'w',
          'from': 'b1',
          'to': 'c3',
          'flags': 'n',
          'piece': 'n',
          'san': 'Nc3'
        },
        <String, String>{
          'color': 'b',
          'from': 'f8',
          'to': 'e7',
          'flags': 'n',
          'piece': 'b',
          'san': 'Be7'
        },
        <String, String>{
          'color': 'w',
          'from': 'c1',
          'to': 'g5',
          'flags': 'n',
          'piece': 'b',
          'san': 'Bg5'
        },
        <String, String>{
          'color': 'b',
          'from': 'e8',
          'to': 'g8',
          'flags': 'k',
          'piece': 'k',
          'san': 'O-O'
        },
        <String, String>{
          'color': 'w',
          'from': 'e2',
          'to': 'e3',
          'flags': 'n',
          'piece': 'p',
          'san': 'e3'
        },
        <String, String>{
          'color': 'b',
          'from': 'h7',
          'to': 'h6',
          'flags': 'n',
          'piece': 'p',
          'san': 'h6'
        },
        <String, String>{
          'color': 'w',
          'from': 'g5',
          'to': 'h4',
          'flags': 'n',
          'piece': 'b',
          'san': 'Bh4'
        },
        <String, String>{
          'color': 'b',
          'from': 'b7',
          'to': 'b6',
          'flags': 'n',
          'piece': 'p',
          'san': 'b6'
        },
        <String, String>{
          'color': 'w',
          'from': 'c4',
          'to': 'd5',
          'flags': 'c',
          'piece': 'p',
          'captured': 'p',
          'san': 'cxd5',
        },
        <String, String>{
          'color': 'b',
          'from': 'f6',
          'to': 'd5',
          'flags': 'c',
          'piece': 'n',
          'captured': 'p',
          'san': 'Nxd5',
        },
        <String, String>{
          'color': 'w',
          'from': 'h4',
          'to': 'e7',
          'flags': 'c',
          'piece': 'b',
          'captured': 'b',
          'san': 'Bxe7',
        },
        <String, String>{
          'color': 'b',
          'from': 'd8',
          'to': 'e7',
          'flags': 'c',
          'piece': 'q',
          'captured': 'b',
          'san': 'Qxe7',
        },
        <String, String>{
          'color': 'w',
          'from': 'c3',
          'to': 'd5',
          'flags': 'c',
          'piece': 'n',
          'captured': 'n',
          'san': 'Nxd5',
        },
        <String, String>{
          'color': 'b',
          'from': 'e6',
          'to': 'd5',
          'flags': 'c',
          'piece': 'p',
          'captured': 'n',
          'san': 'exd5',
        },
        <String, String>{
          'color': 'w',
          'from': 'a1',
          'to': 'c1',
          'flags': 'n',
          'piece': 'r',
          'san': 'Rc1'
        },
        <String, String>{
          'color': 'b',
          'from': 'c8',
          'to': 'e6',
          'flags': 'n',
          'piece': 'b',
          'san': 'Be6'
        },
        <String, String>{
          'color': 'w',
          'from': 'd1',
          'to': 'a4',
          'flags': 'n',
          'piece': 'q',
          'san': 'Qa4'
        },
        <String, String>{
          'color': 'b',
          'from': 'c7',
          'to': 'c5',
          'flags': 'b',
          'piece': 'p',
          'san': 'c5'
        },
        <String, String>{
          'color': 'w',
          'from': 'a4',
          'to': 'a3',
          'flags': 'n',
          'piece': 'q',
          'san': 'Qa3'
        },
        <String, String>{
          'color': 'b',
          'from': 'f8',
          'to': 'c8',
          'flags': 'n',
          'piece': 'r',
          'san': 'Rc8'
        },
        <String, String>{
          'color': 'w',
          'from': 'f1',
          'to': 'b5',
          'flags': 'n',
          'piece': 'b',
          'san': 'Bb5'
        },
        <String, String>{
          'color': 'b',
          'from': 'a7',
          'to': 'a6',
          'flags': 'n',
          'piece': 'p',
          'san': 'a6'
        },
        <String, String>{
          'color': 'w',
          'from': 'd4',
          'to': 'c5',
          'flags': 'c',
          'piece': 'p',
          'captured': 'p',
          'san': 'dxc5',
        },
        <String, String>{
          'color': 'b',
          'from': 'b6',
          'to': 'c5',
          'flags': 'c',
          'piece': 'p',
          'captured': 'p',
          'san': 'bxc5',
        },
        <String, String>{
          'color': 'w',
          'from': 'e1',
          'to': 'g1',
          'flags': 'k',
          'piece': 'k',
          'san': 'O-O'
        },
        <String, String>{
          'color': 'b',
          'from': 'a8',
          'to': 'a7',
          'flags': 'n',
          'piece': 'r',
          'san': 'Ra7'
        },
        <String, String>{
          'color': 'w',
          'from': 'b5',
          'to': 'e2',
          'flags': 'n',
          'piece': 'b',
          'san': 'Be2'
        },
        <String, String>{
          'color': 'b',
          'from': 'b8',
          'to': 'd7',
          'flags': 'n',
          'piece': 'n',
          'san': 'Nd7'
        },
        <String, String>{
          'color': 'w',
          'from': 'f3',
          'to': 'd4',
          'flags': 'n',
          'piece': 'n',
          'san': 'Nd4'
        },
        <String, String>{
          'color': 'b',
          'from': 'e7',
          'to': 'f8',
          'flags': 'n',
          'piece': 'q',
          'san': 'Qf8'
        },
        <String, String>{
          'color': 'w',
          'from': 'd4',
          'to': 'e6',
          'flags': 'c',
          'piece': 'n',
          'captured': 'b',
          'san': 'Nxe6',
        },
        <String, String>{
          'color': 'b',
          'from': 'f7',
          'to': 'e6',
          'flags': 'c',
          'piece': 'p',
          'captured': 'n',
          'san': 'fxe6',
        },
        <String, String>{
          'color': 'w',
          'from': 'e3',
          'to': 'e4',
          'flags': 'n',
          'piece': 'p',
          'san': 'e4'
        },
        <String, String>{
          'color': 'b',
          'from': 'd5',
          'to': 'd4',
          'flags': 'n',
          'piece': 'p',
          'san': 'd4'
        },
        <String, String>{
          'color': 'w',
          'from': 'f2',
          'to': 'f4',
          'flags': 'b',
          'piece': 'p',
          'san': 'f4'
        },
        <String, String>{
          'color': 'b',
          'from': 'f8',
          'to': 'e7',
          'flags': 'n',
          'piece': 'q',
          'san': 'Qe7'
        },
        <String, String>{
          'color': 'w',
          'from': 'e4',
          'to': 'e5',
          'flags': 'n',
          'piece': 'p',
          'san': 'e5'
        },
        <String, String>{
          'color': 'b',
          'from': 'c8',
          'to': 'b8',
          'flags': 'n',
          'piece': 'r',
          'san': 'Rb8'
        },
        <String, String>{
          'color': 'w',
          'from': 'e2',
          'to': 'c4',
          'flags': 'n',
          'piece': 'b',
          'san': 'Bc4'
        },
        <String, String>{
          'color': 'b',
          'from': 'g8',
          'to': 'h8',
          'flags': 'n',
          'piece': 'k',
          'san': 'Kh8'
        },
        <String, String>{
          'color': 'w',
          'from': 'a3',
          'to': 'h3',
          'flags': 'n',
          'piece': 'q',
          'san': 'Qh3'
        },
        <String, String>{
          'color': 'b',
          'from': 'd7',
          'to': 'f8',
          'flags': 'n',
          'piece': 'n',
          'san': 'Nf8'
        },
        <String, String>{
          'color': 'w',
          'from': 'b2',
          'to': 'b3',
          'flags': 'n',
          'piece': 'p',
          'san': 'b3'
        },
        <String, String>{
          'color': 'b',
          'from': 'a6',
          'to': 'a5',
          'flags': 'n',
          'piece': 'p',
          'san': 'a5'
        },
        <String, String>{
          'color': 'w',
          'from': 'f4',
          'to': 'f5',
          'flags': 'n',
          'piece': 'p',
          'san': 'f5'
        },
        <String, String>{
          'color': 'b',
          'from': 'e6',
          'to': 'f5',
          'flags': 'c',
          'piece': 'p',
          'captured': 'p',
          'san': 'exf5',
        },
        <String, String>{
          'color': 'w',
          'from': 'f1',
          'to': 'f5',
          'flags': 'c',
          'piece': 'r',
          'captured': 'p',
          'san': 'Rxf5',
        },
        <String, String>{
          'color': 'b',
          'from': 'f8',
          'to': 'h7',
          'flags': 'n',
          'piece': 'n',
          'san': 'Nh7'
        },
        <String, String>{
          'color': 'w',
          'from': 'c1',
          'to': 'f1',
          'flags': 'n',
          'piece': 'r',
          'san': 'Rcf1'
        },
        <String, String>{
          'color': 'b',
          'from': 'e7',
          'to': 'd8',
          'flags': 'n',
          'piece': 'q',
          'san': 'Qd8'
        },
        <String, String>{
          'color': 'w',
          'from': 'h3',
          'to': 'g3',
          'flags': 'n',
          'piece': 'q',
          'san': 'Qg3'
        },
        <String, String>{
          'color': 'b',
          'from': 'a7',
          'to': 'e7',
          'flags': 'n',
          'piece': 'r',
          'san': 'Re7'
        },
        <String, String>{
          'color': 'w',
          'from': 'h2',
          'to': 'h4',
          'flags': 'b',
          'piece': 'p',
          'san': 'h4'
        },
        <String, String>{
          'color': 'b',
          'from': 'b8',
          'to': 'b7',
          'flags': 'n',
          'piece': 'r',
          'san': 'Rbb7'
        },
        <String, String>{
          'color': 'w',
          'from': 'e5',
          'to': 'e6',
          'flags': 'n',
          'piece': 'p',
          'san': 'e6'
        },
        <String, String>{
          'color': 'b',
          'from': 'b7',
          'to': 'c7',
          'flags': 'n',
          'piece': 'r',
          'san': 'Rbc7'
        },
        <String, String>{
          'color': 'w',
          'from': 'g3',
          'to': 'e5',
          'flags': 'n',
          'piece': 'q',
          'san': 'Qe5'
        },
        <String, String>{
          'color': 'b',
          'from': 'd8',
          'to': 'e8',
          'flags': 'n',
          'piece': 'q',
          'san': 'Qe8'
        },
        <String, String>{
          'color': 'w',
          'from': 'a2',
          'to': 'a4',
          'flags': 'b',
          'piece': 'p',
          'san': 'a4'
        },
        <String, String>{
          'color': 'b',
          'from': 'e8',
          'to': 'd8',
          'flags': 'n',
          'piece': 'q',
          'san': 'Qd8'
        },
        <String, String>{
          'color': 'w',
          'from': 'f1',
          'to': 'f2',
          'flags': 'n',
          'piece': 'r',
          'san': 'R1f2'
        },
        <String, String>{
          'color': 'b',
          'from': 'd8',
          'to': 'e8',
          'flags': 'n',
          'piece': 'q',
          'san': 'Qe8'
        },
        <String, String>{
          'color': 'w',
          'from': 'f2',
          'to': 'f3',
          'flags': 'n',
          'piece': 'r',
          'san': 'R2f3'
        },
        <String, String>{
          'color': 'b',
          'from': 'e8',
          'to': 'd8',
          'flags': 'n',
          'piece': 'q',
          'san': 'Qd8'
        },
        <String, String>{
          'color': 'w',
          'from': 'c4',
          'to': 'd3',
          'flags': 'n',
          'piece': 'b',
          'san': 'Bd3'
        },
        <String, String>{
          'color': 'b',
          'from': 'd8',
          'to': 'e8',
          'flags': 'n',
          'piece': 'q',
          'san': 'Qe8'
        },
        <String, String>{
          'color': 'w',
          'from': 'e5',
          'to': 'e4',
          'flags': 'n',
          'piece': 'q',
          'san': 'Qe4'
        },
        <String, String>{
          'color': 'b',
          'from': 'h7',
          'to': 'f6',
          'flags': 'n',
          'piece': 'n',
          'san': 'Nf6'
        },
        <String, String>{
          'color': 'w',
          'from': 'f5',
          'to': 'f6',
          'flags': 'c',
          'piece': 'r',
          'captured': 'n',
          'san': 'Rxf6',
        },
        <String, String>{
          'color': 'b',
          'from': 'g7',
          'to': 'f6',
          'flags': 'c',
          'piece': 'p',
          'captured': 'r',
          'san': 'gxf6',
        },
        <String, String>{
          'color': 'w',
          'from': 'f3',
          'to': 'f6',
          'flags': 'c',
          'piece': 'r',
          'captured': 'p',
          'san': 'Rxf6',
        },
        <String, String>{
          'color': 'b',
          'from': 'h8',
          'to': 'g8',
          'flags': 'n',
          'piece': 'k',
          'san': 'Kg8'
        },
        <String, String>{
          'color': 'w',
          'from': 'd3',
          'to': 'c4',
          'flags': 'n',
          'piece': 'b',
          'san': 'Bc4'
        },
        <String, String>{
          'color': 'b',
          'from': 'g8',
          'to': 'h8',
          'flags': 'n',
          'piece': 'k',
          'san': 'Kh8'
        },
        <String, String>{
          'color': 'w',
          'from': 'e4',
          'to': 'f4',
          'flags': 'n',
          'piece': 'q',
          'san': 'Qf4'
        },
      ];

      for (final Map<String, String> rawMove in moves) {
        final Move move = _parseMoveFromMap(rawMove);
        chess.move(
          from: move.from,
          to: move.to,
          promotion: move.promotion,
          san: move.san,
        );
      }

      final List<Move> history = chess.history();

      expect(fen, chess.fen());
      expect(history.length, moves.length);
      expect(_parseMoveFromMapList(moves), equals(history));
    });
  });
}