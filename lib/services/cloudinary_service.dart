import 'dart:io';
import 'package:cloudinary/cloudinary.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;

class CloudinaryService {
  final Cloudinary _cloudinary;

  CloudinaryService()
    : _cloudinary = Cloudinary.unsignedConfig(
        cloudName: dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '',
      );

  /// Detects the resource type based on file extension.
  CloudinaryResourceType _detectResourceType(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    if ([
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
      '.tiff',
      '.ico',
    ].contains(ext)) {
      return CloudinaryResourceType.image;
    } else if (ext == '.pdf') {
      return CloudinaryResourceType.raw;
    } else {
      // Default to raw for unknown types, or handle as needed
      return CloudinaryResourceType.raw;
    }
  }

  Future<String?> uploadToCloudinary(
    String filePath,
    String uploadPreset,
  ) async {
    try {
      // Check if file exists
      final File file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      // Ensure file size isn't zero
      final fileStats = await file.stat();
      if (fileStats.size == 0) {
        return null;
      }

      // Verify upload preset is correct
      if (uploadPreset.isEmpty) {
        return null;
      }

      // Detect resource type
      final resourceType = _detectResourceType(filePath);

      // Perform the upload with detected resource type
      final response = await _cloudinary.unsignedUpload(
        file: filePath,
        uploadPreset: uploadPreset,
        resourceType: resourceType,
      );

      if (response.isSuccessful) {
        return response.secureUrl;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Deletes a resource from Cloudinary using its public ID.
  Future<bool> deleteFromCloudinary(String publicId) async {
    try {
      if (publicId.isEmpty) {
        return false;
      }

      final response = await _cloudinary.destroy(publicId);
      return response.isSuccessful;
    } catch (e) {
      return false;
    }
  }
}
