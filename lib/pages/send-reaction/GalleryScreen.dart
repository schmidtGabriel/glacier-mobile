import 'package:flutter/material.dart';
import 'package:glacier/components/VideoGallery/AlbumGridView.dart';
import 'package:glacier/components/VideoGallery/VideoGridView.dart';
import 'package:glacier/pages/PreviewVideoPage.dart';
import 'package:glacier/services/PermissionsService.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen>
    with WidgetsBindingObserver {
  List<AssetEntity> _videos = [];
  final List<AssetPathEntity> _albums = [];
  bool _showAlbums = false;
  String? _currentAlbumName = 'Recents';
  String pageTitle = 'Gallery';
  bool isLoading = true;
  bool isGalleryGranted = false;
  PermissionState? _permissionState;
  final _permissionsService = PermissionsService.instance;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : !isGalleryGranted
              ? Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Gallery permission is required to access videos.',
                        style: TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          final permission =
                              await PhotoManager.requestPermissionExtend();
                          if (permission.isAuth) {
                            setState(() {
                              isGalleryGranted = true;
                              _permissionState = permission;
                            });
                            _loadAlbums();
                          } else {
                            PhotoManager.openSetting();
                          }
                        },
                        child: Text('Grant Permission'),
                      ),
                    ],
                  ),
                ),
              )
              : Scaffold(
                appBar: PreferredSize(
                  preferredSize: Size.fromHeight(
                    _currentAlbumName == null
                        ? kToolbarHeight
                        : kToolbarHeight * 2,
                  ),
                  child: Column(
                    children: [
                      AppBar(
                        title: Text(pageTitle),

                        actions: [
                          if (_currentAlbumName == null && !isLoading) ...[
                            IconButton(
                              icon: Icon(
                                _showAlbums
                                    ? Icons.video_collection
                                    : Icons.folder,
                              ),
                              onPressed: () async {
                                if (!_showAlbums && _albums.isEmpty) {
                                  await _loadAlbums();
                                }
                                if (_showAlbums) {
                                  // switching to show all videos
                                  List<AssetEntity> allVideos = [];
                                  for (var album in _albums) {
                                    final albumVideos = await album
                                        .getAssetListPaged(page: 0, size: 100);
                                    allVideos.addAll(albumVideos);
                                  }
                                  setState(() {
                                    _videos = allVideos;
                                    _showAlbums = false;
                                    pageTitle = 'All Videos';
                                  });
                                } else {
                                  setState(() {
                                    _showAlbums = true;
                                    pageTitle = 'Gallery';
                                  });
                                }
                              },
                            ),
                          ],

                          if (_permissionState == PermissionState.limited)
                            IconButton(
                              icon: Icon(Icons.settings_suggest),
                              onPressed: () {
                                _showLimitedAccessDialog();
                              },
                            ),
                        ],
                      ),
                      if (_currentAlbumName != null)
                        Container(
                          padding: EdgeInsets.only(top: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,

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
                    _permissionState == PermissionState.limited &&
                            _videos.isEmpty
                        ? Center(
                          child: Column(
                            children: [
                              Text(
                                'You have limited access to your photo library. Please select more photos or videos.',
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  PhotoManager.presentLimited().then((_) {
                                    // Refresh the album list after user manages selection
                                    _refreshAlbums();
                                  });
                                },
                                child: Text('Manage Selection'),
                              ),
                            ],
                          ),
                        )
                        : _showAlbums
                        ? AlbumGridView(
                          albums: _albums,
                          openAlbum: (album) => openAlbum(album),
                        )
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
                              Navigator.of(context).pop(selectedVideo);
                              // await Navigator.push<AssetEntity?>(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder:
                              //         (context) => SendReactionPage(
                              //           video: selectedVideo['video'],
                              //           duration: selectedVideo['duration'],
                              //         ),
                              //   ),
                              // );
                            }
                          },
                        ),
              ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh permissions when app comes back from settings
    if (state == AppLifecycleState.resumed) {
      _checkAndRefreshPermissions();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  Future<void> _checkAndRefreshPermissions() async {
    final currentPermission = await PhotoManager.requestPermissionExtend();
    if (currentPermission != _permissionState) {
      setState(() {
        _permissionState = currentPermission;
        isGalleryGranted =
            currentPermission == PermissionState.authorized ||
            currentPermission == PermissionState.limited;
      });

      if (isGalleryGranted) {
        _refreshAlbums();
      }
    }
  }

  Future<void> _loadAlbums() async {
    setState(() {
      isLoading = true;
    });

    final permissionState = await PhotoManager.requestPermissionExtend();
    _permissionState = permissionState;
    isGalleryGranted =
        permissionState == PermissionState.authorized ||
        permissionState == PermissionState.limited;

    if (isGalleryGranted) {
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
      if (_showAlbums) {
        List<AssetEntity> allVideos = [];
        for (var album in albums) {
          final albumVideos = await album.getAssetListPaged(page: 0, size: 100);
          allVideos.addAll(albumVideos);
        }
        print('Found ${allVideos.length} videos in all albums');
        setState(() {
          _videos = allVideos;
        });
      } else {
        final ab = albums.firstWhere((album) => album.name == 'Recents');
        openAlbum(ab);
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _refreshAlbums() async {
    // Clear existing data
    _albums.clear();
    _videos.clear();

    // Reload albums with updated permissions
    await _loadAlbums();
  }

  void _showLimitedAccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Limited Photo Access'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You have granted limited access to your photo library. This means only selected photos and videos are available.',
              ),
              SizedBox(height: 16),
              Text('You can:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('• Add more photos/videos to selection'),
              Text('• Grant full access in Settings'),
              Text('• Continue with current selection'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Continue'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                PhotoManager.presentLimited().then((_) {
                  // Refresh the album list after user manages selection
                  _refreshAlbums();
                });
              },
              child: Text('Manage Selection'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                PhotoManager.openSetting();
              },
              child: Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }
}
