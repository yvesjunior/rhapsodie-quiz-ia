import 'package:flutter/material.dart';
import 'package:flutterquiz/core/core.dart';

class GameModeCard extends StatelessWidget {
  const GameModeCard({
    required this.title,
    required this.backgroundColor,
    required this.imagePath,
    this.onTap,
    super.key,
  });

  final String title;
  final Color backgroundColor;
  final String imagePath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 8,
              color: backgroundColor.withValues(alpha: 0.4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Title
            Positioned(
              top: 16,
              left: 12,
              right: 12,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeights.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Image at bottom
            Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Image.asset(
                  imagePath,
                  height: 90,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 90,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.games_rounded,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Game mode colors matching the design
class GameModeColors {
  static const soloMode = Color(0xFFF5A0B8); // Pink
  static const multiplayerMode = Color(0xFFA8D8EA); // Light blue
  static const oneVsOneMode = Color(0xFFA8E6CF); // Light green
  static const randomQuiz = Color(0xFFB8A9C9); // Light purple
}

