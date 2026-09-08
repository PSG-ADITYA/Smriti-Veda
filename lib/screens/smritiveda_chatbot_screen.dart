import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../locales/app_localizations.dart';
import '../providers/app_state.dart';
import '../services/ai_provider.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class SmritiVedaChatbotScreen extends StatefulWidget {
  const SmritiVedaChatbotScreen({super.key});

  @override
  State<SmritiVedaChatbotScreen> createState() => _SmritiVedaChatbotScreenState();
}

class _SmritiVedaChatbotScreenState extends State<SmritiVedaChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // STT Voice Input
  stt.SpeechToText? _speech;
  bool _isSpeechInitialized = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initStt();
    // Seed friendly initial welcome message
    _messages.add(
      ChatMessage(
        text: 'Namaste! I am your SmritiVeda AI Assistant. How can I help your daily practice, memory games, or health records today?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _initStt() async {
    _speech = stt.SpeechToText();
    try {
      _isSpeechInitialized = await _speech!.initialize(
        onError: (err) {
          if (mounted) setState(() => _isRecording = false);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted && _isRecording) {
              setState(() => _isRecording = false);
              _handleSend();
            }
          }
        },
      );
    } catch (_) {
      _isSpeechInitialized = false;
    }
  }

  @override
  void dispose() {
    _speech?.stop();
    SoundService.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startVoiceInput() async {
    SoundService.playTap();
    if (_speech == null || !_isSpeechInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone voice input is not available on this device.')),
      );
      return;
    }

    final appState = AppStateScope.maybeOf(context);
    final langCode = appState?.selectedLanguage ?? 'en';
    String targetLocale = 'en_IN';
    if (langCode == 'te') {
      targetLocale = 'te_IN';
    } else if (langCode == 'hi' || langCode == 'sa') {
      targetLocale = 'hi_IN';
    }

    setState(() => _isRecording = true);
    try {
      await _speech!.listen(
        localeId: targetLocale,
        onResult: (result) {
          if (mounted) {
            setState(() {
              _textController.text = result.recognizedWords;
            });
          }
        },
      );
    } catch (_) {
      setState(() => _isRecording = false);
    }
  }

  void _stopVoiceInput() {
    _speech?.stop();
    setState(() => _isRecording = false);
    _handleSend();
  }

  void _handleSend([String? presetText]) async {
    final query = presetText ?? _textController.text.trim();
    if (query.isEmpty) return;

    SoundService.playTap();
    _textController.clear();

    setState(() {
      _messages.add(
        ChatMessage(text: query, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });
    _scrollToBottom();

    final appState = AppStateScope.maybeOf(context);
    final langCode = appState?.selectedLanguage ?? 'en';

    try {
      final reply = await AIRouter().getAssistantResponse(
        prompt: query,
        languageCode: langCode,
      );

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(text: reply, isUser: false, timestamp: DateTime.now()),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'I am here with you. Please practice your verses and games at your own calm pace.',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _speakMessage(String text) {
    SoundService.playTap();
    final appState = AppStateScope.maybeOf(context);
    final langCode = appState?.selectedLanguage ?? 'en';
    SoundService.speak(text, languageCode: langCode);
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.maybeOf(context);
    final fontScale = appState?.fontScale ?? 1.0;

    return Scaffold(
      backgroundColor: AppColors.canvasIvory,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.terracottaSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.psychology_rounded, color: AppColors.terracottaPrimary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.tr('chatbot_title'),
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.newsreader(
                  fontWeight: FontWeight.bold,
                  fontSize: 19 * fontScale,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.charcoalText,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_off_rounded),
            tooltip: 'Stop Reading Voice',
            onPressed: () => SoundService.stop(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildPresetChips(fontScale),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: _messages.length,
                itemBuilder: (context, idx) {
                  final msg = _messages[idx];
                  return _buildMessageBubble(msg, fontScale);
                },
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.terracottaPrimary),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Thinking peacefully...',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 13 * fontScale,
                        color: AppColors.secondaryText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            _buildInputBar(fontScale),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChips(double fontScale) {
    final presets = [
      context.tr('chatbot_preset_1'),
      context.tr('chatbot_preset_2'),
      context.tr('chatbot_preset_3'),
      context.tr('chatbot_preset_4'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.sandalwoodGold.withValues(alpha: 0.2)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: presets.map((text) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                backgroundColor: AppColors.canvasIvory,
                side: BorderSide(color: AppColors.sandalwoodGold.withValues(alpha: 0.3)),
                label: Text(
                  text,
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 12 * fontScale,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoalText,
                  ),
                ),
                onPressed: () => _handleSend(text),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, double fontScale) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.terracottaPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.sageSecondary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
                border: isUser ? null : Border.all(color: AppColors.sandalwoodGold.withValues(alpha: 0.3)),
                boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 15 * fontScale,
                      color: isUser ? Colors.white : AppColors.charcoalText,
                      height: 1.4,
                    ),
                  ),
                  if (!isUser) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _speakMessage(msg.text),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.volume_up_rounded, color: AppColors.terracottaPrimary, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Listen',
                                  style: GoogleFonts.atkinsonHyperlegible(
                                    fontSize: 12 * fontScale,
                                    color: AppColors.terracottaPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.terracottaSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, color: AppColors.terracottaPrimary, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar(double fontScale) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.sandalwoodGold.withValues(alpha: 0.25)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: _isRecording ? Colors.red : AppColors.terracottaPrimary,
              size: 26,
            ),
            tooltip: _isRecording ? 'Stop Recording' : 'Speak Question',
            onPressed: _isRecording ? _stopVoiceInput : _startVoiceInput,
          ),
          Expanded(
            child: TextField(
              key: const Key('chatbot_input_field'),
              controller: _textController,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: _isRecording ? 'Listening to your voice...' : context.tr('chatbot_hint'),
                hintStyle: GoogleFonts.atkinsonHyperlegible(fontSize: 14 * fontScale, color: AppColors.secondaryText),
                filled: true,
                fillColor: AppColors.canvasIvory,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.sandalwoodGold.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.sandalwoodGold.withValues(alpha: 0.3)),
                ),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.terracottaPrimary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              key: const Key('chatbot_send_button'),
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              tooltip: 'Send Question',
              onPressed: () => _handleSend(),
            ),
          ),
        ],
      ),
    );
  }
}
