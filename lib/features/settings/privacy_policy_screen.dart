import 'package:flutter/material.dart';
import 'package:raccoon_bandit/l10n/app_localizations.dart';

import '../../core/ui/app_colors.dart';
import '../../core/ui/app_decorations.dart';
import '../../core/ui/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/settings_secondary_header.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final sections = [
      _PolicySection(
        icon: '📖',
        title: l10n.privacyIntroTitle,
        content: l10n.privacyIntroContent,
      ),
      _PolicySection(
        icon: '🔒',
        title: l10n.privacyDataTitle,
        content: l10n.privacyDataContent,
      ),
      _PolicySection(
        icon: '📢',
        title: l10n.privacyAdsTitle,
        content: l10n.privacyAdsContent,
      ),
      _PolicySection(
        icon: '🛒',
        title: l10n.privacyPurchasesTitle,
        content: l10n.privacyPurchasesContent,
      ),
      _PolicySection(
        icon: '📊',
        title: l10n.privacyAnalyticsTitle,
        content: l10n.privacyAnalyticsContent,
      ),
      _PolicySection(
        icon: '👨‍👩‍👧',
        title: l10n.privacyChildrenTitle,
        content: l10n.privacyChildrenContent,
      ),
      _PolicySection(
        icon: '🔗',
        title: l10n.privacyThirdPartyTitle,
        content: l10n.privacyThirdPartyContent,
      ),
      _PolicySection(
        icon: '⚖️',
        title: l10n.privacyGdprTitle,
        content: l10n.privacyGdprContent,
        extra: l10n.privacyContactEmail,
      ),
      _PolicySection(
        icon: '🔄',
        title: l10n.privacyUpdatesTitle,
        content: l10n.privacyUpdatesContent,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SettingsSecondaryHeader(title: l10n.privacyScreenTitle),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.hPadNormal,
                  AppSpacing.lg,
                  AppSpacing.hPadNormal,
                  AppSpacing.xl * 2,
                ),
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemCount: sections.length,
                itemBuilder: (context, index) => _SectionCard(
                  section: sections[index],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection {
  final String icon;
  final String title;
  final String content;
  final String? extra;

  const _PolicySection({
    required this.icon,
    required this.title,
    required this.content,
    this.extra,
  });
}

class _SectionCard extends StatelessWidget {
  final _PolicySection section;

  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.sectionCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(section.icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            section.content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: AppColors.textDark,
            ),
          ),
          if (section.extra != null) ...[
            const SizedBox(height: AppSpacing.xs),
            SelectableText(
              section.extra!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
                decoration: TextDecoration.underline,
                decorationColor: AppTheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
