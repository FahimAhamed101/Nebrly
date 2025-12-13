import 'package:flutter/material.dart';
import '../widgets/colors.dart';

class KoreUploadCard extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final VoidCallback? onTap;
  final String? filePath; // Add file path to track selection
  final String? fileName; // Optional custom file name

  const KoreUploadCard({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.onTap,
    this.filePath,
    this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = filePath != null && filePath!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? KoreColors.primary : const Color(0xFFE5E5E5),
            width: hasFile ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasFile
                    ? KoreColors.primary.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: hasFile ? KoreColors.primary : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: hasFile ? KoreColors.primary : const Color(0xFF1C1C1C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasFile ? (fileName ?? 'File selected') : hint,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasFile ? KoreColors.primary : const Color(0xFF888888),
                      fontWeight: hasFile ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                  if (hasFile && filePath != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _getFileNameFromPath(filePath!),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: hasFile ? KoreColors.primary : const Color(0xFF888888),
            ),
          ],
        ),
      ),
    );
  }

  String _getFileNameFromPath(String path) {
    try {
      return path.split('/').last;
    } catch (e) {
      return 'Selected file';
    }
  }
}