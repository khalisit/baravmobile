import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models.dart';
import 'video_ad_modal.dart';

/// کارتی ڕیکلام — وێنە و ڤیدیۆ پیشان دەدات و خۆکارانە دەگۆڕدرێت.
class AdCarousel extends StatefulWidget {
  const AdCarousel({super.key, required this.ads});

  final List<AdItem> ads;

  @override
  State<AdCarousel> createState() => _AdCarouselState();
}

class _AdCarouselState extends State<AdCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.94);
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.ads.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      int nextPage = 0;
      if (_controller.page != null) {
        nextPage = (_controller.page!.round() + 1) % widget.ads.length;
      } else {
        nextPage = (_index + 1) % widget.ads.length;
      }
      _controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 620),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void didUpdateWidget(covariant AdCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldUrls = oldWidget.ads.map((ad) => ad.mediaUrl).join(',');
    final newUrls = widget.ads.map((ad) => ad.mediaUrl).join(',');
    if (oldUrls != newUrls || _timer == null) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 2.3,
          child: NotificationListener<UserScrollNotification>(
            onNotification: (_) {
              _startTimer();
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.ads.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _AdSlide(ad: widget.ads[i]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.ads.length; i++)
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
    );
  }
}

class _AdSlide extends StatelessWidget {
  const _AdSlide({required this.ad});

  final AdItem ad;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (ad.kind == AdKind.video &&
            ad.mediaUrl != null &&
            ad.mediaUrl!.isNotEmpty) {
          showDialog(
            context: context,
            barrierColor: Colors.black38,
            builder: (context) =>
                VideoAdModal(videoUrl: ad.mediaUrl!, title: ad.title),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(26)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _AdBackground(ad: ad),

              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        ad.tint.first.withValues(alpha: 0.15),
                      ],
                      stops: const [0.40, 1.0],
                    ),
                  ),
                ),
              ),

              if (ad.kind == AdKind.video) ...[
                PositionedDirectional(
                  top: 8,
                  end: 10,
                  child: _Badge(
                    label: AppStrings.video,
                    icon: Icons.play_circle_outline_rounded,
                  ),
                ),
                const Center(child: _PlayButton()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// ئەگەر لینکی میدیا لە باک ئێندەوە هات، وێنەکە پیشان دەدرێت؛
/// ئەگەرنا دیزاینێکی ناوخۆیی جێگەی دەگرێتەوە.
class _AdBackground extends StatelessWidget {
  const _AdBackground({required this.ad});

  final AdItem ad;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: ad.tint,
        ),
      ),
      child: CustomPaint(
        painter: _RingsPainter(),
        child: const SizedBox.expand(),
      ),
    );

    final url = ad.mediaUrl;
    if (url == null || url.isEmpty) return fallback;

    if (ad.kind == AdKind.video) {
      return _VideoAdSlidePreview(videoUrl: url);
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorWidget: (_, _, _) => fallback,
      placeholder: (context, url) => fallback,
    );
  }
}

class _VideoAdSlidePreview extends StatefulWidget {
  const _VideoAdSlidePreview({required this.videoUrl});
  final String videoUrl;

  @override
  State<_VideoAdSlidePreview> createState() => _VideoAdSlidePreviewState();
}

class _VideoAdSlidePreviewState extends State<_VideoAdSlidePreview> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant _VideoAdSlidePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.dispose();
      setState(() {
        _initialized = false;
        _controller = null;
      });
      _init();
    }
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    _controller = controller;
    try {
      await controller.initialize();
      if (mounted && _controller == controller) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _controller == null) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: AppColors.purpleLight,
            strokeWidth: 2,
          ),
        ),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}

/// بازنە نەرمەکانی پشتەوە بۆ ئەوەی کارتەکە بێ‌ڕوو نەبێت.
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  static const Color _overlayLight = Color(0xFFF5F5F7);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
        child: Opacity(
          opacity: 0.8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Color(0xFF10172A).withValues(alpha: 0.50),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _overlayLight.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 11.5, color: _overlayLight),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: _overlayLight,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton();

  static const Color _overlayLight = Color(0xFFF5F5F7);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(0xFF10172A).withValues(alpha: 0.50),
            shape: BoxShape.circle,
            border: Border.all(
              color: _overlayLight.withValues(alpha: 0.3),
              width: 0.8,
            ),
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            size: 20,
            color: _overlayLight,
          ),
        ),
      ),
    );
  }
}
