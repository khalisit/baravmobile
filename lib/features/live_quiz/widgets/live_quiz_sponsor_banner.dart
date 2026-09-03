import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/live_quiz_models.dart';

/// بانەری سپۆنسەر لە سەرەوەی پرسیار — چەند ڕیکلام خۆکارانە دەگۆڕدرێن.
class LiveQuizSponsorBanner extends StatefulWidget {
  const LiveQuizSponsorBanner({super.key, required this.sponsors});

  final List<QuizSponsor> sponsors;

  @override
  State<LiveQuizSponsorBanner> createState() => _LiveQuizSponsorBannerState();
}

class _LiveQuizSponsorBannerState extends State<LiveQuizSponsorBanner> {
  late final PageController _pageController = PageController(
    viewportFraction: 0.94,
  );
  Timer? _timer;
  int _index = 0;

  List<QuizSponsor> get _items =>
      widget.sponsors.where((s) => s.hasMedia).toList(growable: false);

  String _signature(List<QuizSponsor> list) =>
      list.map((s) => '${s.mediaUrl}|${s.brandName}').join('||');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTimer());
  }

  @override
  void didUpdateWidget(covariant LiveQuizSponsorBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_signature(oldWidget.sponsors) != _signature(widget.sponsors)) {
      _index = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    final count = _items.length;
    if (count < 2) return;

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      int nextPage = 0;
      if (_pageController.page != null) {
        nextPage = (_pageController.page!.round() + 1) % count;
      } else {
        nextPage = (_index + 1) % count;
      }
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 620),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final items = _items;
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 2.4,
          child: NotificationListener<UserScrollNotification>(
            onNotification: (_) {
              _startTimer();
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: items.length,
              onPageChanged: (i) {
                if (_index != i) setState(() => _index = i);
              },
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _SponsorSlide(sponsor: items[i]),
              ),
            ),
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < items.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.purpleLight : colors.stroke,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SponsorSlide extends StatelessWidget {
  const _SponsorSlide({required this.sponsor});

  final QuizSponsor sponsor;

  @override
  Widget build(BuildContext context) {
    AppColors.of(context);

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(26)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _SponsorBackground(sponsor: sponsor),

            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.purple.withValues(alpha: 0.15),
                    ],
                    stops: const [0.40, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SponsorBackground extends StatelessWidget {
  const _SponsorBackground({required this.sponsor});

  final QuizSponsor sponsor;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.purpleGradient),
      child: CustomPaint(
        painter: _RingsPainter(),
        child: const SizedBox.expand(),
      ),
    );

    final url = sponsor.mediaUrl;
    if (url.isEmpty) return fallback;

    return CachedNetworkImage(
      imageUrl: url.trim(),
      fit: BoxFit.cover,
      errorWidget: (_, _, _) => fallback,
      placeholder: (context, url) => fallback,
    );
  }
}

class _RingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..color = Colors.white.withValues(alpha: 0.06);

    final center = Offset(size.width * 0.82, size.height * 0.22);
    for (final radius in [size.height * 0.35, size.height * 0.62]) {
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) => false;
}
