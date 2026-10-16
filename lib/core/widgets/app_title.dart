import 'package:flutter/material.dart';

class AppTitle extends StatelessWidget {
  const AppTitle({super.key});

  static const _colors = [
    Color(0xFF1685EF),
    Color(0xFFFF791B),
    Color(0xFF2BB879),
    Color(0xFF129DDD),
    Color(0xFF9344DD),
    Color(0xFFFFAB18),
    Color(0xFF40B943),
    Color(0xFF159F94),
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Little Sprout Adventures',
      header: true,
      child: ExcludeSemantics(
        child: Column(
          children: [
            for (final word in ['Little Sprout', 'Adventures'])
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Stack(
                    children: [
                      Text(
                        word,
                        style: TextStyle(
                          fontSize: 60,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 7
                            ..color = Colors.white,
                          shadows: const [
                            Shadow(
                              color: Color(0x40226795),
                              offset: Offset(0, 5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      Text.rich(
                        TextSpan(children: [
                          for (var i = 0; i < word.length; i++)
                            TextSpan(
                              text: word[i],
                              style:
                                  TextStyle(color: _colors[i % _colors.length]),
                            ),
                        ]),
                        style: const TextStyle(
                          fontSize: 60,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
