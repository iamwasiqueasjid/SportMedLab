import 'dart:io';
import 'package:cloudinary/cloudinary.dart';
import 'package:test_project/utils/constants.dart';

class CloudinaryService {
  final Cloudinary _cloudinary;

  CloudinaryService()
    : _cloudinary = Cloudinary.unsignedConfig(
        cloudName: AppConstants.cloudinaryCloudName,
      );

  Future<String?> uploadImage(
    String filePath,
    String uploadPreset, {
    String? fileName,
    String? folder,
  }) async {
    try {
      // Check if file exists
      final File file = File(filePath);
      if (!await file.exists()) {
        print('File does not exist at path: $filePath');
        return null;
      }

      // Ensure file size isn't zero
      final fileStats = await file.stat();
      if (fileStats.size == 0) {
        print('File exists but has zero size');
        return null;
      }

      print('Uploading file: $filePath');
      print('To folder: ${folder ?? "default"}');
      print('With preset: $uploadPreset');
      print('Cloudinary cloud name: ${AppConstants.cloudinaryCloudName}');

      // Verify upload preset is correct - this is crucial
      if (uploadPreset.isEmpty) {
        print('Error: Upload preset is empty');
        return null;
      }

      // Perform the upload with complete parameters - simplified for debugging
      final response = await _cloudinary.unsignedUpload(
        file: filePath,
        uploadPreset: uploadPreset,
        resourceType: CloudinaryResourceType.image,
        // First try without optional parameters that might be causing issues
      );

      if (response.isSuccessful) {
        print('Upload successful! URL: ${response.secureUrl}');
        return response.secureUrl;
      } else {
        print('Cloudinary upload error: ${response.error}');
        print('Status code: ${response.statusCode}');
        // Remove or replace with an existing property
        return null;
      }
    } catch (e) {
      print('Exception during upload: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }
}
