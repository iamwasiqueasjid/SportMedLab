import 'dart:io';
import 'package:test_project/utils/side_bar.dart';
import 'package:test_project/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  bool _isLoading = false;
  bool _isUploading = false;
  String? _uploadedImageUrl;
  String _weightUnit = 'kg'; // Default weight unit
  String? _selectedGender;
  DateTime? _selectedDate;
  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
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
          final imageUrl = await _authService.uploadProfilePhoto(
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

  // Function to show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleContinue() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _authService.saveProfileData(
          name: _nameController.text,
          role: 'Patient',
          photoURL: _uploadedImageUrl,
          weight: double.tryParse(_weightController.text) ?? 0.0,
          weightUnit: _weightUnit,
          height: double.tryParse(_heightController.text) ?? 0.0,
          gender: _selectedGender ?? '',
          dateOfBirth:
              _selectedDate != null
                  ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                  : '',
          context: context,
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white, // Match LoginScreen background
      appBar: AppBar(
        backgroundColor: Colors.white, // Match LoginScreen
        elevation: 0,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(
                  Icons.menu,
                  color: theme.primaryColor,
                ), // Use primaryColor
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
              : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'Profile Setup',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // Match LoginScreen
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete your profile to get started.',
                          style: TextStyle(
                            color: Colors.grey[700],
                          ), // Match LoginScreen
                        ),
                        const SizedBox(height: 32),

                        // Image picker
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
                                    color:
                                        Colors
                                            .grey[100], // Match LoginScreen field fill
                                    border: Border.all(
                                      color:
                                          theme
                                              .primaryColor, // Match LoginScreen
                                      width: 1,
                                    ),
                                  ),
                                  child:
                                      _isUploading
                                          ? Center(
                                            child: CircularProgressIndicator(
                                              color:
                                                  theme
                                                      .primaryColor, // Match LoginScreen
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
                                  color:
                                      theme.primaryColor, // Match LoginScreen
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    _isUploading
                                        ? Icons.hourglass_top
                                        : Icons.camera_alt,
                                    color:
                                        Colors
                                            .white, // Match LoginScreen button text
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

                        // Name input
                        Text(
                          'Your Name',
                          style: TextStyle(
                            color: theme.primaryColor,
                          ), // Match LoginScreen
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(
                            color: theme.primaryColor,
                          ), // Match LoginScreen
                          decoration: InputDecoration(
                            hintText: 'Enter your name',
                            hintStyle: TextStyle(
                              color: theme.primaryColor,
                            ), // Match LoginScreen
                            filled: true,
                            fillColor: Colors.grey[100], // Match LoginScreen
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.primaryColor,
                              ), // Match LoginScreen
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.primaryColor,
                                width: 2,
                              ),
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

                        // Weight input with unit toggle
                        Text(
                          'Weight',
                          style: TextStyle(
                            color: theme.primaryColor,
                          ), // Match LoginScreen
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _weightController,
                                style: TextStyle(
                                  color: theme.primaryColor,
                                ), // Match LoginScreen
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Enter your weight',
                                  hintStyle: TextStyle(
                                    color: theme.primaryColor,
                                  ), // Match LoginScreen
                                  filled: true,
                                  fillColor:
                                      Colors.grey[100], // Match LoginScreen
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: theme.primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  suffixText: _weightUnit,
                                  suffixStyle: TextStyle(
                                    color: theme.primaryColor,
                                  ), // Match LoginScreen
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your weight';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: _weightUnit,
                              items:
                                  ['kg', 'lb']
                                      .map(
                                        (unit) => DropdownMenuItem(
                                          value: unit,
                                          child: Text(
                                            unit,
                                            style: TextStyle(
                                              color: theme.primaryColor,
                                            ), // Match LoginScreen
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _weightUnit = value;
                                  });
                                }
                              },
                              style: TextStyle(
                                color: theme.primaryColor,
                              ), // Match LoginScreen
                              dropdownColor:
                                  Colors.grey[100], // Match LoginScreen
                              iconEnabledColor:
                                  theme.primaryColor, // Match LoginScreen
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Height input
                        Text(
                          'Height (cm)',
                          style: TextStyle(
                            color: theme.primaryColor,
                          ), // Match LoginScreen
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _heightController,
                          style: TextStyle(
                            color: theme.primaryColor,
                          ), // Match LoginScreen
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter your height',
                            hintStyle: TextStyle(
                              color: theme.primaryColor,
                            ), // Match LoginScreen
                            filled: true,
                            fillColor: Colors.grey[100], // Match LoginScreen
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: theme.primaryColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.primaryColor,
                                width: 2,
                              ),
                            ),
                            suffixText: 'cm',
                            suffixStyle: TextStyle(
                              color: theme.primaryColor,
                            ), // Match LoginScreen
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your height';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Gender dropdown
                        Text(
                          'Gender',
                          style: TextStyle(
                            color: theme.primaryColor,
                          ), // Match LoginScreen
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: InputDecoration(
                            hintText: 'Select gender',
                            hintStyle: TextStyle(
                              color: theme.primaryColor,
                            ), // Match LoginScreen
                            filled: true,
                            fillColor: Colors.grey[100], // Match LoginScreen
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: theme.primaryColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                          items:
                              _genders
                                  .map(
                                    (gender) => DropdownMenuItem(
                                      value: gender,
                                      child: Text(
                                        gender,
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                        ), // Match LoginScreen
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value;
                            });
                          },
                          style: TextStyle(
                            color: theme.primaryColor,
                          ), // Match LoginScreen
                          dropdownColor: Colors.grey[100], // Match LoginScreen
                          iconEnabledColor:
                              theme.primaryColor, // Match LoginScreen
                          validator: (value) {
                            if (value == null) {
                              return 'Please select your gender';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Date of birth
                        Text(
                          'Date of Birth',
                          style: TextStyle(
                            color: theme.primaryColor,
                          ), // Match LoginScreen
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              hintText: 'Select date',
                              hintStyle: TextStyle(
                                color: theme.primaryColor,
                              ), // Match LoginScreen
                              filled: true,
                              fillColor: Colors.grey[100], // Match LoginScreen
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.primaryColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              _selectedDate == null
                                  ? 'Select date'
                                  : DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(_selectedDate!),
                              style: TextStyle(
                                color: theme.primaryColor,
                              ), // Match LoginScreen
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          height: 50, // Match LoginScreen button height
                          child: ElevatedButton(
                            onPressed:
                                (_isLoading || _isUploading)
                                    ? null
                                    : _handleContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  theme.primaryColor, // Match LoginScreen
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: theme.primaryColor
                                  .withOpacity(0.5),
                            ),
                            child:
                                _isLoading
                                    ? CircularProgressIndicator(
                                      color: Colors.white, // Match LoginScreen
                                    )
                                    : const Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color:
                                            Colors.white, // Match LoginScreen
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
