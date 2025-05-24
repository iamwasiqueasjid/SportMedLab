class AppConstants {
  // Cloudinary Configurations
  static const String cloudinaryCloudName = 'dk5trs6zr';

  // Make sure this exact upload preset name exists in your Cloudinary account
  static const String cloudinaryUploadPreset = 'sports-med-lab';

  // These folders will be created automatically in Cloudinary
  static const String cloudinaryUsersFolder = 'sports-med-lab/Users';

  // API URL (for debugging only)
  static String get cloudinaryApiUrl =>
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload';

  static const String FIREBASE_ANDROID_API_KEY =
      'AIzaSyAj1_w04Xo1M5UWrqedF9sj3ZrW5ZYeA38';
  static const String FIREBASE_ANDROID_APP_ID =
      '1:200118990270:android:2747c61b92b769224db5ef';
  static const String FIREBASE_ANDROID_MESSAGING_SENDER_ID = '200118990270';
  static const String FIREBASE_ANDROID_PROJECT_ID = 'sports-med-lab-4f8aa';
  static const String FIREBASE_ANDROID_STORAGE_BUCKET =
      'sports-med-lab-4f8aa.firebasestorage.app';

  static const String FIREBASE_IOS_API_KEY =
      'AIzaSyC5Pdmum1hMmTbg235i_n8WapjY7bgZfXU';
  static const String FIREBASE_IOS_APP_ID =
      '1:200118990270:ios:56eac0ec910a5eab4db5ef';
  static const String FIREBASE_IOS_MESSAGING_SENDER_ID = '200118990270';
  static const String FIREBASE_IOS_PROJECT_ID = 'sports-med-lab-4f8aa';
  static const String FIREBASE_IOS_STORAGE_BUCKET =
      'sports-med-lab-4f8aa.firebasestorage.app';
  static const String FIREBASE_IOS_BUNDLE_ID = 'com.example.testProject';
}
