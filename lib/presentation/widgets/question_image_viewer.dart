import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class QuestionImageViewer extends StatefulWidget {
  final String imagePath;
  final double? maxHeight;
  final bool enableFullScreen;
  final bool enableInlineZoom;

  const QuestionImageViewer({
    super.key,
    required this.imagePath,
    this.maxHeight,
    this.enableFullScreen = true,
    this.enableInlineZoom = false,
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
    Widget imageContent = Center(
      child: Image.asset(
        widget.imagePath,
        fit: BoxFit.contain,
        cacheWidth: 1080,
        errorBuilder: (_, __, ___) => _buildErrorWidget(),
      ),
    );

    if (widget.enableInlineZoom) {
      imageContent = InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 3.5,
        child: imageContent,
      );
    }

    return GestureDetector(
      onTap: widget.enableFullScreen ? () => _openFullScreen(context) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: widget.maxHeight ?? 380,
          ),
          color: Colors.white,
          width: double.infinity,
          child: Stack(
            children: [
              imageContent,
              if (widget.enableFullScreen)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_in, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Expand',
                          style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

