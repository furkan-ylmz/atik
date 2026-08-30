import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_logger.dart';
import '../../data/repositories/detection_repository.dart';
import '../result/result_screen.dart';

class ScanCameraScreen extends StatefulWidget {
  final DetectionRepository? detectionRepository;

  const ScanCameraScreen({
    super.key,
    this.detectionRepository,
  });

  @override
  State<ScanCameraScreen> createState() => _ScanCameraScreenState();
}

class _ScanCameraScreenState extends State<ScanCameraScreen> with WidgetsBindingObserver {
  late final DetectionRepository _detectionRepository;
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _detectionRepository = widget.detectionRepository ?? DetectionRepository();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camera = _cameraController;
    if (camera == null || !camera.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      camera.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kullanılabilir kamera bulunamadı.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final camera = _cameras[_selectedCameraIndex];
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stack) {
      AppLogger.error('Kamera başlatılamadı', e, stack, 'ScanCameraScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kamera başlatma hatası: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      AppLogger.error('Flaş değiştirilemedi', e, null, 'ScanCameraScreen');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() {
      _isInitialized = false;
    });
    await _cameraController?.dispose();
    await _initializeCamera();
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile photo = await _cameraController!.takePicture();

      // Kalıcı depolamaya kaydet
      final permanentPath = await _detectionRepository.saveImageToLocalStorage(photo.path);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ResultScreen(imagePath: permanentPath),
          ),
        );
      }
    } catch (e, stack) {
      AppLogger.error('Fotoğraf çekilemedi', e, stack, 'ScanCameraScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf çekilemedi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitialized
          ? Stack(
              children: [
                // Kamera Önizlemesi
                SizedBox.expand(
                  child: CameraPreview(_cameraController!),
                ),

                // Üst Bar
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.4),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Atığı kutu içine hizalayın',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                                color: _isFlashOn ? Colors.amber : Colors.white,
                              ),
                              onPressed: _toggleFlash,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withOpacity(0.4),
                              ),
                            ),
                            if (_cameras.length > 1) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
                                onPressed: _switchCamera,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Kamera Vizör Çerçevesi
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.82,
                    height: MediaQuery.of(context).size.width * 0.82,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.85), width: 2.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),

                // Alt Deklanşör Butonu
                Positioned(
                  bottom: 44,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _isProcessing ? null : _takePicture,
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: _isProcessing
                            ? const Padding(
                                padding: EdgeInsets.all(22.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                size: 40,
                                color: AppColors.primary,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
    );
  }
}
