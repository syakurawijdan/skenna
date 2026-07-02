import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../data/api_client.dart';
import '../../data/user_session.dart';
import '../navigation/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class _ChatItem {
  const _ChatItem({
    required this.text,
    required this.isUser,
    this.showAvatar = false,
  });

  static const showContinueMarker = '[SHOW_CONTINUE]';
  static const educationCompleteMarker = '[EDUCATION_COMPLETE]';
  static const suggestStartMarker = '[SUGGEST_Q]';
  static const suggestEndMarker = '[/SUGGEST_Q]';

  final String text;
  final bool isUser;
  final bool showAvatar;

  bool get showContinue => !isUser && text.contains(showContinueMarker);

  List<String> get suggestions {
    if (isUser) return const [];
    if (!text.contains(suggestStartMarker) ||
        !text.contains(suggestEndMarker)) {
      return const [];
    }
    final match = RegExp(
      r'\[SUGGEST_Q\](.*?)\[/SUGGEST_Q\]',
      dotAll: true,
    ).firstMatch(text);
    if (match == null) return const [];

    return match
        .group(1)!
        .split('|')
        .map((question) => question.trim())
        .where((question) => question.isNotEmpty)
        .take(3)
        .toList(growable: false);
  }

  bool get hasSuggestions => suggestions.isNotEmpty;

  String get displayText => text
      .replaceAll(showContinueMarker, '')
      .replaceAll(educationCompleteMarker, '')
      .replaceAll(RegExp(r'\[SUGGEST_Q\].*?\[/SUGGEST_Q\]', dotAll: true), '')
      .trim();
}

class _ChatConversation {
  const _ChatConversation({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.answerPreview,
    required this.messages,
  });

  final String id;
  final String title;
  final DateTime updatedAt;
  final String answerPreview;
  final List<_ChatItem> messages;
}

class _ComparisonProduct {
  const _ComparisonProduct({
    required this.name,
    required this.sodiumMg,
    required this.subtitle,
  });

  final String name;
  final double sodiumMg;
  final String subtitle;
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({
    super.key,
    required this.apiClient,
    this.initialQuestion,
    this.productName,
    this.perPortionMg,
    this.kategori,
    this.scanId,
    this.sodiumLevel,
    this.packageMl,
    this.portionsInPackage,
    this.satuanTakaran,
    this.imagePath,
  });

  final ApiClient apiClient;
  final String? initialQuestion;
  final String? productName;
  final double? perPortionMg;
  final String? kategori;
  final int? scanId;
  final String? sodiumLevel;
  final double? packageMl;
  final int? portionsInPackage;
  final String? satuanTakaran;
  final String? imagePath;

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  static const _recapText = 'Beri rekap natrium saya hari ini';
  static const _compareText = 'Bandingkan produk';
  static const _educationText = 'Mulai edukasi';

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatItem> _messages = <_ChatItem>[];
  final List<_ChatConversation> _history = <_ChatConversation>[];

  bool _loading = false;
  bool _showTyping = false;
  bool _showWelcome = true;
  bool _historyVisible = false;
  bool _bannerDismissed = false;
  bool _savingScanConsumption = false;
  String _inputText = '';
  String _userName = 'User';
  int _userId = 0;
  int _educationPart = 0;

  bool get _isBumbuCategory {
    final kategori = widget.kategori?.toLowerCase().trim() ?? '';
    return kategori == 'saus_bumbu' ||
        kategori == 'bumbu' ||
        kategori.contains('saus') ||
        kategori.contains('bumbu');
  }

  @override
  void initState() {
    super.initState();
    _loadUserContext();
    final shortcut = widget.initialQuestion?.trim();
    if (shortcut != null && shortcut.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _sendQuestion(
          shortcut,
          educationPart: _isEducationStart(shortcut) ? 1 : null,
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserContext() async {
    final sessionUserId = UserSession().getUserId();
    if (!mounted) return;
    setState(() => _userId = sessionUserId);
    if (sessionUserId <= 0) return;

    await ApiClient.setCurrentUserId(sessionUserId);
    try {
      final profile = await widget.apiClient.getUserProfile(sessionUserId);
      final fullName = profile['full_name']?.toString().trim();
      if (mounted && fullName != null && fullName.isNotEmpty) {
        setState(() => _userName = fullName);
      }
    } catch (e) {
      debugPrint('Gagal memuat profil chatbot: $e');
    }
    await _loadRemoteHistory();
  }

  Future<void> _loadRemoteHistory() async {
    final userId = _userId > 0 ? _userId : UserSession().getUserId();
    if (userId <= 0) return;
    try {
      final grouped = await widget.apiClient.getChatHistory(userId);
      final conversations = <_ChatConversation>[];
      for (final group in grouped.whereType<Map>()) {
        final items = group['items'];
        if (items is! List) continue;
        for (final rawItem in items.whereType<Map>()) {
          final item = Map<String, dynamic>.from(rawItem);
          final sessionMessages = <_ChatItem>[];
          final rawMessages = item['messages'];
          if (rawMessages is List) {
            for (final rawMessage in rawMessages.whereType<Map>()) {
              final message = Map<String, dynamic>.from(rawMessage);
              final question = message['question']?.toString().trim() ?? '';
              final answer = message['answer']?.toString().trim() ?? '';
              if (question.isNotEmpty) {
                sessionMessages.add(_ChatItem(text: question, isUser: true));
              }
              if (answer.isNotEmpty) {
                sessionMessages.add(
                  _ChatItem(text: answer, isUser: false, showAvatar: true),
                );
              }
            }
          }
          final question =
              item['title']?.toString().trim() ??
              item['question']?.toString().trim() ??
              '';
          final answer = item['answer']?.toString().trim() ?? '';
          if (sessionMessages.isEmpty) {
            if (question.isNotEmpty)
              sessionMessages.add(_ChatItem(text: question, isUser: true));
            if (answer.isNotEmpty) {
              sessionMessages.add(
                _ChatItem(text: answer, isUser: false, showAvatar: true),
              );
            }
          }
          if (sessionMessages.isEmpty) continue;
          final createdAt =
              DateTime.tryParse(item['created_at']?.toString() ?? '') ??
              DateTime.now();
          conversations.add(
            _ChatConversation(
              id:
                  item['session_id']?.toString() ??
                  item['id']?.toString() ??
                  createdAt.microsecondsSinceEpoch.toString(),
              title: _preview(
                question.isNotEmpty
                    ? question
                    : sessionMessages.first.displayText,
                maxLength: 50,
              ),
              updatedAt: createdAt,
              answerPreview: _preview(
                item['answer_preview']?.toString() ?? answer,
                maxLength: 80,
              ),
              messages: sessionMessages,
            ),
          );
        }
      }
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (!mounted) return;
      setState(() {
        _history
          ..clear()
          ..addAll(conversations);
      });
    } catch (e) {
      debugPrint('Gagal memuat riwayat chat dari server: $e');
    }
  }

  String _preview(String value, {int maxLength = 54}) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= maxLength) return normalized;
    return '${normalized.substring(0, maxLength - 3)}...';
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _ask() async {
    final question = _controller.text.trim();
    await _sendQuestion(
      question,
      educationPart: _educationPartForQuestion(question),
    );
  }

  Future<void> _handleQuickAction(String text) async {
    if (_showWelcome) {
      setState(() => _showWelcome = false);
    }
    if (text == _compareText) {
      final selected = await _selectComparisonProducts();
      if (selected == null || selected.length < 2) return;
      final names = selected.map((item) => item.name).join(' dengan ');
      await _sendQuestion('Bandingkan produk $names');
      return;
    }
    await _sendQuestion(
      text,
      educationPart: _isEducationStart(text) ? 1 : null,
    );
  }

  Future<List<_ComparisonProduct>?> _selectComparisonProducts() async {
    final userId = _userId > 0 ? _userId : UserSession().getUserId();
    if (userId <= 0) {
      await _sendQuestion(_compareText);
      return null;
    }

    List<_ComparisonProduct> products = [];
    try {
      final history = await widget.apiClient.getScanHistory(userId);
      products = _productsFromHistory(history);
    } catch (e) {
      debugPrint('Gagal mengambil produk untuk perbandingan: $e');
    }

    if (!mounted) return null;
    if (products.length < 2) {
      _showSnack('Belum ada cukup produk di riwayat untuk dibandingkan.');
      return null;
    }

    final selected = <_ComparisonProduct>[];
    return showModalBottomSheet<List<_ComparisonProduct>>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Pilih produk yang ingin dibandingkan',
                            style: AppTextStyles.bold16.copyWith(
                              color: AppColors.blue600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: AppColors.blue600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: products.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: AppColors.neutral100),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final checked = selected.any(
                            (item) => item.name == product.name,
                          );
                          return CheckboxListTile(
                            value: checked,
                            activeColor: AppColors.blue300,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              product.name,
                              style: AppTextStyles.semiBold13.copyWith(
                                color: AppColors.blue700,
                              ),
                            ),
                            subtitle: Text(
                              product.subtitle,
                              style: AppTextStyles.regular10.copyWith(
                                color: AppColors.neutral300,
                              ),
                            ),
                            onChanged: (value) {
                              setSheetState(() {
                                if (value == true) {
                                  selected.add(product);
                                } else {
                                  selected.removeWhere(
                                    (item) => item.name == product.name,
                                  );
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selected.length >= 2
                              ? AppColors.blue300
                              : AppColors.blue200,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: selected.length >= 2
                            ? () => Navigator.pop(
                                context,
                                List<_ComparisonProduct>.from(selected),
                              )
                            : null,
                        child: Text(
                          'Bandingkan ${selected.length} produk',
                          style: AppTextStyles.bold13.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<_ComparisonProduct> _productsFromHistory(List<dynamic> history) {
    final byName = <String, _ComparisonProduct>{};
    for (final item in history.whereType<Map>()) {
      final map = Map<String, dynamic>.from(item);
      final name =
          (map['nama_produk'] ?? map['food_name'] ?? map['product_name'] ?? '')
              .toString()
              .trim();
      final sodium = double.tryParse(map['sodium_mg']?.toString() ?? '') ?? 0;
      if (name.isEmpty || sodium <= 0) continue;
      byName[name.toLowerCase()] = _ComparisonProduct(
        name: name,
        sodiumMg: sodium,
        subtitle: '${sodium.toStringAsFixed(0)} mg natrium',
      );
      final secondName = map['product_name2']?.toString().trim();
      final secondSodium =
          double.tryParse(map['sodium_mg2']?.toString() ?? '') ?? 0;
      if (secondName != null && secondName.isNotEmpty && secondSodium > 0) {
        byName[secondName.toLowerCase()] = _ComparisonProduct(
          name: secondName,
          sodiumMg: secondSodium,
          subtitle: '${secondSodium.toStringAsFixed(0)} mg natrium',
        );
      }
    }
    return byName.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.regular13.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.blue600,
      ),
    );
  }

  bool _isEducationStart(String text) {
    final normalized = text.toLowerCase().trim();
    return normalized.contains('mulai edukasi') ||
        normalized.contains('edukasi') ||
        normalized.contains('belajar');
  }

  int _nextEducationPart() {
    if (_educationPart < 1) return 2;
    if (_educationPart >= 3) return 3;
    return _educationPart + 1;
  }

  int? _educationPartForQuestion(String text) {
    final normalized = text.toLowerCase().trim();
    if (_isEducationStart(text)) return 1;
    if (normalized == 'lanjut' ||
        normalized == 'lanjutkan' ||
        normalized == 'next') {
      return _nextEducationPart();
    }
    return null;
  }

  void _updateEducationPartFromAnswer(String answer) {
    final match = RegExp(
      r'Edukasi\s+([123])\s*/\s*3',
      caseSensitive: false,
    ).firstMatch(answer);
    if (match == null) return;
    final parsed = int.tryParse(match.group(1) ?? '');
    if (parsed == null) return;
    _educationPart = parsed;
  }

  Future<void> _sendQuestion(String question, {int? educationPart}) async {
    if (question.isEmpty || _loading) return;

    setState(() {
      _showWelcome = false;
      _messages.add(_ChatItem(text: question, isUser: true));
      _loading = true;
      _showTyping = true;
      _controller.clear();
      _inputText = '';
    });
    _scrollToBottom();

    try {
      final userId = _userId > 0 ? _userId : UserSession().getUserId();
      if (userId <= 0) {
        setState(() {
          _messages.add(
            const _ChatItem(
              text:
                  'Sesi login belum ditemukan. Silakan masuk ulang agar Skenny bisa menjawab dengan data profilmu.',
              isUser: false,
              showAvatar: true,
            ),
          );
        });
        return;
      }

      await ApiClient.setCurrentUserId(userId);
      debugPrint('[DEBUG] chatbot sending user_id=$userId');
      final data = await widget.apiClient.askChatbot(
        userId: userId,
        question: question,
        educationPart: educationPart,
        productName: widget.productName,
        kategori: widget.kategori,
        sodiumPerPortionMg: widget.perPortionMg,
        scanId: widget.scanId,
      );
      final answer = data['answer']?.toString() ?? '-';
      final parts = answer.split('||FOLLOWUP||');
      final mainAnswer = parts[0].trim();
      final followUp = parts.length > 1 ? parts[1].trim() : null;
      if (!mounted) return;
      setState(() {
        _showTyping = false;
        _updateEducationPartFromAnswer(answer);
        _messages.add(
          _ChatItem(text: mainAnswer, isUser: false, showAvatar: true),
        );
      });
      if (followUp != null && followUp.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          setState(() {
            _messages.add(
              _ChatItem(text: followUp, isUser: false, showAvatar: false),
            );
          });
        }
      }
      await _loadRemoteHistory();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _showTyping = false;
        _messages.add(
          const _ChatItem(
            text:
                'Maaf, Skenny belum bisa menjawab sekarang. Coba kirim ulang beberapa saat lagi.',
            isUser: false,
            showAvatar: true,
          ),
        );
      });
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _showTyping = false;
        });
      }
    }
  }

  Future<void> _recordScanConsumption() async {
    if (_isBumbuCategory) return;
    if (_savingScanConsumption) return;

    final productName = widget.productName?.trim();
    if (productName == null || productName.isEmpty) return;

    setState(() => _savingScanConsumption = true);
    try {
      final userId = UserSession().getUserId();
      if (userId <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi login belum ditemukan. Silakan masuk ulang.'),
          ),
        );
        return;
      }

      await widget.apiClient.postScanHistory(
        userId: userId,
        sodiumMg: (widget.perPortionMg ?? 0).round(),
        servings: 1,
        productName: productName,
        sodiumLevel: widget.sodiumLevel,
        kategori: widget.kategori,
        packageMl: (widget.packageMl ?? 0).round(),
        portionsInPackage: widget.portionsInPackage ?? 1,
        satuanTakaran: widget.satuanTakaran ?? 'g',
        isConsumed: true,
        imagePath: widget.imagePath,
        scanId: widget.scanId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konsumsi berhasil dicatat!')),
      );
      Navigator.pushNamed(context, AppRoutes.history);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mencatat konsumsi: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingScanConsumption = false);
    }
  }

  void _skipScanConsumption() {
    setState(() => _bannerDismissed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Oke, konsumsi tidak dicatat.')),
    );
  }

  void _loadConversation(_ChatConversation conversation) {
    setState(() {
      _messages
        ..clear()
        ..addAll(conversation.messages);
      _showWelcome = false;
      _historyVisible = false;
    });
    _scrollToBottom(jump: true);
  }

  Future<void> _openHistorySidebar() async {
    await _loadRemoteHistory();
    if (mounted) {
      setState(() => _historyVisible = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _ChatHeader(onOpenHistory: _openHistorySidebar),
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        transitionBuilder: (child, animation) {
                          final offset = Tween<Offset>(
                            begin: const Offset(0, -0.08),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offset,
                              child: child,
                            ),
                          );
                        },
                        child: _showWelcome
                            ? _WelcomeSection(
                                key: const ValueKey('welcome'),
                                userName: _userName,
                                onAction: _handleQuickAction,
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('hidden-welcome'),
                              ),
                      ),
                      if (_showWelcome) const SizedBox(height: 18),
                      for (var i = 0; i < _messages.length; i++) ...[
                        _AnimatedChatBubble(
                          key: ValueKey(
                            'message-$i-${_messages[i].text.hashCode}',
                          ),
                          item: _messages[i],
                          onContinue: () => _sendQuestion(
                            'lanjut',
                            educationPart: _nextEducationPart(),
                          ),
                          onSuggestion: (question) => _sendQuestion(
                            question,
                            educationPart: _educationPartForQuestion(question),
                          ),
                        ),
                        if (i != _messages.length - 1)
                          SizedBox(
                            height:
                                _messages[i].isUser == _messages[i + 1].isUser
                                ? 8
                                : 14,
                          )
                        else if (_loading)
                          const SizedBox(height: 14),
                      ],
                      if (_showTyping) const _TypingBubble(),
                    ],
                  ),
                ),
                if (widget.productName != null &&
                    !_isBumbuCategory &&
                    !_bannerDismissed)
                  _ScanConsumptionBanner(
                    productName: widget.productName!,
                    saving: _savingScanConsumption,
                    onConfirm: _recordScanConsumption,
                    onReject: _skipScanConsumption,
                  ),
                _BottomQuickActions(onAction: _handleQuickAction),
                _ChatComposer(
                  controller: _controller,
                  loading: _loading,
                  inputText: _inputText,
                  onChanged: (value) => setState(() => _inputText = value),
                  onSend: _ask,
                  onSubmitted: _ask,
                ),
              ],
            ),
          ),
          if (_historyVisible)
            _ChatHistorySidebar(
              conversations: _history,
              onClose: () => setState(() => _historyVisible = false),
              onSelected: _loadConversation,
            ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.onOpenHistory});

  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SizedBox(
        height: 52,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _CircleIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
            Text(
              'Chat Skenny',
              textAlign: TextAlign.center,
              style: AppTextStyles.bold20.copyWith(
                color: AppColors.blue300,
                fontSize: 22,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _CircleIconButton(
                icon: Icons.history_rounded,
                onTap: onOpenHistory,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blue100,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: AppColors.blue300, size: 20),
        ),
      ),
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection({
    super.key,
    required this.userName,
    required this.onAction,
  });

  final String userName;
  final ValueChanged<String> onAction;
  static const _welcomeQuestions = [
    'Bagaimana cara mencegah hipertensi?',
    'Berikan saya resep masakan rendah natrium',
    'Apa saja gejala tekanan darah tinggi?',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Halo $userName,\nAku Skenny 👋',
          textAlign: TextAlign.center,
          style: AppTextStyles.bold25.copyWith(color: AppColors.blue500),
        ),
        const SizedBox(height: 6),
        Text(
          'Virtual Assistant Kamu',
          style: AppTextStyles.regular13.copyWith(color: AppColors.blue300),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SkennyAvatar(size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.blue100),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Silakan tanya aku soal natrium, hipertensi, atau gizi. Kamu juga bisa mulai dari sini:',
                      style: AppTextStyles.regular13.copyWith(
                        color: AppColors.blue800,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Column(
                      children: [
                        _WelcomeActionButton(
                          label: _welcomeQuestions[0],
                          onTap: () => onAction(_welcomeQuestions[0]),
                        ),
                        const SizedBox(height: 8),
                        _WelcomeActionButton(
                          label: _welcomeQuestions[1],
                          onTap: () => onAction(_welcomeQuestions[1]),
                        ),
                        const SizedBox(height: 8),
                        _WelcomeActionButton(
                          label: _welcomeQuestions[2],
                          onTap: () => onAction(_welcomeQuestions[2]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WelcomeActionButton extends StatelessWidget {
  const _WelcomeActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blue100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 9, 9),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.semiBold13.copyWith(
                    color: AppColors.blue300,
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.blue300,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedChatBubble extends StatefulWidget {
  const _AnimatedChatBubble({
    super.key,
    required this.item,
    required this.onContinue,
    required this.onSuggestion,
  });

  final _ChatItem item;
  final VoidCallback onContinue;
  final ValueChanged<String> onSuggestion;

  @override
  State<_AnimatedChatBubble> createState() => _AnimatedChatBubbleState();
}

class _AnimatedChatBubbleState extends State<_AnimatedChatBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _ChatBubble(
          item: widget.item,
          onContinue: widget.onContinue,
          onSuggestion: widget.onSuggestion,
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.item,
    required this.onContinue,
    required this.onSuggestion,
  });

  final _ChatItem item;
  final VoidCallback onContinue;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    if (item.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.75,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.blue300,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue300.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              child: Text(
                item.displayText,
                style: AppTextStyles.regular13.copyWith(
                  color: AppColors.white,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (item.showAvatar)
          const _SkennyAvatar(size: 32)
        else
          const SizedBox(width: 32),
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.80,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(18),
                      ),
                      border: Border.all(color: AppColors.blue100),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.07),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _SkennyResponseContent(
                      text: item.displayText,
                      baseColor: AppColors.blue900,
                      strongColor: AppColors.blue300,
                    ),
                  ),
                  if (item.showContinue) ...[
                    const SizedBox(height: 8),
                    _ContinueButton(onTap: onContinue),
                  ],
                  if (item.hasSuggestions) ...[
                    const SizedBox(height: 8),
                    _SuggestedQuestionButtons(
                      questions: item.suggestions,
                      onSelected: onSuggestion,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.blue200),
          ),
          child: Text(
            'Lanjut ➜',
            style: AppTextStyles.semiBold10.copyWith(color: AppColors.blue300),
          ),
        ),
      ),
    );
  }
}

class _SkennyResponseContent extends StatelessWidget {
  const _SkennyResponseContent({
    required this.text,
    required this.baseColor,
    required this.strongColor,
  });

  final String text;
  final Color baseColor;
  final Color strongColor;

  @override
  Widget build(BuildContext context) {
    final comparison = _ParsedComparisonResponse.tryParse(text);
    if (comparison == null) {
      return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: _MarkdownText(
          text: text,
          baseColor: baseColor,
          strongColor: strongColor,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perbandingan Produk:',
          style: AppTextStyles.bold13.copyWith(
            color: AppColors.blue800,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        _ComparisonDataTable(rows: comparison.rows),
        if (comparison.remainingMarkdown.isNotEmpty) ...[
          const SizedBox(height: 12),
          _MarkdownText(
            text: comparison.remainingMarkdown,
            baseColor: baseColor,
            strongColor: strongColor,
          ),
        ],
      ],
    );
  }
}

class _MarkdownText extends StatelessWidget {
  const _MarkdownText({
    required this.text,
    required this.baseColor,
    required this.strongColor,
  });

  final String text;
  final Color baseColor;
  final Color strongColor;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: text,
      styleSheet: MarkdownStyleSheet(
        p: AppTextStyles.regular13.copyWith(color: baseColor, height: 1.38),
        strong: AppTextStyles.regular13.copyWith(
          color: strongColor,
          fontWeight: FontWeight.bold,
          height: 1.38,
        ),
        listBullet: AppTextStyles.regular13.copyWith(
          color: baseColor,
          height: 1.38,
        ),
      ),
    );
  }
}

class _ComparisonDataTable extends StatelessWidget {
  const _ComparisonDataTable({required this.rows});

  final List<_ComparisonTableRow> rows;

  @override
  Widget build(BuildContext context) {
    final headerStyle = AppTextStyles.bold13.copyWith(
      color: AppColors.blue800,
      fontSize: 12,
      height: 1.2,
    );
    final cellStyle = AppTextStyles.regular13.copyWith(
      color: AppColors.blue900,
      fontSize: 12,
      height: 1.2,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(AppColors.blue100),
              headingTextStyle: headerStyle,
              dataTextStyle: cellStyle,
              columnSpacing: 18,
              horizontalMargin: 12,
              headingRowHeight: 38,
              dataRowMinHeight: 38,
              dataRowMaxHeight: 38,
              border: TableBorder.all(color: AppColors.blue100),
              columns: const [
                DataColumn(label: _NoWrapCell('Produk', isHeader: true)),
                DataColumn(label: _NoWrapCell('Natrium', isHeader: true)),
                DataColumn(
                  label: _NoWrapCell('% Batas Harian', isHeader: true),
                ),
                DataColumn(
                  label: _NoWrapCell('Sajian/Kemasan', isHeader: true),
                ),
              ],
              rows: [
                for (var index = 0; index < rows.length; index++)
                  DataRow(
                    color: MaterialStateProperty.all(
                      index.isEven ? AppColors.white : AppColors.blue50,
                    ),
                    cells: [
                      DataCell(_NoWrapCell(rows[index].product)),
                      DataCell(_NoWrapCell(rows[index].sodium)),
                      DataCell(_NoWrapCell(rows[index].percent)),
                      DataCell(_NoWrapCell(rows[index].servings)),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NoWrapCell extends StatelessWidget {
  const _NoWrapCell(this.text, {this.isHeader = false});

  final String text;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      softWrap: false,
      overflow: TextOverflow.visible,
      style: (isHeader ? AppTextStyles.bold13 : AppTextStyles.regular13)
          .copyWith(
            color: isHeader ? AppColors.blue800 : AppColors.blue900,
            fontSize: 12,
            height: 1.2,
          ),
    );
  }
}

class _ParsedComparisonResponse {
  const _ParsedComparisonResponse({
    required this.rows,
    required this.remainingMarkdown,
  });

  final List<_ComparisonTableRow> rows;
  final String remainingMarkdown;

  static _ParsedComparisonResponse? tryParse(String text) {
    if (!text.contains('Perbandingan Produk:')) return null;
    final lines = text.split('\n');
    final tableStart = lines.indexWhere(
      (line) =>
          line.trim().startsWith('| Produk |') &&
          line.contains('Sajian/Kemasan'),
    );
    if (tableStart < 0 || tableStart + 2 >= lines.length) return null;

    var tableEnd = tableStart;
    while (tableEnd < lines.length && lines[tableEnd].trim().startsWith('|')) {
      tableEnd++;
    }

    final rows = <_ComparisonTableRow>[];
    for (final line in lines.sublist(tableStart + 2, tableEnd)) {
      final cells = _splitMarkdownTableRow(line);
      if (cells.length < 4) continue;
      rows.add(
        _ComparisonTableRow(
          product: _stripMarkdown(cells[0]),
          sodium: _stripMarkdown(cells[1]),
          percent: _stripMarkdown(cells[2]),
          servings: _stripMarkdown(cells[3]),
        ),
      );
    }
    if (rows.isEmpty) return null;

    final remaining = [
      ...lines
          .sublist(0, tableStart)
          .where((line) => line.trim() != 'Perbandingan Produk:'),
      ...lines.sublist(tableEnd),
    ].join('\n').trim();

    return _ParsedComparisonResponse(rows: rows, remainingMarkdown: remaining);
  }

  static List<String> _splitMarkdownTableRow(String line) {
    final trimmed = line.trim();
    final withoutLeft = trimmed.startsWith('|')
        ? trimmed.substring(1)
        : trimmed;
    final withoutEdges = withoutLeft.endsWith('|')
        ? withoutLeft.substring(0, withoutLeft.length - 1)
        : withoutLeft;
    return withoutEdges.split('|').map((cell) => cell.trim()).toList();
  }

  static String _stripMarkdown(String value) {
    return value
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll('`', '')
        .trim();
  }
}

class _ComparisonTableRow {
  const _ComparisonTableRow({
    required this.product,
    required this.sodium,
    required this.percent,
    required this.servings,
  });

  final String product;
  final String sodium;
  final String percent;
  final String servings;
}

class _SuggestedQuestionButtons extends StatelessWidget {
  const _SuggestedQuestionButtons({
    required this.questions,
    required this.onSelected,
  });

  final List<String> questions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: questions
          .map(
            (question) => _SuggestedQuestionButton(
              question: question,
              onTap: () => onSelected(question),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _SuggestedQuestionButton extends StatelessWidget {
  const _SuggestedQuestionButton({required this.question, required this.onTap});

  final String question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.blue200),
          ),
          child: Text(
            question,
            style: AppTextStyles.semiBold10.copyWith(color: AppColors.blue300),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const _SkennyAvatar(size: 32),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: AppColors.blue100),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _BouncingDot(delay: 0),
              SizedBox(width: 5),
              _BouncingDot(delay: 120),
              SizedBox(width: 5),
              _BouncingDot(delay: 240),
            ],
          ),
        ),
      ],
    );
  }
}

class _BouncingDot extends StatefulWidget {
  const _BouncingDot({required this.delay});

  final int delay;

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _opacity = Tween<double>(
      begin: 0.25,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    Future<void>.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Opacity(opacity: _opacity.value, child: child);
      },
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.blue300,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _BottomQuickActions extends StatelessWidget {
  const _BottomQuickActions({required this.onAction});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 10),
      child: Row(
        children: [
          _QuickChip(
            label: _ChatbotScreenState._recapText,
            onTap: () => onAction(_ChatbotScreenState._recapText),
          ),
          const SizedBox(width: 8),
          _QuickChip(
            label: _ChatbotScreenState._compareText,
            onTap: () => onAction(_ChatbotScreenState._compareText),
          ),
          const SizedBox(width: 8),
          _QuickChip(
            label: _ChatbotScreenState._educationText,
            onTap: () => onAction(_ChatbotScreenState._educationText),
          ),
        ],
      ),
    );
  }
}

class _ScanConsumptionBanner extends StatelessWidget {
  const _ScanConsumptionBanner({
    required this.productName,
    required this.saving,
    required this.onConfirm,
    required this.onReject,
  });

  final String productName;
  final bool saving;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.blue200),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jadi dikonsumsi produk ini?',
              style: AppTextStyles.bold13.copyWith(color: AppColors.blue600),
            ),
            const SizedBox(height: 4),
            Text(
              productName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.regular13.copyWith(
                color: AppColors.blue800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue300,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: saving ? null : onConfirm,
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              'Ya, Catat',
                              style: AppTextStyles.semiBold13.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.blue300,
                        side: const BorderSide(color: AppColors.blue300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: saving ? null : onReject,
                      child: Text(
                        'Tidak',
                        style: AppTextStyles.semiBold13.copyWith(
                          color: AppColors.blue300,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.blue200),
          ),
          child: Text(
            label,
            style: AppTextStyles.semiBold10.copyWith(color: AppColors.blue300),
          ),
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.loading,
    required this.inputText,
    required this.onChanged,
    required this.onSend,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool loading;
  final String inputText;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final canSend = inputText.trim().isNotEmpty && !loading;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                enabled: !loading,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onChanged: onChanged,
                onSubmitted: (_) {
                  if (canSend) onSubmitted();
                },
                style: AppTextStyles.regular13.copyWith(
                  color: AppColors.blue800,
                ),
                decoration: InputDecoration(
                  hintText: 'Tulis pertanyaan kamu...',
                  hintStyle: AppTextStyles.regular13.copyWith(
                    color: AppColors.neutral300,
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(color: AppColors.blue300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(
                      color: AppColors.blue300,
                      width: 1.4,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(color: AppColors.blue100),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: canSend ? AppColors.blue300 : AppColors.blue100,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: canSend ? onSend : null,
              child: SizedBox(
                width: 40,
                height: 40,
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(15),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: AppColors.blue300,
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: canSend ? AppColors.white : AppColors.blue300,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatHistorySidebar extends StatelessWidget {
  const _ChatHistorySidebar({
    required this.conversations,
    required this.onClose,
    required this.onSelected,
  });

  final List<_ChatConversation> conversations;
  final VoidCallback onClose;
  final ValueChanged<_ChatConversation> onSelected;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width * 0.82;
    final height = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: ColoredBox(color: AppColors.black.withValues(alpha: 0.18)),
          ),
        ),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: width, end: 0),
          builder: (context, value, child) {
            return Positioned(
              top: 0,
              bottom: 0,
              right: -value,
              width: width,
              child: child!,
            );
          },
          child: Material(
            color: AppColors.white,
            elevation: 12,
            child: SizedBox(
              height: height,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Riwayat Chat',
                              style: AppTextStyles.bold20.copyWith(
                                color: AppColors.blue600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: onClose,
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.blue600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: conversations.isEmpty
                            ? Center(
                                child: Text(
                                  'Belum ada riwayat chat.',
                                  style: AppTextStyles.regular13.copyWith(
                                    color: AppColors.neutral300,
                                  ),
                                ),
                              )
                            : ListView(
                                children: [
                                  for (final group
                                      in _groupedConversations().entries) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 12,
                                        bottom: 8,
                                      ),
                                      child: Text(
                                        group.key,
                                        style: AppTextStyles.bold13.copyWith(
                                          color: AppColors.blue300,
                                        ),
                                      ),
                                    ),
                                    for (final item in group.value)
                                      _HistoryTile(
                                        conversation: item,
                                        onTap: () => onSelected(item),
                                      ),
                                  ],
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Map<String, List<_ChatConversation>> _groupedConversations() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final groups = <String, List<_ChatConversation>>{
      'Hari ini': [],
      'Kemarin': [],
    };
    for (final item in conversations) {
      final date = DateTime(
        item.updatedAt.year,
        item.updatedAt.month,
        item.updatedAt.day,
      );
      if (date == today) {
        groups['Hari ini']!.add(item);
      } else if (date == yesterday) {
        groups['Kemarin']!.add(item);
      } else {
        final daysAgo = today.difference(date).inDays;
        groups
            .putIfAbsent('$daysAgo hari lalu', () => <_ChatConversation>[])
            .add(item);
      }
    }
    groups.removeWhere((_, value) => value.isEmpty);
    return groups;
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.conversation, required this.onTap});

  final _ChatConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final localTime = conversation.updatedAt.toUtc().add(
      const Duration(hours: 7),
    );
    final time =
        '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
    final question = conversation.messages
        .where((item) => item.isUser)
        .map((item) => item.displayText)
        .firstWhere(
          (text) => text.isNotEmpty,
          orElse: () => conversation.title,
        );
    final answer = conversation.answerPreview;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.blue50,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.blue100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        time,
                        style: AppTextStyles.regular10.copyWith(
                          color: const Color(0xFF2C4A8A),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.blue300,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  question.length > 50
                      ? '${question.substring(0, 47)}...'
                      : question,
                  style: AppTextStyles.semiBold13.copyWith(
                    color: const Color(0xFF2C4A8A),
                  ),
                ),
                if (answer.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _SkennyResponseContent(
                    text: answer,
                    baseColor: AppColors.neutral300,
                    strongColor: const Color(0xFF2C4A8A),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkennyAvatar extends StatelessWidget {
  const _SkennyAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/illustrations/chatbot_2.png',
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppColors.blue100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.smart_toy_outlined,
            color: AppColors.blue300,
            size: size * 0.62,
          ),
        ),
      ),
    );
  }
}
