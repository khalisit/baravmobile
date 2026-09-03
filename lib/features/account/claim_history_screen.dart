import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/animation/fade_slide_in.dart';
import '../../core/localization/app_strings.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/kurdish_format.dart';
import '../../core/widgets/glow_backdrop.dart';
import '../../core/session/session_controller.dart';
import '../../data/api_service.dart';
import '../../data/models.dart';

class ClaimHistoryScreen extends StatefulWidget {
  const ClaimHistoryScreen({super.key});

  @override
  State<ClaimHistoryScreen> createState() => _ClaimHistoryScreenState();
}

class _ClaimHistoryScreenState extends State<ClaimHistoryScreen> {
  static List<ClaimReceipt>? _cachedReceipts;

  List<ClaimReceipt>? _receipts = _cachedReceipts;
  bool _isLoading = _cachedReceipts == null;
  String? _error;
  Timer? _realtimeTimer;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
    _realtimeTimer = Timer.periodic(const Duration(seconds: 22), (_) {
      _silentLoadReceipts();
    });
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadReceipts() async {
    final session = SessionController.instance;
    try {
      final data = await ApiService.getReceipts(
        userId: session.user?.id ?? '',
        token: session.token ?? '',
      );
      _cachedReceipts = data;
      if (mounted) {
        setState(() {
          _receipts = data;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          if (_receipts == null) _isLoading = false;
        });
      }
    }
  }

  Future<void> _silentLoadReceipts() async {
    final session = SessionController.instance;
    try {
      final data = await ApiService.getReceipts(
        userId: session.user?.id ?? '',
        token: session.token ?? '',
      );
      _cachedReceipts = data;
      if (mounted) {
        setState(() {
          _receipts = data;
          _error = null;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    LocaleScope.of(context);
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final isSorani = LocaleController.instance.isSorani;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.claimHistory),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: GlowBackdrop(
        intensity: 0.4,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => _loadReceipts(),
            child: Builder(
              builder: (context) {
                if (_isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.purpleLight,
                    ),
                  );
                } else if (_error != null) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: AppColors.danger.withValues(alpha: 0.8),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isSorani
                                    ? 'هەڵەیەک ڕوویدا لە بارکردنی وەسڵەکان'
                                    : 'Xeletiyek çêbû di barkirina weselan de',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!.replaceAll('Exception: ', ''),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.textMuted,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                final list = _receipts ?? [];

                // Calculate totals
                double totalClaimedIqd = 0;
                double totalClaimedUsd = 0;
                for (final item in list) {
                  if (item.status.toUpperCase() == 'PAID') {
                    if (item.currency == 'USD') {
                      totalClaimedUsd += item.amount;
                    } else {
                      totalClaimedIqd += item.amount;
                    }
                  }
                }

                final session = SessionController.instance;
                final totalRewards = session.user?.totalRewards ?? 0;
                double totalUnclaimedIqd = (totalRewards - totalClaimedIqd).clamp(0, double.infinity);

                String claimedText;
                if (totalClaimedUsd > 0 && totalClaimedIqd > 0) {
                  claimedText = '\$${KurdishFormat.number(totalClaimedUsd.round())} / ${KurdishFormat.moneyIqd(totalClaimedIqd.round())}';
                } else if (totalClaimedUsd > 0) {
                  claimedText = '\$${KurdishFormat.number(totalClaimedUsd.round())}';
                } else {
                  claimedText = KurdishFormat.moneyIqd(totalClaimedIqd.round());
                }

                final unclaimedText = KurdishFormat.moneyIqd(totalUnclaimedIqd.round());

                return Column(
                  children: [
                    // Totals Cards Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isSorani ? 'خەڵاتی وەرگیراو' : 'Xelatên wergirtî',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    claimedText,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: colors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.pending_actions_rounded,
                                        color: Colors.orange,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isSorani ? 'خەڵاتی نەدراو' : 'Xelatên nedayî',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    unclaimedText,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: colors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: list.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.receipt_long_rounded,
                                          size: 54,
                                          color: colors.textMuted.withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          AppStrings.noClaimsYet,
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            color: colors.textMuted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: list.length,
                              itemBuilder: (context, index) {
                                final item = list[index];
                                final isPaid = item.status.toUpperCase() == 'PAID';
                                
                                String statusText;
                                Color statusColor;
                                if (isPaid) {
                                  statusText = isSorani ? 'دراوە' : 'هاتیە دان';
                                  statusColor = Colors.green;
                                } else {
                                  statusText = isSorani ? 'لە چاوەڕوانیدا' : 'د هیڤیێدا';
                                  statusColor = Colors.orange;
                                }

                                final formattedAmount = item.currency == 'USD'
                                    ? '\$${KurdishFormat.number(item.amount.round())}'
                                    : KurdishFormat.moneyIqd(item.amount.round());

                                return FadeSlideIn(
                                  delay: Duration(milliseconds: index * 60),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: colors.stroke),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                formattedAmount,
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: colors.ink,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  statusText,
                                                  style: theme.textTheme.labelSmall?.copyWith(
                                                    color: statusColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            '${KurdishFormat.date(item.createdAt)} ${KurdishFormat.time(item.createdAt)}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: colors.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (item.quizTitle != null && item.quizTitle!.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Divider(height: 1, thickness: 1, color: colors.stroke),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.emoji_events_outlined,
                                                  size: 16,
                                                  color: Colors.orange.withValues(alpha: 0.8),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    isSorani ? 'کویز: ${item.quizTitle}' : 'کویز: ${item.quizTitle}',
                                                    style: theme.textTheme.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (item.notes != null && item.notes!.isNotEmpty) ...[
                                            if (item.quizTitle == null || item.quizTitle!.isEmpty) ...[
                                              const SizedBox(height: 12),
                                              Divider(height: 1, thickness: 1, color: colors.stroke),
                                            ],
                                            const SizedBox(height: 10),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.notes_rounded,
                                                  size: 16,
                                                  color: colors.textMuted,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    item.notes!,
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      fontSize: 12,
                                                      height: 1.35,
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
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
