import 'package:flutter/material.dart';


import '../../core/localization/locale_controller.dart';
import '../../core/routing/transitions.dart';
import '../../core/widgets/glow_backdrop.dart';
import '../../core/widgets/glass_card.dart';
import 'live_chat_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key, this.hasUnreadMessages = false});

  final bool hasUnreadMessages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSorani = LocaleController.instance.isSorani;

    final faqs = isSorani
        ? [
            {'q': 'چۆن دەتوانم بەشداری کویز بکەم؟', 'a': 'دەتوانیت لە ڕووکاری سەرەکی، دوگمەی "ئامادەم" دابگریت پێش دەستپێکردنی کویزەکە.'},
            {'q': 'ئایا پارەدان پێویستە بۆ بەشداریکردن؟', 'a': 'نەخێر، بەشداریکردن بەتەواوی بێبەرامبەرە و دەتوانیت خەڵات ببەیتەوە.'},
            {'q': 'چۆن خەڵاتەکەم وەردەگرم؟', 'a': 'دوای بردنەوە، دەتوانیت لە بەشی خەڵاتەکانم داوای خەڵاتەکەت بکەیت.'},
            {'q': 'ئەگەر هێڵی ئینتەرنێت پچڕا چی ڕوودەدات؟', 'a': 'کویزەکە بەردەوام دەبێت، ئەگەر خێرا بگەڕێیتەوە دەتوانیت بەردەوام بیت لە وەڵامدانەوە.'},
          ]
        : [
            {'q': 'Kûîzê çawa beşdar bibim?', 'a': 'Tu dikarî li rûpela serekî, pêl bişkoka "Amade me" bikî berî destpêkirina kûîzê.'},
            {'q': 'Gelo peredan pêwîst e?', 'a': 'Nexêr, beşdarbûn bi temamî bêpere ye û tu dikarî xelatan qezenc bikî.'},
            {'q': 'Xelata xwe çawa werdigirim?', 'a': 'Piştî qezenckirinê, tu dikarî li beşa xelatên min daxwaza xelata xwe bikî.'},
            {'q': 'Heke înternet qut bibe çi dibe?', 'a': 'Kûîz berdewam dike, heke tu zû vegerî tu dikarî berdewam bikî.'},
          ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isSorani ? 'یارمەتی و پشتیوانی' : 'Alîkarî û Piştgirî'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ColorFilter.mode(
              theme.scaffoldBackgroundColor.withOpacity(0.5),
              BlendMode.srcOver,
            ),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: GlowBackdrop(
        intensity: 0.3,
        child: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: faqs.length + 1, // +1 for header
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    isSorani ? 'پرسیارە باوەکان (FAQ)' : 'Pirsên Bersivdar (FAQ)',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                );
              }

              final faq = faqs[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  child: ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    tilePadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.help_outline_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      faq['q']!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    iconColor: theme.colorScheme.primary,
                    collapsedIconColor: theme.colorScheme.onSurface,
                    childrenPadding: const EdgeInsets.only(top: 8),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.subdirectory_arrow_right_rounded,
                              color: theme.colorScheme.primary.withOpacity(0.7),
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                faq['a']!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.9),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(fadeRoute(const LiveChatScreen()));
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: Badge(
              isLabelVisible: hasUnreadMessages,
              smallSize: 10,
              backgroundColor: theme.colorScheme.error,
              child: const Icon(Icons.chat_bubble_outline_rounded),
            ),
            label: Text(
              isSorani ? 'چاتی ڕاستەوخۆ' : 'Danûstandina Zindî',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
