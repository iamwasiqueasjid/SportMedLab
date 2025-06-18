import 'dart:io';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:test_project/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/widgets/app_message_notifier.dart';
import 'package:test_project/utils/responsive_extension.dart';
import 'package:test_project/utils/responsive_helper.dart';

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({super.key});

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _emailController = TextEditingController();
  final _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isEditing = false;
  String? _uploadedImageUrl;
  String _role = 'Patient';
  String? _selectedGender;
  DateTime? _selectedDate;
  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await _authService.fetchUserData();
      if (userData != null) {
        setState(() {
          _emailController.text = userData.email;
          _nameController.text = userData.displayName;
          _uploadedImageUrl = userData.photoURL;
          _role = userData.role;

          try {
            final userDataMap = userData as dynamic;
            if (userDataMap.role == 'Patient') {
              _weightController.text = (userDataMap.weight?.toString()) ?? '';
              _heightController.text = (userDataMap.height?.toString()) ?? '';
              _selectedGender = userDataMap.gender;
              if (userDataMap.dateOfBirth != null &&
                  userDataMap.dateOfBirth.isNotEmpty) {
                try {
                  _selectedDate = DateFormat(
                    'yyyy-MM-dd',
                  ).parse(userDataMap.dateOfBirth);
                } catch (e) {
                  _selectedDate = null;
                }
              }
            } else {
              _weightController.text = '';
              _heightController.text = '';
              _selectedGender = null;
              _selectedDate = null;
            }
          } catch (e) {
            _weightController.text = '';
            _heightController.text = '';
            _selectedGender = null;
            _selectedDate = null;
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        AppNotifier.show(
          context,
          'Error loading profile: $e',
          type: MessageType.error,
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;
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
      if (mounted) {
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
  }

  Future<void> _selectDate(BuildContext context) async {
    if (!_isEditing) return;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.grey[100]!,
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
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
          role: _role,
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
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });

        if (mounted) {
          AppNotifier.show(
            context,
            'Profile updated successfully',
            type: MessageType.success,
          );
        }
      } catch (e) {
        if (mounted) {
          AppNotifier.show(
            context,
            'Error updating profile: $e',
            type: MessageType.error,
          );
        }
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        AppNotifier.show(
          context,
          'Please complete all required fields',
          type: MessageType.info,
        );
      }
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _imageFile = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          // Header with edit/save buttons
          Container(
            padding: EdgeInsets.all(
              ResponsiveHelper.getValue(
                context,
                mobile: 16.0,
                tablet: 20.0,
                desktop: 24.0,
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Profile',
                      style: context.responsiveHeadlineMedium.copyWith(
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
                    Text(
                      'Manage your personal details',
                      style: context.responsiveBodyMedium.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : _toggleEdit,
                      child: Text(
                        _isEditing ? 'Cancel' : 'Edit',
                        style: context.responsiveBodyLarge.copyWith(
                          color: _isLoading ? Colors.grey : theme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_isEditing)
                      TextButton(
                        onPressed:
                            _isLoading || _isUploading ? null : _handleSave,
                        child: Text(
                          'Save',
                          style: context.responsiveBodyLarge.copyWith(
                            color:
                                _isLoading || _isUploading
                                    ? Colors.grey
                                    : theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child:
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
                    : SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveHelper.getValue(
                          context,
                          mobile: 20.0,
                          tablet: 24.0,
                          desktop: 32.0,
                        ),
                        vertical: ResponsiveHelper.getValue(
                          context,
                          mobile: 24.0,
                          tablet: 28.0,
                          desktop: 32.0,
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile image section and form fields...
                            // (Rest of the UI code remains the same)
                            Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: ResponsiveHelper.getValue(
                                  context,
                                  mobile: 140.0,
                                  tablet: 160.0,
                                  desktop: 180.0,
                                ),
                                height: ResponsiveHelper.getValue(
                                  context,
                                  mobile: 140.0,
                                  tablet: 160.0,
                                  desktop: 180.0,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.primaryColor.withOpacity(0.1),
                                      Colors.white,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: ResponsiveHelper.getValue(
                                        context,
                                        mobile: 8.0,
                                        tablet: 10.0,
                                        desktop: 12.0,
                                      ),
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: _isEditing ? _pickImage : null,
                                      child: Container(
                                        width: ResponsiveHelper.getValue(
                                          context,
                                          mobile: 130.0,
                                          tablet: 150.0,
                                          desktop: 170.0,
                                        ),
                                        height: ResponsiveHelper.getValue(
                                          context,
                                          mobile: 130.0,
                                          tablet: 150.0,
                                          desktop: 170.0,
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: theme.primaryColor
                                                .withOpacity(
                                                  _isEditing ? 0.8 : 0.3,
                                                ),
                                            width: ResponsiveHelper.getValue(
                                              context,
                                              mobile: 2.0,
                                              tablet: 2.5,
                                              desktop: 3.0,
                                            ),
                                          ),
                                        ),
                                        child: ClipOval(
                                          child:
                                              _isUploading
                                                  ? Center(
                                                    child: SpinKitFadingCircle(
                                                      color: theme.primaryColor,
                                                      size:
                                                          ResponsiveHelper.getValue(
                                                            context,
                                                            mobile: 30.0,
                                                            tablet: 35.0,
                                                            desktop: 40.0,
                                                          ),
                                                    ),
                                                  )
                                                  : _imageFile != null
                                                  ? Image.file(
                                                    _imageFile!,
                                                    width:
                                                        ResponsiveHelper.getValue(
                                                          context,
                                                          mobile: 130.0,
                                                          tablet: 150.0,
                                                          desktop: 170.0,
                                                        ),
                                                    height:
                                                        ResponsiveHelper.getValue(
                                                          context,
                                                          mobile: 130.0,
                                                          tablet: 150.0,
                                                          desktop: 170.0,
                                                        ),
                                                    fit: BoxFit.cover,
                                                  )
                                                  : _uploadedImageUrl != null
                                                  ? Image.network(
                                                    _uploadedImageUrl!,
                                                    width:
                                                        ResponsiveHelper.getValue(
                                                          context,
                                                          mobile: 130.0,
                                                          tablet: 150.0,
                                                          desktop: 170.0,
                                                        ),
                                                    height:
                                                        ResponsiveHelper.getValue(
                                                          context,
                                                          mobile: 130.0,
                                                          tablet: 150.0,
                                                          desktop: 170.0,
                                                        ),
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Image.asset(
                                                          'assets/images/Avatar.png',
                                                          width:
                                                              ResponsiveHelper.getValue(
                                                                context,
                                                                mobile: 130.0,
                                                                tablet: 150.0,
                                                                desktop: 170.0,
                                                              ),
                                                          height:
                                                              ResponsiveHelper.getValue(
                                                                context,
                                                                mobile: 130.0,
                                                                tablet: 150.0,
                                                                desktop: 170.0,
                                                              ),
                                                          fit: BoxFit.cover,
                                                        ),
                                                  )
                                                  : Image.asset(
                                                    'assets/images/Avatar.png',
                                                    width:
                                                        ResponsiveHelper.getValue(
                                                          context,
                                                          mobile: 130.0,
                                                          tablet: 150.0,
                                                          desktop: 170.0,
                                                        ),
                                                    height:
                                                        ResponsiveHelper.getValue(
                                                          context,
                                                          mobile: 130.0,
                                                          tablet: 150.0,
                                                          desktop: 170.0,
                                                        ),
                                                    fit: BoxFit.cover,
                                                  ),
                                        ),
                                      ),
                                    ),
                                    if (_isEditing)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: theme.primaryColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius:
                                                    ResponsiveHelper.getValue(
                                                      context,
                                                      mobile: 4.0,
                                                      tablet: 5.0,
                                                      desktop: 6.0,
                                                    ),
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
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
                                                mobile: 24.0,
                                                tablet: 26.0,
                                                desktop: 28.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
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
                            _buildTextField(
                              label: 'Your Name',
                              controller: _nameController,
                              enabled: false,
                            ),
                            SizedBox(
                              height: ResponsiveHelper.getValue(
                                context,
                                mobile: 24.0,
                                tablet: 28.0,
                                desktop: 32.0,
                              ),
                            ),
                            _buildTextField(
                              label: 'Email',
                              controller: _emailController,
                              enabled: false,
                            ),
                            SizedBox(
                              height: ResponsiveHelper.getValue(
                                context,
                                mobile: 24.0,
                                tablet: 28.0,
                                desktop: 32.0,
                              ),
                            ),
                            _buildTextField(
                              label: 'Weight (kg)',
                              controller: _weightController,
                              enabled: _isEditing,
                              keyboardType: TextInputType.number,
                              suffixText: 'kg',
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
                            SizedBox(
                              height: ResponsiveHelper.getValue(
                                context,
                                mobile: 24.0,
                                tablet: 28.0,
                                desktop: 32.0,
                              ),
                            ),
                            _buildTextField(
                              label: 'Height (cm)',
                              controller: _heightController,
                              enabled: _isEditing,
                              keyboardType: TextInputType.number,
                              suffixText: 'cm',
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
                            _buildDropdownField(
                              label: 'Gender',
                              value: _selectedGender,
                              items: _genders,
                              enabled: _isEditing,
                              onChanged:
                                  (value) =>
                                      setState(() => _selectedGender = value),
                              validator:
                                  (value) =>
                                      value == null
                                          ? 'Please select your gender'
                                          : null,
                            ),
                            SizedBox(
                              height: ResponsiveHelper.getValue(
                                context,
                                mobile: 24.0,
                                tablet: 28.0,
                                desktop: 32.0,
                              ),
                            ),
                            _buildDateField(
                              label: 'Date of Birth',
                              date: _selectedDate,
                              onTap: () => _selectDate(context),
                              enabled: false,
                            ),
                          ],
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  // Keep all the helper methods (_buildTextField, _buildDropdownField, _buildDateField) exactly the same
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType? keyboardType,
    String? suffixText,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.responsiveBodyLarge.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.w600,
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
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getValue(
                context,
                mobile: 12.0,
                tablet: 14.0,
                desktop: 16.0,
              ),
            ),
            boxShadow:
                enabled
                    ? [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.1),
                        blurRadius: ResponsiveHelper.getValue(
                          context,
                          mobile: 6.0,
                          tablet: 7.0,
                          desktop: 8.0,
                        ),
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [],
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: context.responsiveBodyLarge.copyWith(
              color: theme.primaryColor,
            ),
            decoration: InputDecoration(
              hintText: 'Enter $label',
              hintStyle: context.responsiveBodyMedium.copyWith(
                color: theme.primaryColor.withOpacity(0.5),
              ),
              filled: true,
              fillColor: Colors.white,
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
                  color: theme.primaryColor.withOpacity(0.3),
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
                borderSide: BorderSide(color: theme.primaryColor, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getValue(
                    context,
                    mobile: 12.0,
                    tablet: 14.0,
                    desktop: 16.0,
                  ),
                ),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              suffixText: suffixText,
              suffixStyle: context.responsiveBodyMedium.copyWith(
                color: theme.primaryColor,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getValue(
                  context,
                  mobile: 16.0,
                  tablet: 18.0,
                  desktop: 20.0,
                ),
                vertical: ResponsiveHelper.getValue(
                  context,
                  mobile: 14.0,
                  tablet: 16.0,
                  desktop: 18.0,
                ),
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required bool enabled,
    required void Function(String?) onChanged,
    required String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.responsiveBodyLarge.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.w600,
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
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getValue(
                context,
                mobile: 12.0,
                tablet: 14.0,
                desktop: 16.0,
              ),
            ),
            boxShadow:
                enabled
                    ? [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.1),
                        blurRadius: ResponsiveHelper.getValue(
                          context,
                          mobile: 6.0,
                          tablet: 7.0,
                          desktop: 8.0,
                        ),
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              hintText: 'Select $label',
              hintStyle: context.responsiveBodyMedium.copyWith(
                color: theme.primaryColor.withOpacity(0.5),
              ),
              filled: true,
              fillColor: Colors.white,
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
                  color: theme.primaryColor.withOpacity(0.3),
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
                borderSide: BorderSide(color: theme.primaryColor, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getValue(
                    context,
                    mobile: 12.0,
                    tablet: 14.0,
                    desktop: 16.0,
                  ),
                ),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getValue(
                  context,
                  mobile: 16.0,
                  tablet: 18.0,
                  desktop: 20.0,
                ),
                vertical: ResponsiveHelper.getValue(
                  context,
                  mobile: 14.0,
                  tablet: 16.0,
                  desktop: 18.0,
                ),
              ),
            ),
            items:
                items
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item,
                          style: context.responsiveBodyLarge.copyWith(
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    )
                    .toList(),
            onChanged: enabled ? onChanged : null,
            style: context.responsiveBodyLarge.copyWith(
              color: theme.primaryColor,
            ),
            dropdownColor: Colors.white,
            iconEnabledColor: theme.primaryColor,
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.responsiveBodyLarge.copyWith(
            color: theme.primaryColor,
            fontWeight: FontWeight.w600,
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
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getValue(
                context,
                mobile: 12.0,
                tablet: 14.0,
                desktop: 16.0,
              ),
            ),
            boxShadow:
                enabled
                    ? [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.1),
                        blurRadius: ResponsiveHelper.getValue(
                          context,
                          mobile: 6.0,
                          tablet: 7.0,
                          desktop: 8.0,
                        ),
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [],
          ),
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: InputDecorator(
              decoration: InputDecoration(
                hintText: 'Select $label',
                hintStyle: context.responsiveBodyMedium.copyWith(
                  color: theme.primaryColor.withOpacity(0.5),
                ),
                filled: true,
                fillColor: Colors.white,
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
                    color: theme.primaryColor.withOpacity(0.3),
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
                  borderSide: BorderSide(color: theme.primaryColor, width: 2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getValue(
                      context,
                      mobile: 12.0,
                      tablet: 14.0,
                      desktop: 16.0,
                    ),
                  ),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.getValue(
                    context,
                    mobile: 16.0,
                    tablet: 18.0,
                    desktop: 20.0,
                  ),
                  vertical: ResponsiveHelper.getValue(
                    context,
                    mobile: 14.0,
                    tablet: 16.0,
                    desktop: 18.0,
                  ),
                ),
              ),
              child: Text(
                date == null
                    ? 'Select $label'
                    : DateFormat('yyyy-MM-dd').format(date),
                style: context.responsiveBodyLarge.copyWith(
                  color: theme.primaryColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
