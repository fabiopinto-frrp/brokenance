import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/privacy/balance_visibility.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/section_title.dart';
import '../bloc/profile_cubit.dart';
import '../data/profile.dart';
import 'profile_sheets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfileCubit>().state;
    final profile = state.profile;

    if (profile == null) {
      if (state.status == ProfileStatus.failure) {
        return ErrorView(error: state.error!, onRetry: context.read<ProfileCubit>().refresh);
      }
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: context.read<ProfileCubit>().refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.xxl),
        children: [
          if (profile.netWorthSet) _BalanceCard(profile: profile) else _BalanceSetupCard(profile: profile),
          const SizedBox(height: AppSpacing.lg),
          _IncomeCard(profile: profile),
          const SizedBox(height: AppSpacing.xl),
          SectionTitle(context.l10n.profileDetailsTitle),
          _DetailsCard(profile: profile),
          const SizedBox(height: AppSpacing.xl),
          SectionTitle(context.l10n.profileSecurityTitle),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline_rounded),
              title: Text(context.l10n.profileChangePassword),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () =>
                  _afterSave(context, showChangePasswordSheet(context), context.l10n.profilePasswordChanged),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a short confirmation when a sheet saved something.
Future<void> _afterSave(BuildContext context, Future<bool> sheet, [String? message]) async {
  final messenger = ScaffoldMessenger.of(context);
  final text = message ?? context.l10n.saved;
  if (await sheet) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: () => _afterSave(context, showBalanceSheet(context, profile)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(context.l10n.profileBalanceTitle, style: theme.textTheme.labelMedium)),
                  const BalanceVisibilityButton(size: 18),
                  Icon(Icons.edit_outlined, size: 18, color: context.colors.textSecondary),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              BalanceText(cents: profile.netWorthCents, style: theme.textTheme.displayMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown until the user types their balance for the first time.
class _BalanceSetupCard extends StatelessWidget {
  const _BalanceSetupCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.primary, size: 32),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.profileBalanceSetupTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.profileBalanceSetupMessage, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => _afterSave(context, showBalanceSheet(context, profile)),
              child: Text(l10n.profileBalanceSetupButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomeCard extends StatelessWidget {
  const _IncomeCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final hasIncome = profile.monthlyIncomeCents > 0;

    return Card(
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: () => _afterSave(context, showIncomeSheet(context, profile)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              Icon(Icons.payments_outlined, color: context.colors.positive),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.profileIncomeTitle, style: theme.textTheme.labelMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      hasIncome
                          ? Money.format(profile.monthlyIncomeCents, Localizations.localeOf(context))
                          : l10n.profileIncomeNone,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: hasIncome ? null : context.colors.textSecondary,
                      ),
                    ),
                    if (hasIncome) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(l10n.profileIncomeHint, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              Icon(Icons.edit_outlined, size: 18, color: context.colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    void edit() => _afterSave(context, showNameSheet(context, profile));

    return Card(
      child: Column(
        children: [
          _DetailRow(label: l10n.fieldFirstName, value: profile.firstName, onTap: edit),
          const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
          _DetailRow(label: l10n.fieldLastName, value: profile.lastName, onTap: edit),
          const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
          // The username cannot be changed.
          _DetailRow(label: l10n.fieldUsername, value: '@${profile.username}'),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(label, style: theme.textTheme.bodyMedium),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(value, style: theme.textTheme.bodyLarge, overflow: TextOverflow.ellipsis),
          ),
          if (onTap != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right_rounded, color: context.colors.textSecondary),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}
