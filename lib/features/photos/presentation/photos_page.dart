import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/components/category_chips.dart';
import '../../../shared/components/empty_state_view.dart';
import '../../../shared/widgets/tv_focus_wrapper.dart';
import '../services/photo_gallery_service.dart';

class PhotosPage extends StatefulWidget {
  const PhotosPage({super.key});

  @override
  State<PhotosPage> createState() => _PhotosPageState();
}

class _PhotosPageState extends State<PhotosPage> {
  final PhotoGalleryService _service = PhotoGalleryService.instance;
  String _selectedAlbum = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _showPhotoViewer(PhotoItem photo) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Zoomable Interactive Viewer
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.9,
                        colors: [Color(0xFF1E2838), Color(0xFF090D14)],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.image_outlined, size: 90, color: Colors.white24),
                          const SizedBox(height: 12),
                          Text(photo.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('${photo.resolution} • ${photo.formattedSize} • ${photo.format.name.toUpperCase()}', style: const TextStyle(color: Colors.white60)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Close Button
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = _service.filterPhotos(album: _selectedAlbum, query: _searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photos & Slideshow'),
        actions: [
          TvFocusWrapper(
            onTap: () => _service.toggleSlideshow(),
            child: TextButton.icon(
              onPressed: () => _service.toggleSlideshow(),
              icon: Icon(
                _service.isSlideshowPlaying ? Icons.pause_circle_filled_rounded : Icons.slideshow_rounded,
                size: 20,
                color: _service.isSlideshowPlaying ? Colors.amber : Colors.white,
              ),
              label: Text(_service.isSlideshowPlaying ? 'Pause Slideshow' : 'Play Slideshow'),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Slideshow Active Notification Bar
          if (_service.isSlideshowPlaying)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              color: AppColors.primary,
              child: Row(
                children: [
                  const Icon(Icons.slideshow_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Slideshow Active: Showing slide ${_service.slideshowIndex + 1} of ${_service.allPhotos.length}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    '${_service.slideshowIntervalSeconds}s interval',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),

          // Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search photos by title or album...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
              ),
            ),
          ),

          // Album Chips
          CategoryChips(
            categories: _service.albums,
            selectedCategory: _selectedAlbum,
            onCategorySelected: (album) => setState(() => _selectedAlbum = album),
          ),
          const SizedBox(height: 12),

          // Photos Grid
          Expanded(
            child: photos.isEmpty
                ? EmptyStateView(
                    title: 'No Photos Found',
                    message: _searchQuery.isNotEmpty
                        ? 'No photo matched "$_searchQuery".'
                        : 'No photos in album "$_selectedAlbum".',
                    icon: Icons.photo_library_outlined,
                    actionLabel: 'Reset Filter',
                    onActionTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _selectedAlbum = 'All';
                      });
                    },
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 240,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      return TvFocusWrapper(
                        onTap: () => _showPhotoViewer(photo),
                        borderRadius: BorderRadius.circular(8),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(
                                color: const Color(0xFF141923),
                                child: Center(
                                  child: Icon(Icons.image_outlined, size: 48, color: Colors.white.withValues(alpha: 0.15)),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  color: Colors.black87,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        photo.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      Text(
                                        '${photo.format.name.toUpperCase()} • ${photo.formattedSize}',
                                        style: const TextStyle(color: Colors.white60, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
