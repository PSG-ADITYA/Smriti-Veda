import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/db_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class ForgotUsernameScreen extends StatefulWidget {
  const ForgotUsernameScreen({super.key});

  @override
  State<ForgotUsernameScreen> createState() => _ForgotUsernameScreenState();
}

class _ForgotUsernameScreenState extends State<ForgotUsernameScreen> {
  final _inputController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _foundUser;
  bool _searched = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _handleFindUsername() {
    SoundService().playClickSound();
    final query = _inputController.text.trim().toLowerCase();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your registered Email address or Phone number.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _foundUser = null;
      _searched = false;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      final user = DbService().findUserByEmailOrPhone(query);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _foundUser = user;
          _searched = true;
        });
        if (user != null) {
          SoundService().playSuccessSound();
        } else {
          SoundService().playErrorSound();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasIvory,
      appBar: AppBar(
        backgroundColor: AppColors.canvasIvory,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.charcoalText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Recover Username / ID',
          style: GoogleFonts.newsreader(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.terracottaPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Forgot Your Username?',
                    style: GoogleFonts.newsreader(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.charcoalText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your registered Email address or Phone number to recover your Username / Credential ID.',
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 14,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Search Field Card
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.sandalwoodGold.withValues(alpha: 0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _inputController,
                            decoration: InputDecoration(
                              labelText: 'Registered Email or Phone Number',
                              hintText: 'e.g. name@example.com or 9876543210',
                              prefixIcon: const Icon(Icons.account_box_outlined, color: AppColors.terracottaPrimary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: AppColors.canvasIvory,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleFindUsername,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.terracottaPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      'Find Username',
                                      style: GoogleFonts.atkinsonHyperlegible(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Search Result Display Card
                  if (_searched && _foundUser != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.sageSoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.sageSecondary, width: 1.5),
                        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.sageSecondary, size: 28),
                              const SizedBox(width: 10),
                              Text(
                                'Account Found!',
                                style: GoogleFonts.newsreader(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.charcoalText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: AppColors.borderSubtle),
                          const SizedBox(height: 14),

                          Text(
                            'REGISTERED USERNAME / CREDENTIAL ID:',
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: AppColors.terracottaPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            _foundUser!['uid'] ?? _foundUser!['email'] ?? 'User ID',
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.charcoalText,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Text(
                            'Full Name: ${_foundUser!['name'] ?? 'N/A'}',
                            style: GoogleFonts.atkinsonHyperlegible(fontSize: 14, color: AppColors.charcoalText),
                          ),
                          Text(
                            'Email: ${_foundUser!['email'] ?? 'N/A'}',
                            style: GoogleFonts.atkinsonHyperlegible(fontSize: 14, color: AppColors.secondaryText),
                          ),
                          Text(
                            'Role: ${_foundUser!['role'] ?? 'Patient'}',
                            style: GoogleFonts.atkinsonHyperlegible(fontSize: 14, color: AppColors.secondaryText),
                          ),
                          const SizedBox(height: 18),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    final username = _foundUser!['uid'] ?? _foundUser!['email'] ?? '';
                                    Clipboard.setData(ClipboardData(text: username));
                                    SoundService().playTapSound();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Username copied to clipboard!')),
                                    );
                                  },
                                  icon: const Icon(Icons.copy, size: 16),
                                  label: const Text('Copy ID'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.charcoalText,
                                    side: const BorderSide(color: AppColors.borderSubtle),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    SoundService().playClickSound();
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.login, size: 16),
                                  label: const Text('Go to Login'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.terracottaPrimary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else if (_searched && _foundUser == null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
                          const SizedBox(height: 10),
                          Text(
                            'No Account Found',
                            style: GoogleFonts.newsreader(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No account matches "${_inputController.text.trim()}". Please verify your email/phone or create a new account.',
                            style: GoogleFonts.atkinsonHyperlegible(fontSize: 13, color: Colors.red.shade800),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
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
