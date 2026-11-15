
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  final Future<void> Function(
    String identifier,
    String password,
  )? onLogin;

  final VoidCallback? onRegister;
  final VoidCallback? onForgotPassword;

  const LoginScreen({
    super.key,
    this.onLogin,
    this.onRegister,
    this.onForgotPassword,
  });

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController identifierController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.onLogin == null) {
      showMessage(
        'सुरक्षित लॉगिन सेवा अभी जोड़ी जानी बाकी है।',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await widget.onLogin!(
        identifierController.text.trim(),
        passwordController.text,
      );
    } catch (e) {
      if (mounted) {
        showMessage(
          'लॉगिन नहीं हो सका। कृपया अपनी जानकारी जाँचें।',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void register() {
    if (widget.onRegister != null) {
      widget.onRegister!();
    } else {
      showMessage(
        'नया अकाउंट बनाने का पेज अगले चरण में जुड़ेगा।',
      );
    }
  }

  void forgotPassword() {
    if (widget.onForgotPassword != null) {
      widget.onForgotPassword!();
    } else {
      showMessage(
        'पासवर्ड रिकवरी की सुविधा अगले चरण में जुड़ेगी।',
      );
    }
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('सुरक्षित लॉगिन'),
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,

              children: [

                const SizedBox(height: 15),

                const Semantics(
                  label: 'Smart Vision Reader लोगो',
                  child: Icon(
                    Icons.visibility,
                    size: 85,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  'Smart Vision Reader',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'पढ़ें, सुनें और सीखें।',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17),
                ),

                const SizedBox(height: 30),

                const Text(
                  'अपने अकाउंट में लॉगिन करें',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                TextFormField(
                  controller: identifierController,
                  keyboardType: TextInputType.text,
                  autofillHints: const [
                    AutofillHints.username,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'मोबाइल नंबर या ईमेल',
                    hintText: 'अपना मोबाइल या ईमेल लिखें',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'मोबाइल नंबर या ईमेल आवश्यक है।';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  autofillHints: const [
                    AutofillHints.password,
                  ],
                  decoration: InputDecoration(
                    labelText: 'पासवर्ड',
                    hintText: 'अपना पासवर्ड लिखें',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: obscurePassword
                          ? 'पासवर्ड दिखाएँ'
                          : 'पासवर्ड छिपाएँ',
                      onPressed: () {
                        setState(() {
                          obscurePassword =
                              !obscurePassword;
                        });
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'पासवर्ड आवश्यक है।';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: forgotPassword,
                    child: const Text(
                      'पासवर्ड भूल गए?',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed:
                        isLoading ? null : login,
                    icon: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.login,
                            size: 25,
                          ),
                    label: Text(
                      isLoading
                          ? 'कृपया प्रतीक्षा करें'
                          : 'लॉगिन करें',
                      style: const TextStyle(
                        fontSize: 19,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Divider(),

                const SizedBox(height: 15),

                const Text(
                  'नए उपयोगकर्ता हैं?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17),
                ),

                const SizedBox(height: 10),

                OutlinedButton.icon(
                  onPressed: register,
                  icon: const Icon(Icons.person_add),
                  label: const Text(
                    'नया अकाउंट बनाएँ',
                    style: TextStyle(fontSize: 17),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      52,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                const Divider(),

                const SizedBox(height: 12),

                const Text(
                  'सदस्यता एवं सुविधाएँ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                const Text(
                  'सत्यापित पात्र दृष्टिबाधित विद्यार्थियों '
                  'को निर्धारित निःशुल्क सुविधाएँ मिलेंगी। '
                  'अन्य उपयोगकर्ताओं के लिए निर्धारित '
                  'सदस्यता शुल्क लागू होगा।',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),

                const SizedBox(height: 20),

                const Text(
                  'आपकी निजी जानकारी सुरक्षित रखना '
                  'हमारी प्राथमिकता है।',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
