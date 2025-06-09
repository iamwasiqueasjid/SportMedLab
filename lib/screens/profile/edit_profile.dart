import 'dart:io';
import 'package:test_project/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:test_project/utils/message_type.dart';
import 'package:test_project/widgets/app_message_notifier.dart';
import 'package:test_project/widgets/custom_drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
  String _weightUnit = 'kg';
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
          _emailController.text = userData['email'] ?? '';
          _nameController.text = userData['displayName'] ?? '';
          _role = userData['role'] ?? 'Patient';
          _weightController.text = userData['weight']?.toString() ?? '';
          _heightController.text = userData['height']?.toString() ?? '';
          _weightUnit = userData['weightUnit'] ?? 'kg';
          _selectedGender = userData['gender'];
          _uploadedImageUrl = userData['photoURL'];
          if (userData['dateOfBirth'] != null &&
              userData['dateOfBirth'].isNotEmpty) {
            _selectedDate = DateFormat(
              'yyyy-MM-dd',
            ).parse(userData['dateOfBirth']);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      AppNotifier.show(
        context,
        'Error loading profile: $e',
        type: MessageType.error,
      );
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

          AppNotifier.show(
            context,
            'Failed to upload image: $e',
            type: MessageType.error,
          );
        }
      }
    } catch (e) {
      AppNotifier.show(
        context,
        'Error picking image: $e',
        type: MessageType.error,
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (!_isEditing) return;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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
        await _authService.saveProfileData(
          name: _nameController.text,
          role: _role,
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
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });

        AppNotifier.show(
          context,
          'Profile updated successfully',
          type: MessageType.success,
        );
      } catch (e) {
        AppNotifier.show(
          context,
          'Error updating profile: $e',
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

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(Icons.menu, color: theme.primaryColor),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _toggleEdit,
            child: Text(
              _isEditing ? 'Cancel' : 'Edit',
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_isEditing)
            TextButton(
              onPressed: _isLoading || _isUploading ? null : _handleSave,
              child: Text(
                'Save',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      drawer: CustomDrawer(
        userName: _nameController.text.isEmpty ? "User" : _nameController.text,
        photoUrl: _uploadedImageUrl,
        role: 'Patient',
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
                        Text(
                          'Your Profile',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'View or update your profile details.',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[100],
                                    border: Border.all(
                                      color: theme.primaryColor,
                                      width: 1,
                                    ),
                                  ),
                                  child:
                                      _isUploading
                                          ? Center(
                                            child: CircularProgressIndicator(
                                              color: theme.primaryColor,
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
                                                    : _uploadedImageUrl != null
                                                    ? Image.network(
                                                      _uploadedImageUrl!,
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
                              if (_isEditing)
                                Container(
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      _isUploading
                                          ? Icons.hourglass_top
                                          : Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_uploadedImageUrl != null && _isEditing)
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
                        Text(
                          'Your Name',
                          style: TextStyle(color: theme.primaryColor),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          enabled: _isEditing,
                          style: TextStyle(color: theme.primaryColor),
                          decoration: InputDecoration(
                            hintText: 'Enter your name',
                            hintStyle: TextStyle(color: theme.primaryColor),
                            filled: true,
                            fillColor: Colors.grey[100],
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
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
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
                        Text(
                          'Weight',
                          style: TextStyle(color: theme.primaryColor),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _weightController,
                                enabled: _isEditing,
                                style: TextStyle(color: theme.primaryColor),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Enter your weight',
                                  hintStyle: TextStyle(
                                    color: theme.primaryColor,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
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
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  suffixText: _weightUnit,
                                  suffixStyle: TextStyle(
                                    color: theme.primaryColor,
                                  ),
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
                            if (_isEditing)
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
                                              ),
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
                                style: TextStyle(color: theme.primaryColor),
                                dropdownColor: Colors.grey[100],
                                iconEnabledColor: theme.primaryColor,
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Height (cm)',
                          style: TextStyle(color: theme.primaryColor),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _heightController,
                          enabled: _isEditing,
                          style: TextStyle(color: theme.primaryColor),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter your height',
                            hintStyle: TextStyle(color: theme.primaryColor),
                            filled: true,
                            fillColor: Colors.grey[100],
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
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            suffixText: 'cm',
                            suffixStyle: TextStyle(color: theme.primaryColor),
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
                        Text(
                          'Gender',
                          style: TextStyle(color: theme.primaryColor),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: InputDecoration(
                            hintText: 'Select gender',
                            hintStyle: TextStyle(color: theme.primaryColor),
                            filled: true,
                            fillColor: Colors.grey[100],
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
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
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
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              _isEditing
                                  ? (value) {
                                    setState(() {
                                      _selectedGender = value;
                                    });
                                  }
                                  : null,
                          style: TextStyle(color: theme.primaryColor),
                          dropdownColor: Colors.grey[100],
                          iconEnabledColor: theme.primaryColor,
                          validator: (value) {
                            if (value == null) {
                              return 'Please select your gender';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Date of Birth',
                          style: TextStyle(color: theme.primaryColor),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              hintText: 'Select date',
                              hintStyle: TextStyle(color: theme.primaryColor),
                              filled: true,
                              fillColor: Colors.grey[100],
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
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                            ),
                            child: Text(
                              _selectedDate == null
                                  ? 'Select date'
                                  : DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(_selectedDate!),
                              style: TextStyle(color: theme.primaryColor),
                            ),
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
