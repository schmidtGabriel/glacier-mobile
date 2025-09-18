import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class AlbumGridView extends StatefulWidget {
  final List<AssetPathEntity> albums;
  final Function(AssetPathEntity) openAlbum;

  const AlbumGridView({
    super.key,
    required this.albums,
    required this.openAlbum,
  });

  @override
  State<AlbumGridView> createState() => _AlbumGridViewState();
}

class _AlbumData {
  final AssetPathEntity album;
  final int assetCount;
  final Uint8List? thumbnailData;
  final AssetEntity? coverAsset;

  _AlbumData({
    required this.album,
    required this.assetCount,
    this.thumbnailData,
    this.coverAsset,
  });
}

class _AlbumGridViewState extends State<AlbumGridView> {
  bool isLoading = true;
  List<_AlbumData> albumDataList = [];
  final Map<String, Uint8List> _thumbnailCache = {};
  final Map<String, int> _assetCountCache = {};

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (isLoading) Center(child: CircularProgressIndicator()),

        Visibility(
          visible: !isLoading,
          child: GridView.builder(
            padding: const EdgeInsets.only(
              right: 16,
              left: 16,
              top: 8,
              bottom: 20,
            ),
            itemCount: albumDataList.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3 / 2,
            ),
            itemBuilder: (context, index) {
              final albumData = albumDataList[index];
              final album = albumData.album;

              return GestureDetector(
                onTap: () async {
                  // Load videos on demand, not all at once
                  widget.openAlbum(album);
                },
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child:
                            albumData.thumbnailData != null
                                ? Image.memory(
                                  albumData.thumbnailData!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                                : Container(color: Colors.grey),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          children: [
                            Text(
                              album.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${albumData.assetCount} videos',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
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
    );
  }

  @override
  void dispose() {
    // Clear thumbnail cache to free memory
    _thumbnailCache.clear();
    _assetCountCache.clear();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadAlbum();
  }

  Future<void> loadAlbum() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Pre-load album data with caching
      final List<_AlbumData> tempAlbumData = [];

      for (final album in widget.albums) {
        // Cache asset count
        int assetCount;
        if (_assetCountCache.containsKey(album.id)) {
          assetCount = _assetCountCache[album.id]!;
        } else {
          assetCount = await album.assetCountAsync;
          _assetCountCache[album.id] = assetCount;
        }

        // Cache thumbnail
        Uint8List? thumbnailData;
        if (_thumbnailCache.containsKey(album.id)) {
          thumbnailData = _thumbnailCache[album.id];
        } else {
          try {
            final assets = await album.getAssetListRange(start: 0, end: 1);
            if (assets.isNotEmpty) {
              final cover = assets.first;
              // Use smaller thumbnail size to reduce memory usage
              thumbnailData = await cover.thumbnailDataWithSize(
                ThumbnailSize(150, 150), // Reduced from 200x200
              );
              if (thumbnailData != null) {
                _thumbnailCache[album.id] = thumbnailData;
              }
            }
          } catch (e) {
            print('Error loading thumbnail for album ${album.name}: $e');
          }
        }

        tempAlbumData.add(
          _AlbumData(
            album: album,
            assetCount: assetCount,
            thumbnailData: thumbnailData,
            coverAsset: null,
          ),
        );
      }

      if (mounted) {
        setState(() {
          albumDataList = tempAlbumData;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading albums: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
