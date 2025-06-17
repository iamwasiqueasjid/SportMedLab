import 'dart:io';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/widgets/app_message_notifier.dart';
import 'package:test_project/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:test_project/utils/responsive_extension.dart';
import 'package:test_project/utils/responsive_helper.dart';

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
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error picking image: $e',
            style: context.responsiveBodyMedium,
          ),
        ),
      );
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
        // Upload image to Cloudinary if selected
        if (_imageFile != null) {
          setState(() {
            _isUploading = true;
          });
          final imageUrl = await _authService.uploadProfilePhoto(
            filePath: _imageFile!.path,
            context: context,
          );
          setState(() {
            _uploadedImageUrl = imageUrl;
            _isUploading = false;
          });
        }
        await _authService.saveProfileData(
          name: _nameController.text,
          role: 'Patient',
          photoURL: _uploadedImageUrl,
          weight: double.tryParse(_weightController.text) ?? 0.0,
          height: double.tryParse(_heightController.text) ?? 0.0,
          gender: _selectedGender ?? '',
          dateOfBirth:
              _selectedDate != null
                  ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                  : '',
          context: context,
        );
      } catch (e) {
        AppNotifier.show(
          context,
          'Error saving profile: $e',
          type: MessageType.error,
        );
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      AppNotifier.show(
        context,
        'Please complete all required fields',
        type: MessageType.info,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white, // Match LoginScreen background
      body:
          _isLoading
              ? Center(
                child: SpinKitDoubleBounce(
                  color: const Color(0xFF0A2D7B),
                  size: ResponsiveHelper.getValue(
                    context,
                    mobile: 40.0,
                    tablet: 50.0,
                    desktop: 60.0,
                  ),
                ),
              )
              : SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getValue(
                      context,
                      mobile: 24.0,
                      tablet: 32.0,
                      desktop: 40.0,
                    ),
                    vertical: ResponsiveHelper.getValue(
                      context,
                      mobile: 20.0,
                      tablet: 24.0,
                      desktop: 28.0,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'Profile Setup',
                          style: context.responsiveHeadlineMedium.copyWith(
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveHelper.getValue(
                            context,
                            mobile: 8.0,
                            tablet: 10.0,
                            desktop: 12.0,
                          ),
                        ),
                        Text(
                          'Complete your profile to get started.',
                          style: context.responsiveBodyMedium.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveHelper.getValue(
                            context,
                            mobile: 32.0,
                            tablet: 36.0,
                            desktop: 40.0,
                          ),
                        ),

                        // Image picker
                        Center(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              GestureDetector(
                                onTap: _isUploading ? null : _pickImage,
                                child: Container(
                                  width: ResponsiveHelper.getValue(
                                    context,
                                    mobile: 120.0,
                                    tablet: 140.0,
                                    desktop: 160.0,
                                  ),
                                  height: ResponsiveHelper.getValue(
                                    context,
                                    mobile: 120.0,
                                    tablet: 140.0,
                                    desktop: 160.0,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[100],
                                    border: Border.all(
                                      color: theme.primaryColor,
                                      width: ResponsiveHelper.getValue(
                                        context,
                                        mobile: 1.0,
                                        tablet: 1.5,
                                        desktop: 2.0,
                                      ),
                                    ),
                                  ),
                                  child:
                                      _isUploading
                                          ? Center(
                                            child: SpinKitDoubleBounce(
                                              color: const Color(0xFF0A2D7B),
                                              size: ResponsiveHelper.getValue(
                                                context,
                                                mobile: 30.0,
                                                tablet: 35.0,
                                                desktop: 40.0,
                                              ),
                                            ),
                                          )
                                          : ClipOval(
                                            child:
                                                _imageFile != null
                                                    ? Image.file(
                                                      _imageFile!,
                                                      width:
                                                          ResponsiveHelper.getValue(
                                                            context,
                                                            mobile: 120.0,
                                                            tablet: 140.0,
                                                            desktop: 160.0,
                                                          ),
                                                      height:
                                                          ResponsiveHelper.getValue(
                                                            context,
                                                            mobile: 120.0,
                                                            tablet: 140.0,
                                                            desktop: 160.0,
                                                          ),
                                                      fit: BoxFit.cover,
                                                    )
                                                    : Image.asset(
                                                      'assets/images/Avatar.png',
                                                      width:
                                                          ResponsiveHelper.getValue(
                                                            context,
                                                            mobile: 120.0,
                                                            tablet: 140.0,
                                                            desktop: 160.0,
                                                          ),
                                                      height:
                                                          ResponsiveHelper.getValue(
                                                            context,
                                                            mobile: 120.0,
                                                            tablet: 140.0,
                                                            desktop: 160.0,
                                                          ),
                                                      fit: BoxFit.cover,
                                                    ),
                                          ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(
                                    ResponsiveHelper.getValue(
                                      context,
                                      mobile: 8.0,
                                      tablet: 10.0,
                                      desktop: 12.0,
                                    ),
                                  ),
                                  child: Icon(
                                    _isUploading
                                        ? Icons.hourglass_top
                                        : Icons.camera_alt,
                                    color: Colors.white,
                                    size: ResponsiveHelper.getValue(
                                      context,
                                      mobile: 20.0,
                                      tablet: 22.0,
                                      desktop: 24.0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_uploadedImageUrl != null)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: ResponsiveHelper.getValue(
                                  context,
                                  mobile: 8.0,
                                  tablet: 10.0,
                                  desktop: 12.0,
                                ),
                              ),
                              child: Text(
                                'Image uploaded successfully!',
                                style: context.responsiveBodyMedium.copyWith(
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ),
                        SizedBox(
                          height: ResponsiveHelper.getValue(
                            context,
                            mobile: 24.0,
                            tablet: 28.0,
                            desktop: 32.0,
                          ),
                        ),

                        // Name input
                        Text(
                          'Your Name',
                          style: context.responsiveBodyLarge.copyWith(
                            color: theme.primaryColor,
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveHelper.getValue(
                            context,
                            mobile: 8.0,
                            tablet: 10.0,
                            desktop: 12.0,
                          ),
                        ),
                        TextFormField(
                          controller: _nameController,
                          style: context.responsiveBodyLarge.copyWith(
                            color: theme.primaryColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter your name',
                            hintStyle: context.responsiveBodyMedium.copyWith(
                              color: theme.primaryColor,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveHelper.getValue(
                                  context,
                                  mobile: 12.0,
                                  tablet: 14.0,
                                  desktop: 16.0,
                                ),
                              ),
                              borderSide: BorderSide(color: theme.primaryColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveHelper.getValue(
                                  context,
                                  mobile: 12.0,
                                  tablet: 14.0,
                                  desktop: 16.0,
                                ),
                              ),
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
                        SizedBox(
                          height: ResponsiveHelper.getValue(
                            context,
                            mobile: 24.0,
                            tablet: 28.0,
                            desktop: 32.0,
                          ),
                        ),

                        // Weight input with unit toggle
                        Text(
                          'Weight',
                          style: context.responsiveBodyLarge.copyWith(
                            color: theme.primaryColor,
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveHelper.getValue(
                            context,
                            mobile: 8.0,
                            tablet: 10.0,
                            desktop: 12.0,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _weightController,
                                style: context.responsiveBodyLarge.copyWith(
                                  color: theme.primaryColor,
                                ),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Enter your weight',
                                  hintStyle: context.responsiveBodyMedium
                                      .copyWith(color: theme.primaryColor),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      ResponsiveHelper.getValue(
                                        context,
                                        mobile: 12.0,
                                        tablet: 14.0,
                                        desktop: 16.0,
                                      ),
                                    ),
                                    borderSide: BorderSide(
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      ResponsiveHelper.getValue(
                                        context,
                                        mobile: 12.0,
                                        tablet: 14.0,
                                        desktop: 16.0,
                                      ),
                                    ),
                                    borderSide: BorderSide(
                                      color: theme.primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  suffixText: 'kg',
                                  suffixStyle: context.responsiveBodyMedium
                                      .copyWith(color: theme.primaryColor),
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
                          ],
                        ),
                        SizedBox(
                          height: ResponsiveHelper.getValue(
                            context,
                            mobile: 24.0,
                            tablet: 28.0,
                            desktop: 32.0,
                          ),
                        ),

                        // Height input
                        Text(
                          'Height (cm)',
                          style: context.responsiveBodyLarge.copyWith(
                            color: theme.primaryColor,
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveHelper.getValue(
                            context,
                            mobile: 8.0,
                            tablet: 10.0,
                            desktop: 12.0,
                          ),
                        ),
                        TextFormField(
                          controller: _heightController,
                          style: context.responsiveBodyLarge.copyWith(
                            color: theme.primaryColor,
                          ),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter your height',
                            hintStyle: context.responsiveBodyMedium.copyWith(
                              color: theme.primaryColor,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveHelper.getValue(
                                  context,
                                  mobile: 12.0,
                                  tablet: 14.0,
                                  desktop: 16.0,
                                ),
                              ),
                              borderSide: BorderSide(color: theme.primaryColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveHelper.getValue(
                                  context,
                                  mobile: 12.0,
                                  tablet: 14.0,
                                  desktop: 16.0,
                                ),
                              ),
                              borderSide: BorderSide(
                                color: theme.primaryColor,
                                width: 2,
                              ),
                            ),
                            suffixText: 'cm',
                            suffixStyle: context.responsiveBodyMedium.copyWith(
                              color: theme.primaryColor,
                            ),
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
                        SizedBox(
                          height: ResponsiveHelper.getValue(
                            context,
                            mobile: 24.0,
                            tablet: 28.0,
                            desktop: 32.0,
                          ),
                        ),

                        // Gender dropdown
                        Text(
                          'Gender',
                          style: context.responsiveBodyLarge.copyWith(
                            color: theme.primaryColor,
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveHelper.getValue(
                            context,
                            mobile: 8.0,
                            tablet: 10.0,
                            desktop: 12.0,
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: InputDecoration(
                            hintText: 'Select gender',
                            hintStyle: context.responsiveBodyMedium.copyWith(
                              color: theme.primaryColor,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveHelper.getValue(
                                  context,
                                  mobile: 12.0,
                                  tablet: 14.0,
                                  desktop: 16.0,
                                ),
                              ),
                              borderSide: BorderSide(color: theme.primaryColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                ResponsiveHelper.getValue(
                                  context,
                                  mobile: 12.0,
                                  tablet: 14.0,
                                  desktop: 16.0,
                                ),
                              ),
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
                                        style: context.responsiveBodyLarge
                                            .copyWith(
                                              color: theme.primaryColor,
                                            ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value;
                            });
                          },
                          style: context.responsiveBodyLarge.copyWith(
                            color: theme.primaryColor,
                          ),
                          dropdownColor: Colors.grey[100],
                          iconEnabledColor: theme.primaryColor,
                          validator: (value) {
                            if (value == null) {
                              return 'Please select your gender';
                            }
                            return null;
                          },
                        ),
                        SizedBox(
                          height: ResponsiveHelper.getValue(
                            context,
                            mobile: 24.0,
                            tablet: 28.0,
                            desktop: 32.0,
                          ),
                        ),

                        // Date of birth
                        Text(
                          'Date of Birth',
                          style: context.responsiveBodyLarge.copyWith(
                            color: theme.primaryColor,
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveHelper.getValue(
                            context,
                            mobile: 8.0,
                            tablet: 10.0,
                            desktop: 12.0,
                          ),
                        ),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              hintText: 'Select date',
                              hintStyle: context.responsiveBodyMedium.copyWith(
                                color: theme.primaryColor,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getValue(
                                    context,
                                    mobile: 12.0,
                                    tablet: 14.0,
                                    desktop: 16.0,
                                  ),
                                ),
                                borderSide: BorderSide(
                                  color: theme.primaryColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getValue(
                                    context,
                                    mobile: 12.0,
                                    tablet: 14.0,
                                    desktop: 16.0,
                                  ),
                                ),
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
                              style: context.responsiveBodyLarge.copyWith(
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveHelper.getValue(
                            context,
                            mobile: 24.0,
                            tablet: 28.0,
                            desktop: 32.0,
                          ),
                        ),

                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          height: ResponsiveHelper.getValue(
                            context,
                            mobile: 50.0,
                            tablet: 55.0,
                            desktop: 60.0,
                          ),
                          child: ElevatedButton(
                            onPressed:
                                (_isLoading || _isUploading)
                                    ? null
                                    : _handleContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getValue(
                                    context,
                                    mobile: 12.0,
                                    tablet: 14.0,
                                    desktop: 16.0,
                                  ),
                                ),
                              ),
                              disabledBackgroundColor: theme.primaryColor
                                  .withOpacity(0.5),
                            ),
                            child:
                                _isLoading
                                    ? SpinKitDoubleBounce(
                                      color: theme.primaryColor,
                                      size: ResponsiveHelper.getValue(
                                        context,
                                        mobile: 30.0,
                                        tablet: 35.0,
                                        desktop: 40.0,
                                      ),
                                    )
                                    : Text(
                                      'Continue',
                                      style: context.responsiveBodyLarge
                                          .copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                          ),
                        ),
                        SizedBox(
                          height: ResponsiveHelper.getValue(
                            context,
                            mobile: 24.0,
                            tablet: 28.0,
                            desktop: 32.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
