import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../../core/constants/app_colors.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
    required this.onPictureTaken,
    this.cropAspectRatio = 1.0, // 1.0 = carré, 16/9 = paysage, etc.
  });

  final Function(File imageFile) onPictureTaken;
  final double cropAspectRatio;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      // Récupérer les caméras disponibles
      _cameras = await availableCameras();
      
      if (_cameras!.isEmpty) {
        throw Exception('Aucune caméra trouvée');
      }

      // Utiliser la caméra arrière par défaut, ou la première disponible
      final camera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium, // Bon compromis qualité/performance
        enableAudio: false,
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('❌ Erreur caméra: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur caméra: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) {
      return;
    }

    setState(() {
      _isTakingPicture = true;
    });

    try {
      // Prendre la photo
      final XFile picture = await _controller!.takePicture();
      
      // Sauvegarder dans un fichier temporaire
      final tempDir = await getTemporaryDirectory();
      final filePath = path.join(
        tempDir.path,
        'profile_pic_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final savedFile = await File(picture.path).copy(filePath);

      // Fermer la caméra avant d'ouvrir le crop
      await _controller?.dispose();
      
      if (mounted) {
        // ✅ Ouvrir l'éditeur de crop
        await _openCropper(savedFile);
      }
    } catch (e) {
      print('❌ Erreur prise de photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  Future<void> _openCropper(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: CropAspectRatio(
          ratioX: widget.cropAspectRatio,
          ratioY: 1.0,
        ),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Rogner la photo',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true, // Verrouiller le ratio pour un avatar
          ),
          IOSUiSettings(
            title: 'Rogner la photo',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        // ✅ Retourner le fichier rogné
        widget.onPictureTaken(File(croppedFile.path));
        
        if (mounted) {
          Navigator.pop(context); // Fermer la caméra
        }
      } else {
        // L'utilisateur a annulé le crop
        // On retourne à l'écran caméra
        await _initCamera(); // Réinitialiser la caméra
        setState(() {});
      }
    } catch (e) {
      print('❌ Erreur crop: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du rognage: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      // Retour à l'écran caméra
      await _initCamera();
      setState(() {});
    }
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;

    final currentLens = _controller?.description.lensDirection;
    final newCamera = _cameras!.firstWhere(
      (c) => c.lensDirection != currentLens,
      orElse: () => _cameras!.first,
    );

    _controller = CameraController(
      newCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    
    _controller!.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prendre une photo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: _switchCamera,
            tooltip: 'Changer de caméra',
          ),
        ],
      ),
      body: Stack(
        children: [
          // ✅ Aperçu de la caméra
          if (_isInitialized && _controller != null)
            Positioned.fill(
              child: CameraPreview(_controller!),
            )
          else
            const Center(
              child: CircularProgressIndicator(),
            ),
          
          // ✅ Overlay avec le cadre de crop
          if (_isInitialized)
            Positioned.fill(
              child: CustomPaint(
                painter: CropOverlayPainter(
                  aspectRatio: widget.cropAspectRatio,
                ),
              ),
            ),
          
          // ✅ Bouton de capture en bas
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 4,
                    ),
                  ),
                  child: _isTakingPicture
                      ? const Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: AppColors.primary,
                          size: 40,
                        ),
                ),
              ),
            ),
          ),
          
          // ✅ Bouton annuler
          Positioned(
            top: 60,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          // ✅ Info du cadre
          Positioned(
            bottom: 140,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Cadrez votre visage dans le cercle',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Custom Painter pour afficher le cadre de crop
class CropOverlayPainter extends CustomPainter {
  final double aspectRatio;

  CropOverlayPainter({required this.aspectRatio});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Calculer la taille du cercle/rectangle en fonction de l'écran
    final cropSize = size.width * 0.7;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 40),
      width: cropSize,
      height: cropSize / aspectRatio,
    );
    
    // Dessiner le rectangle/cercle
    if (aspectRatio == 1.0) {
      // Cercle pour avatar carré
      canvas.drawCircle(
        rect.center,
        cropSize / 2,
        paint,
      );
      // Grille
      _drawGrid(canvas, rect, paint);
    } else {
      // Rectangle pour paysage
      canvas.drawRect(rect, paint);
      _drawGrid(canvas, rect, paint);
    }
  }

  void _drawGrid(Canvas canvas, Rect rect, Paint paint) {
    paint.color = Colors.white.withOpacity(0.2);
    paint.strokeWidth = 1;
    paint.style = PaintingStyle.stroke;
    
    // Lignes de la règle des tiers
    final xStep = rect.width / 3;
    final yStep = rect.height / 3;
    
    for (int i = 1; i < 3; i++) {
      // Verticales
      canvas.drawLine(
        Offset(rect.left + xStep * i, rect.top),
        Offset(rect.left + xStep * i, rect.bottom),
        paint,
      );
      // Horizontales
      canvas.drawLine(
        Offset(rect.left, rect.top + yStep * i),
        Offset(rect.right, rect.top + yStep * i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}