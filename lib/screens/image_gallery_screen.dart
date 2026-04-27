import 'package:flutter/material.dart';

class ImageGalleryScreen extends StatelessWidget {
  final List<String> imageUrls;
  final String title;

  const ImageGalleryScreen({
    super.key,
    required this.imageUrls,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('이미지 (${imageUrls.length}장)'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: GridView.builder(
        padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottomSafe),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _ImageViewerScreen(
                    imageUrls: imageUrls,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: Image.network(
              imageUrls[index],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey.shade100,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade100,
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.grey.shade400,
                    size: 32,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ImageViewerScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _ImageViewerScreen({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isZoomed = false;
  final _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(fontSize: 16),
        ),
        elevation: 0,
      ),
      body: PageView.builder(
        controller: _pageController,
        physics: _isZoomed
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            transformationController: index == _currentIndex
                ? _transformationController
                : null,
            minScale: 1.0,
            maxScale: 5.0,
            onInteractionUpdate: (details) {
              if (index != _currentIndex) return;
              final scale = _transformationController.value.getMaxScaleOnAxis();
              final zoomed = scale > 1.01;
              if (zoomed != _isZoomed) {
                setState(() => _isZoomed = zoomed);
              }
            },
            onInteractionEnd: (details) {
              if (index != _currentIndex) return;
              final scale = _transformationController.value.getMaxScaleOnAxis();
              final zoomed = scale > 1.01;
              if (zoomed != _isZoomed) {
                setState(() => _isZoomed = zoomed);
              }
            },
            child: Center(
              child: Image.network(
                widget.imageUrls[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 48,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
