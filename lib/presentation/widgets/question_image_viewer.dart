import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class QuestionImageViewer extends StatefulWidget {
  final String imagePath;
  final double? maxHeight;
  final bool enableFullScreen;

  const QuestionImageViewer({
    super.key,
    required this.imagePath,
    this.maxHeight,
    this.enableFullScreen = true,
  });

  @override
  State<QuestionImageViewer> createState() => _QuestionImageViewerState();
}

class _QuestionImageViewerState extends State<QuestionImageViewer> {
  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text('Question Preview', style: TextStyle(color: Colors.white)),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.asset(
                widget.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _buildErrorWidget(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 40),
          SizedBox(height: 8),
          Text(
            'Official question screenshot unavailable',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enableFullScreen ? () => _openFullScreen(context) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: widget.maxHeight ?? 420,
          ),
          color: Colors.white,
          width: double.infinity,
          child: Stack(
            children: [
              InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1.0,
                maxScale: 3.5,
                child: Center(
                  child: Image.asset(
                    widget.imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _buildErrorWidget(),
                  ),
                ),
              ),
              if (widget.enableFullScreen)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

