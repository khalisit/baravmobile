import 'package:flutter/material.dart';

import '../../core/localization/locale_controller.dart';
import '../../core/widgets/glow_backdrop.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSorani = LocaleController.instance.isSorani;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isSorani ? 'یاسا و ڕێنماییەکان' : 'Qanûn û Rêwerz'),
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
        intensity: 0.1,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Official Header
                    Center(
                      child: Icon(
                        Icons.gavel_rounded,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isSorani ? 'بەڵگەنامەی یاسایی و ڕێنماییەکان' : 'Belgeya Qanûnî û Rêwerzan',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Divider(color: theme.colorScheme.primary.withOpacity(0.3), thickness: 2),
                    const SizedBox(height: 32),
                    
                    // Terms
                    _buildDocumentSection(
                      theme,
                      title: isSorani ? '١. پەیماننامەی بەکارهێنان (Terms of Service)' : '1. Mercên Bikaranînê (Terms of Service)',
                      content: isSorani
                          ? '١.١ پێویستە هەموو بەشداربوویەک زانیاری دروست بدات لەکاتی خۆتۆمارکردن.\n\n'
                            '١.٢ هەر جۆرە فێڵکردنێک یان بەکارهێنانی ئامرازی دەرەکی بۆ وەڵامدانەوەی پرسیارەکان، دەبێتە هۆی سڕینەوەی هەژمارەکە بێ ئاگادارکردنەوە.\n\n'
                            '١.٣ خەڵاتەکان تەنها بۆ ئەو کەسانەن کە بە شێوەیەکی یاسایی و بێ فێڵ یاری دەکەن.\n\n'
                            '١.٤ ئادمین مافی ئەوەی هەیە هەر کاتێک بیەوێت گۆڕانکاری لە کاتی کویز یان جۆری خەڵاتەکان بکات.'
                          : '1.1 Divê her beşdar zanyariyên rast bide dema xwe tomarkirinê.\n\n'
                            '1.2 Her cûre sextekarî an bikaranîna amûrên derveyî ji bo bersivdana pirsan, dê bibe sedema jêbirina hesabê bêyî agahdarkirin.\n\n'
                            '1.3 Xelat tenê ji bo wan kesan e ku bi rengekî qanûnî û bê sextekarî dilîzin.\n\n'
                            '1.4 Mafê admîn heye ku her dem guhertin di dema kûîzê an cûreyê xelatan de bike.',
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Privacy
                    _buildDocumentSection(
                      theme,
                      title: isSorani ? '٢. پاراستنی تایبەتمەندی (Privacy Policy)' : '2. Parastina Taybetmendiyê (Privacy Policy)',
                      content: isSorani
                          ? '٢.١ زانیارییە کەسییەکانی وەک ناوی تەواو و ژمارەی تەلەفۆن پارێزراون و نادرێن بە هیچ لایەنێکی سێیەم.\n\n'
                            '٢.٢ ئێمە زانیارییەکان تەنها بۆ دابەشکردنی خەڵاتەکان و پەیوەندی کردن بە براوەکانەوە بەکاردەهێنین.\n\n'
                            '٢.٣ پاسۆردەکان بە شێوەیەکی پارێزراو (Encrypted) پاشەکەوت دەکرێن و کەس ناتوانێت بیانبینێت.\n\n'
                            '٢.٤ بەکارهێنەر مافی سڕینەوەی تەواوی زانیارییەکانی هەیە لە هەر کاتێکدا بیەوێت لە ڕێگەی ئەپەکەوە.'
                          : '2.1 Zanyariyên kesane wek navê temam û hejmara telefonê parastî ne û nadin ti aliyekî sêyem.\n\n'
                            '2.2 Em zanyariyan tenê ji bo dabeşkirina xelatan û têkildarî li gel serketiyan bikartînin.\n\n'
                            '2.3 Şîfre bi rengekî parastî (Encrypted) tên tomarkirin û kes nikare wan bibîne.\n\n'
                            '2.4 Mafê bikarhêner heye ku hemû zanyariyên xwe di her demê de bi rêya sepanê jê bibe.',
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Footer/Signature
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSorani ? 'واژوو (Signature)' : 'Îmze (Signature)',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Barav Quiz Admin',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              height: 1,
                              width: 120,
                              color: theme.colorScheme.onSurface.withOpacity(0.2),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isSorani ? 'بەرواری دەرچوون' : 'Dîroka Derketinê',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '01-09-2024',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentSection(ThemeData theme, {required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          textAlign: TextAlign.justify,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.8,
            color: theme.colorScheme.onSurface.withOpacity(0.85),
          ),
        ),
      ],
    );
  }
}
