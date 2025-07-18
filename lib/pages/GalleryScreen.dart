import 'package:flutter/material.dart';
import 'package:glacier/components/PreviewVideoPage.dart';
import 'package:glacier/components/VideoGallery/AlbumGridView.dart';
import 'package:glacier/components/VideoGallery/VideoGridView.dart';
import 'package:glacier/pages/send-reaction/SendReactionPage.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<AssetEntity> _videos = [];
  final List<AssetPathEntity> _albums = [];
  bool _showAlbums = true;
  String? _currentAlbumName;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          Navigator.of(
            context,
          ).pushReplacementNamed('/', arguments: {'index': 0});
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(
            _currentAlbumName == null ? kToolbarHeight : kToolbarHeight * 2,
          ),
          child: Column(
            children: [
              AppBar(
                title: Text('Gallery'),

                leading: CloseButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushReplacementNamed('/', arguments: {'index': 0});
                  },
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _showAlbums ? Icons.video_collection : Icons.folder,
                    ),
                    onPressed: () async {
                      if (!_showAlbums && _albums.isEmpty) {
                        await _loadAlbums();
                      }
                      if (_showAlbums) {
                        // switching to show all videos
                        List<AssetEntity> allVideos = [];
                        for (var album in _albums) {
                          final albumVideos = await album.getAssetListPaged(
                            page: 0,
                            size: 100,
                          );
                          allVideos.addAll(albumVideos);
                        }
                        setState(() {
                          _videos = allVideos;
                          _showAlbums = false;
                        });
                      } else {
                        setState(() {
                          _showAlbums = true;
                        });
                      }
                    },
                  ),
                ],
              ),
              if (_currentAlbumName != null)
                Container(
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () {
                          setState(() {
                            _showAlbums = true;
                            _currentAlbumName = null;
                          });
                        },
                      ),

                      Expanded(
                        child: Text(
                          _currentAlbumName ?? 'Videos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        body:
            _showAlbums
                ? AlbumGridView(
                  albums: _albums,
                  openAlbum: (album) => openAlbum(album),
                )
                : _videos.isEmpty || _albums.isEmpty
                ? Center(child: CircularProgressIndicator())
                : VideoGridView(
                  videos: _videos,
                  previewVideo: (video) async {
                    final selectedVideo =
                        await Navigator.push<Map<String, dynamic>?>(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PreviewVideoPage(
                                  localVideo: video,
                                  hasConfirmButton: true,
                                ),
                          ),
                        );

                    if (selectedVideo != null) {
                      // var path = await selectedVideo.file;
                      // Navigator.of(context).pop(selectedVideo);
                      await Navigator.push<AssetEntity?>(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => SendReactionPage(
                                video: selectedVideo['video'],
                                duration: selectedVideo['duration'],
                              ),
                        ),
                      );
                    }
                  },
                ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  void openAlbum(AssetPathEntity album) {
    setState(() {
      _currentAlbumName = album.name;
      _showAlbums = false;
    });

    album.getAssetListPaged(page: 0, size: 100).then((videos) {
      setState(() {
        _videos = videos;
      });
    });
  }

  Future<void> _loadAlbums() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      PhotoManager.openSetting();
      return;
    }

    // Get all albums/folders with videos
    List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.video,
    );
    for (final album in albums) {
      final count = await album.assetCountAsync;
      if (count > 0) {
        setState(() {
          _albums.add(album);
        });
      }
    }

    if (!_showAlbums) {
      List<AssetEntity> allVideos = [];
      for (var album in albums) {
        final albumVideos = await album.getAssetListPaged(page: 0, size: 100);
        allVideos.addAll(albumVideos);
      }
      setState(() {
        _videos = allVideos;
      });
    }
  }
}
