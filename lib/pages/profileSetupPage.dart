import 'dart:io';
import 'package:test_project/pages/sideBar.dart';
import 'package:test_project/services/databaseHandler.dart';
import 'package:test_project/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _databaseService = DatabaseService();
  final ImagePicker _picker = ImagePicker();

  String? _selectedRole;
  File? _imageFile;
  bool _isLoading = false;
  bool _isUploading = false;
  String? _uploadedImageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _isUploading = true;
        });

        try {
          // Upload the image immediately after selection
          final imageUrl = await _databaseService.uploadProfilePhoto(
            filePath: image.path,
            context: context,
          );

          if (imageUrl != null) {
            setState(() {
              _uploadedImageUrl = imageUrl;
              _isUploading = false;
            });
          } else {
            setState(() {
              _isUploading = false;
            });
          }
        } catch (e) {
          setState(() {
            _isUploading = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _handleContinue() async {
    if (_formKey.currentState!.validate() && _selectedRole != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Save the profile data - now passing the photoURL if available
        await _databaseService.saveProfileData(
          Name: _nameController.text,
          Role: _selectedRole!,
          PhotoURL: _uploadedImageUrl, // Pass the URL from the earlier upload
          context: context,
        );

        // Navigation will be handled in saveProfileData
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      // Show validation errors or missing role selection
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the profile setup')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(Icons.menu, color: theme.iconTheme.color),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
      ),
      drawer: CustomSidebar(
        userName: _nameController.text.isEmpty ? "User" : _nameController.text,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile Setup',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Circle Avatar with Image Picker and upload indicator
                        Center(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              GestureDetector(
                                onTap: _isUploading ? null : _pickImage,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.colorScheme.surface,
                                  ),
                                  child:
                                      _isUploading
                                          ? Center(
                                            child: CircularProgressIndicator(
                                              color: theme.colorScheme.primary,
                                            ),
                                          )
                                          : ClipOval(
                                            child:
                                                _imageFile != null
                                                    ? Image.file(
                                                      _imageFile!,
                                                      width: 120,
                                                      height: 120,
                                                      fit: BoxFit.cover,
                                                    )
                                                    : Image.asset(
                                                      'assets/images/Avatar.png',
                                                      width: 120,
                                                      height: 120,
                                                      fit: BoxFit.cover,
                                                    ),
                                          ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    _isUploading
                                        ? Icons.hourglass_top
                                        : Icons.camera_alt,
                                    color: theme.colorScheme.onPrimary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_uploadedImageUrl != null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Image uploaded successfully!',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Name input field
                        Text('Your Name', style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Role selection (Tutor or Student)
                        Text(
                          'Select Your Role',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _RoleCard(
                                title: 'Tutor',
                                icon: Icons.school,
                                isSelected: _selectedRole == 'Tutor',
                                iconColor: AppColors.lightTextSecondary,
                                onTap:
                                    () =>
                                        setState(() => _selectedRole = 'Tutor'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _RoleCard(
                                title: 'Student',
                                icon: Icons.person,
                                isSelected: _selectedRole == 'Student',
                                iconColor: AppColors.darkTextSecondary,
                                onTap:
                                    () => setState(
                                      () => _selectedRole = 'Student',
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed:
                                (_isLoading || _isUploading)
                                    ? null
                                    : _handleContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: theme.colorScheme.primary
                                  .withOpacity(0.5),
                            ),
                            child:
                                _isLoading
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : Text(
                                      'Continue',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            color: theme.colorScheme.onPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final Color iconColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? theme.colorScheme.onPrimary : iconColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color:
                    isSelected ? theme.colorScheme.onPrimary : theme.hintColor,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
