import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'user';
  String? _selectedMajor;
  String? _selectedBatch;
  String? _selectedConcentration;
  String? _selectedClass;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate student data
    if (_selectedRole == 'user') {
      if (_selectedMajor == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your major'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_selectedBatch == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your batch'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_selectedClass == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your class'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final result = await AuthService().register(
      email: _emailController.text,
      password: _passwordController.text,
      name: _nameController.text,
      role: _selectedRole,
      major: _selectedMajor,
      batch: _selectedBatch,
      concentration: _selectedConcentration,
      classCode: _selectedClass,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );

      if (result['role'] == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin-home');
      } else {
        Navigator.pushReplacementNamed(context, '/user-home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.person_add,
                    size: 60,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Register New Account',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Role Selection
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('Student')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                        if (value == 'admin') {
                          _selectedMajor = null;
                          _selectedBatch = null;
                          _selectedConcentration = null;
                          _selectedClass = null;
                        }
                      });
                    },
                  ),

                  // Show student fields only for students
                  if (_selectedRole == 'user') ...[
                    const SizedBox(height: 16),

                    // Major Selection
                    DropdownButtonFormField<String>(
                      value: _selectedMajor,
                      decoration: const InputDecoration(
                        labelText: 'Major',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      hint: const Text('Select Major'),
                      items: AppConstants.majors.map((major) {
                        return DropdownMenuItem(
                          value: major,
                          child: Text(major),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMajor = value;
                          _selectedConcentration = null; // Reset concentration
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Batch Selection
                    DropdownButtonFormField<String>(
                      value: _selectedBatch,
                      decoration: const InputDecoration(
                        labelText: 'Batch (Angkatan)',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      hint: const Text('Select Batch'),
                      items: AppConstants.batches.map((batch) {
                        return DropdownMenuItem(
                          value: batch,
                          child: Text(batch),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBatch = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Concentration Selection (Optional)
                    if (_selectedMajor != null &&
                        AppConstants.getConcentrationsForMajor(_selectedMajor!)
                            .isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _selectedConcentration,
                        decoration: const InputDecoration(
                          labelText: 'Concentration (Optional)',
                          prefixIcon: Icon(Icons.build_outlined),
                        ),
                        hint: const Text('Select Concentration'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('None'),
                          ),
                          ...AppConstants.getConcentrationsForMajor(
                                  _selectedMajor!)
                              .map((concentration) {
                            return DropdownMenuItem(
                              value: concentration,
                              child: Text(concentration),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedConcentration = value;
                          });
                        },
                      ),
                    const SizedBox(height: 16),

                    // Class Selection
                    DropdownButtonFormField<String>(
                      value: _selectedClass,
                      decoration: const InputDecoration(
                        labelText: 'Class',
                        prefixIcon: Icon(Icons.class_outlined),
                      ),
                      hint: const Text('Select Class'),
                      items: AppConstants.classes.map((classCode) {
                        return DropdownMenuItem(
                          value: classCode,
                          child: Text('Class $classCode'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedClass = value;
                        });
                      },
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          if (mounted) {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          }
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          if (mounted) {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          }
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Register Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Login',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
