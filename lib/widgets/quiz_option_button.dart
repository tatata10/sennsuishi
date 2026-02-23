import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class QuizOptionButton extends StatelessWidget {
  final int index;
  final String text;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isCorrect;
  final bool isAnswered;

  const QuizOptionButton({
    super.key,
    required this.index,
    required this.text,
    required this.onTap,
    required this.isSelected,
    required this.isCorrect,
    required this.isAnswered,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.grey.shade300;
    Color backgroundColor = Colors.white;
    Color textColor = AppTheme.textDark;

    if (isAnswered) {
      if (isSelected) {
        borderColor = isCorrect ? AppTheme.mintGreen : AppTheme.errorRed;
        backgroundColor = isCorrect ? AppTheme.mintGreen.withOpacity(0.1) : AppTheme.errorRed.withOpacity(0.1);
        textColor = isCorrect ? AppTheme.navy : AppTheme.errorRed;
      } else if (isCorrect) {
        // Highlight the correct answer if the user picked the wrong one
        borderColor = AppTheme.mintGreen;
        backgroundColor = AppTheme.mintGreen.withOpacity(0.1);
        textColor = AppTheme.navy;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 2),
        ),
        child: InkWell(
          onTap: isAnswered ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isSelected ? borderColor : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
