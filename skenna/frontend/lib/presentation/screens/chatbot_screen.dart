import 'package:flutter/material.dart';

import '../../data/api_client.dart';

class _ChatItem {
  const _ChatItem({
    required this.text,
    required this.isUser,
    this.showAvatar = false,
  });

  final String text;
  final bool isUser;
  final bool showAvatar;
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({
    super.key,
    required this.apiClient,
    this.initialQuestion,
  });

  final ApiClient apiClient;
  final String? initialQuestion;

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatItem> _messages = <_ChatItem>[
    const _ChatItem(
      text:
          "Hello, I'm Skenny! I'm your personal sport assistant. How can I help you?",
      isUser: false,
    ),
  ];

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _scrollToBottom(jump: true);
    final shortcut = widget.initialQuestion?.trim();
    if (shortcut != null && shortcut.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _sendQuestion(shortcut);
      });
    }
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
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final question = _controller.text.trim();
    await _sendQuestion(question);
  }

  Future<void> _sendQuestion(String question) async {
    if (question.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(_ChatItem(text: question, isUser: true));
      _loading = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final data = await widget.apiClient.askChatbot(
        userId: 1,
        question: question,
      );
      final answer = data['answer']?.toString() ?? '-';
      setState(() {
        _messages.add(_ChatItem(text: answer, isUser: false, showAvatar: true));
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(
          _ChatItem(text: 'Error: $e', isUser: false, showAvatar: true),
        );
      });
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF5F5F7);
    const darkBlue = Color(0xFF213868);
    const normalBlue = Color(0xFF2C4A8A);
    const lightBlue = Color(0xFFDFE4ED);
    const activeBlue = Color(0xFFBEC7DB);
    const botBubble = Color(0xFFF2F4F5);

    return Container(
      color: bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: const BoxDecoration(
                      color: lightBlue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: darkBlue,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      'https://www.figma.com/api/mcp/asset/d0d9cd99-2152-4e19-b42d-7b9de991c9f4',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: activeBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.smart_toy, color: darkBlue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'skenny',
                    style: TextStyle(
                      color: darkBlue,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Wed 8:21 AM',
                style: TextStyle(
                  color: activeBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 12),
              const _HelloHero(),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 120),
                  itemCount: _messages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final item = _messages[i];
                    if (item.isUser) {
                      return Align(
                        alignment: Alignment.centerRight,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 282),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: const BoxDecoration(
                              color: normalBlue,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                                bottomLeft: Radius.circular(24),
                              ),
                            ),
                            child: Text(
                              item.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.22,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.showAvatar)
                          Container(
                            width: 43,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: activeBlue,
                              borderRadius: BorderRadius.all(
                                Radius.circular(25.5),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  'https://www.figma.com/api/mcp/asset/d0d9cd99-2152-4e19-b42d-7b9de991c9f4',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.smart_toy,
                                    color: darkBlue,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 43),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 266),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: const BoxDecoration(
                              color: botBubble,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(24),
                                bottomRight: Radius.circular(24),
                                bottomLeft: Radius.circular(24),
                              ),
                            ),
                            child: Text(
                              item.text,
                              style: const TextStyle(
                                color: Color(0xFF303437),
                                fontSize: 13,
                                height: 1.22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 45,
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(fontSize: 13, color: darkBlue),
                        decoration: InputDecoration(
                          hintText: 'Tulis pertanyaan kamu...',
                          hintStyle: const TextStyle(
                            color: activeBlue,
                            fontSize: 13,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 13,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: const BorderSide(color: normalBlue),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: const BorderSide(
                              color: normalBlue,
                              width: 1.2,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _loading ? null : _ask(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _loading ? null : _ask,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: lightBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _loading ? Icons.hourglass_top : Icons.send,
                        color: darkBlue,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelloHero extends StatelessWidget {
  const _HelloHero();

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF213868);
    const activeBlue = Color(0xFFBEC7DB);
    const normalBlue = Color(0xFF2C4A8A);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 43,
          height: 44,
          decoration: const BoxDecoration(
            color: activeBlue,
            borderRadius: BorderRadius.all(Radius.circular(25.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                'https://www.figma.com/api/mcp/asset/d0d9cd99-2152-4e19-b42d-7b9de991c9f4',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.smart_toy, color: darkBlue),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 210,
          height: 120,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                bottom: 0,
                child: Image.network(
                  'https://www.figma.com/api/mcp/asset/d0d9cd99-2152-4e19-b42d-7b9de991c9f4',
                  width: 123,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 123,
                    height: 120,
                    decoration: BoxDecoration(
                      color: activeBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: darkBlue,
                      size: 40,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 126,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 9,
                  ),
                  decoration: const BoxDecoration(
                    color: normalBlue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(21),
                      topRight: Radius.circular(21),
                      bottomRight: Radius.circular(21),
                    ),
                  ),
                  child: const Text(
                    'Hai!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
