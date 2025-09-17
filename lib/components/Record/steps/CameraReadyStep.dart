import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:glacier/themes/theme_extensions.dart';

class CameraReadyStep extends StatelessWidget {
  final CameraController? cameraController;
  final String layout;
  final Function(String) onLayoutChanged;
  final VoidCallback onReadyPressed;

  const CameraReadyStep({
    super.key,
    required this.cameraController,
    required this.layout,
    required this.onLayoutChanged,
    required this.onReadyPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Label above camera preview
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    'Check the room light.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color:
                          context.isDarkMode
                              ? Colors.grey[300]
                              : Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Take a look at yourself.',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color:
                          context.isDarkMode
                              ? Colors.grey[300]
                              : Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Get ready!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color:
                          context.isDarkMode
                              ? Colors.grey[300]
                              : Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // Camera preview with proportional dimensions
            Expanded(
              flex: 3, // Reduced from taking all available space
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate proportional width based on available height
                    double maxHeight = constraints.maxHeight;
                    double aspectRatio = 9 / 16; // Height/Width ratio
                    double calculatedWidth = maxHeight * aspectRatio;

                    // Ensure width doesn't exceed screen width with some padding
                    double maxWidth = MediaQuery.of(context).size.width * 0.8;
                    double finalWidth =
                        calculatedWidth > maxWidth ? maxWidth : calculatedWidth;
                    double finalHeight = finalWidth / aspectRatio;

                    return SizedBox(
                      width: finalWidth,
                      height: finalHeight,
                      child:
                          cameraController != null &&
                                  cameraController!.value.isInitialized
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CameraPreview(cameraController!),
                              )
                              : Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text('Initializing camera...'),
                                  ],
                                ),
                              ),
                    );
                  },
                ),
              ),
            ),
            // Bottom section with layout selector and Ready button
            Container(
              child: Column(
                children: [
                  // Layout selector
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: DropdownButton<String>(
                  //     value: layout,
                  //     isExpanded: true,
                  //     items: [
                  //       DropdownMenuItem(
                  //         value: 'preview',
                  //         child: Text('Preview Layout'),
                  //       ),
                  //       DropdownMenuItem(
                  //         value: 'vertical',
                  //         child: Text('Vertical Layout'),
                  //       ),
                  //     ],
                  //     onChanged: (String? newValue) {
                  //       if (newValue != null) {
                  //         onLayoutChanged(newValue);
                  //       }
                  //     },
                  //   ),
                  // ),
                  // Ready button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
                    child: SizedBox(
                      width: double.infinity,

                      child: ElevatedButton(
                        onPressed:
                            cameraController != null &&
                                    cameraController!.value.isInitialized
                                ? onReadyPressed
                                : null,
                        style: ElevatedButton.styleFrom(
                          textStyle: TextStyle(fontSize: 18),
                        ),
                        child: Text('Ready'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
