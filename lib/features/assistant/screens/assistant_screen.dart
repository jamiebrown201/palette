import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette/core/theme/palette_colours.dart';
import 'package:palette/core/theme/palette_typography.dart';
import 'package:palette/features/assistant/logic/assistant_engine.dart';
import 'package:palette/features/assistant/providers/assistant_providers.dart';
import 'package:palette/features/assistant/widgets/chat_bubble.dart';
import 'package:palette/providers/analytics_provider.dart';

/// AI Design Assistant — a conversational interface powered by the
/// Design Rules Engine. Users ask design questions and receive personalised
/// advice grounded in their Colour DNA, room data, and Red Thread.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({this.initialPrompt, super.key});

  /// Optional prompt to auto-send when the screen opens (e.g. from a room CTA).
  final String? initialPrompt;

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _hasShownStarters = false;

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).screenView('assistant');
    // Listen for context becoming available to show welcome message.
    // Using addPostFrameCallback to avoid modifying providers during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(
        assistantContextProvider, // provider
        (_, next) {
          next.whenData((_) => _showWelcomeMessage());
        },
        fireImmediately: true,
      );
    });
  }

  void _showWelcomeMessage() {
    if (_hasShownStarters) return;
    final messages = ref.read(assistantMessagesProvider);
    if (messages.isNotEmpty) return;

    final ctxAsync = ref.read(assistantContextProvider);
    ctxAsync.whenData((ctx) {
      if (_hasShownStarters) return;
      _hasShownStarters = true;
      final engine = AssistantEngine(ctx);
      final starters = engine.starterSuggestions();

      ref
          .read(assistantMessagesProvider.notifier)
          .addMessage(
            AssistantMessage(
              text:
                  "I'm your pocket interior designer. I know your "
                  'rooms, your palette, and your style. Ask me anything '
                  'about your home.',
              isUser: false,
              suggestedFollowUps: starters,
            ),
          );

      if (widget.initialPrompt != null) {
        Future.microtask(() => _send(widget.initialPrompt!));
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _controller.clear();
    _focusNode.requestFocus();

    ref.read(analyticsProvider).track('assistant_message_sent', {
      'message_length': trimmed.length,
    });

    // Add user message
    final notifier = ref.read(assistantMessagesProvider.notifier);
    notifier.addMessage(AssistantMessage(text: trimmed, isUser: true));

    // Generate response from context
    final ctxAsync = ref.read(assistantContextProvider);
    ctxAsync.whenData((ctx) {
      final engine = AssistantEngine(ctx);
      final response = engine.respond(trimmed);
      notifier.addMessage(response);

      ref.read(analyticsProvider).track('assistant_response_generated', {
        'has_swatches': response.colourSwatches.isNotEmpty,
        'has_room': response.roomId != null,
        'follow_up_count': response.suggestedFollowUps.length,
      });
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(assistantMessagesProvider);
    final ctxAsync = ref.watch(assistantContextProvider);

    // Welcome message is now shown via initState + addPostFrameCallback
    // to avoid modifying provider state during build.

    return Scaffold(
      backgroundColor: PaletteColours.warmWhite,
      appBar: AppBar(
        backgroundColor: PaletteColours.warmWhite,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: PaletteColours.sageGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: PaletteColours.textOnAccent,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Design Assistant', style: PaletteTypography.titleMedium),
                Text(
                  'Your pocket interior designer',
                  style: PaletteTypography.labelSmall,
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Start new conversation',
              onPressed: () {
                ref.read(assistantMessagesProvider.notifier).clear();
                _hasShownStarters = false;
                ref
                    .read(analyticsProvider)
                    .track('assistant_conversation_reset');
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ctxAsync.when(
              data: (_) => _buildMessageList(messages),
              loading:
                  () => const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: PaletteColours.sageGreen,
                          strokeWidth: 2,
                        ),
                        SizedBox(height: 16),
                        Text('Loading your home data...'),
                      ],
                    ),
                  ),
              error:
                  (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Something went wrong loading your data. '
                        'Try going back and opening the assistant again.',
                        style: PaletteTypography.bodyMedium.copyWith(
                          color: PaletteColours.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
            ),
          ),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<AssistantMessage> messages) {
    if (messages.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return ChatBubble(message: messages[index], onFollowUpTapped: _send);
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: const BoxDecoration(
        color: PaletteColours.cardBackground,
        boxShadow: [
          BoxShadow(
            color: PaletteColours.shadowLevel1,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              style: PaletteTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Ask about your home...',
                hintStyle: PaletteTypography.bodyMedium.copyWith(
                  color: PaletteColours.textTertiary,
                ),
                filled: true,
                fillColor: PaletteColours.softCream,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: PaletteColours.sageGreenLight,
                  ),
                ),
              ),
              onSubmitted: _send,
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: PaletteColours.sageGreen,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => _send(_controller.text),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: PaletteColours.textOnAccent,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
