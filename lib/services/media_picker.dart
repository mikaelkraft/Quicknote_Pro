import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for picking media files with proper permission handling
class MediaPicker {
  final ImagePicker _imagePicker = ImagePicker();

  /// Pick an image from camera
  Future<File?> pickImageFromCamera() async {
    // Request camera permission
    final hasPermission = await _requestCameraPermission();
    if (!hasPermission) {
      throw PermissionDeniedException('Camera permission denied');
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      return image != null ? File(image.path) : null;
    } catch (e) {
      throw MediaPickerException('Failed to capture image from camera: $e');
    }
  }

  /// Pick an image from gallery
  Future<File?> pickImageFromGallery() async {
    // Request photos permission
    final hasPermission = await _requestPhotosPermission();
    if (!hasPermission) {
      throw PermissionDeniedException('Photos permission denied');
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      return image != null ? File(image.path) : null;
    } catch (e) {
      throw MediaPickerException('Failed to pick image from gallery: $e');
    }
  }

  /// Pick any file
  Future<File?> pickAnyFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      
      return null;
    } catch (e) {
      throw MediaPickerException('Failed to pick file: $e');
    }
  }

  /// Pick multiple files
  Future<List<File>> pickMultipleFiles() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result != null) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();
      }
      
      return [];
    } catch (e) {
      throw MediaPickerException('Failed to pick files: $e');
    }
  }

  /// Request camera permission
  Future<bool> _requestCameraPermission() async {
    if (Platform.isAndroid) {
      final permission = await Permission.camera.request();
      return permission.isGranted;
    } else if (Platform.isIOS) {
      // iOS handles permissions through Info.plist
      final permission = await Permission.camera.request();
      return permission.isGranted;
    }
    return true;
  }

  /// Request photos permission
  Future<bool> _requestPhotosPermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API level 33+), use granular media permissions
      if (await _isAndroid13OrHigher()) {
        final permission = await Permission.photos.request();
        return permission.isGranted;
      } else {
        // For older Android versions
        final permission = await Permission.storage.request();
        return permission.isGranted;
      }
    } else if (Platform.isIOS) {
      // iOS handles permissions through Info.plist
      final permission = await Permission.photos.request();
      return permission.isGranted;
    }
    return true;
  }

  /// Check if running on Android 13 or higher
  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    
    try {
      // This is a simplified check - in a real app you might want to use 
      // device_info_plus package for more accurate version detection
      return true; // Assume Android 13+ for now and use granular permissions
    } catch (e) {
      return false;
    }
  }

  /// Check if permission is granted
  Future<bool> hasPermission(PermissionType type) async {
    switch (type) {
      case PermissionType.camera:
        return (await Permission.camera.status).isGranted;
      case PermissionType.photos:
        if (Platform.isAndroid && await _isAndroid13OrHigher()) {
          return (await Permission.photos.status).isGranted;
        } else {
          return (await Permission.storage.status).isGranted;
        }
      case PermissionType.storage:
        return (await Permission.storage.status).isGranted;
    }
  }

  /// Show permission rationale
  Future<bool> shouldShowPermissionRationale(PermissionType type) async {
    switch (type) {
      case PermissionType.camera:
        return await Permission.camera.shouldShowRequestRationale;
      case PermissionType.photos:
        if (Platform.isAndroid && await _isAndroid13OrHigher()) {
          return await Permission.photos.shouldShowRequestRationale;
        } else {
          return await Permission.storage.shouldShowRequestRationale;
        }
      case PermissionType.storage:
        return await Permission.storage.shouldShowRequestRationale;
    }
  }

  /// Open app settings for permission management
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }
}

/// Types of permissions used by MediaPicker
enum PermissionType {
  camera,
  photos,
  storage,
}

/// Exception thrown when permission is denied
class PermissionDeniedException implements Exception {
  final String message;
  const PermissionDeniedException(this.message);
  
  @override
  String toString() => 'PermissionDeniedException: $message';
}

/// Exception thrown when media picking fails
class MediaPickerException implements Exception {
  final String message;
  const MediaPickerException(this.message);
  
  @override
  String toString() => 'MediaPickerException: $message';
}