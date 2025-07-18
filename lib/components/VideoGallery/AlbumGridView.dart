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
  final AssetEntity? coverAsset;
  final int assetCount;

  _AlbumData({required this.album, this.coverAsset, required this.assetCount});
}

class _AlbumGridViewState extends State<AlbumGridView> {
  bool isLoading = true;
  List<_AlbumData> albumDataList = [];

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
            itemCount: widget.albums.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3 / 2,
            ),
            itemBuilder: (context, index) {
              final album = widget.albums[index];
              return FutureBuilder<List<AssetEntity>>(
                future: album.getAssetListRange(start: 0, end: 1),
                builder: (context, snapshot) {
                  final assets = snapshot.data;
                  final cover =
                      (assets != null && assets.isNotEmpty)
                          ? assets.first
                          : null;
                  return GestureDetector(
                    onTap: () async {
                      final albumVideos = await album.getAssetListPaged(
                        page: 0,
                        size: 100,
                      );
                      setState(() {
                        widget.openAlbum(album);
                      });
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
                                cover != null
                                    ? FutureBuilder<Uint8List?>(
                                      future: cover.thumbnailDataWithSize(
                                        ThumbnailSize(200, 200),
                                      ),
                                      builder: (context, thumbSnapshot) {
                                        if (thumbSnapshot.connectionState ==
                                                ConnectionState.waiting ||
                                            thumbSnapshot.data == null) {
                                          return Container(color: Colors.grey);
                                        }
                                        return Image.memory(
                                          thumbSnapshot.data!,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        );
                                      },
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
                                FutureBuilder<int>(
                                  future: album.assetCountAsync,
                                  builder: (context, countSnapshot) {
                                    final count = countSnapshot.data ?? 0;
                                    return Text(
                                      '$count videos',
                                      style: TextStyle(fontSize: 12),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadAlbum();
  }

  loadAlbum() {
    setState(() {
      isLoading = true;
    });

    Future.delayed(Duration(milliseconds: 500), () async {
      setState(() {
        isLoading = false;
      });
    });
  }
}
