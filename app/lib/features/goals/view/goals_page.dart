import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/list/list_page.dart';
import '../../../core/router/app_destinations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../core/widgets/money_field.dart';
import '../../../core/widgets/undo_delete.dart';
import '../../auth/view/auth_validators.dart';
import '../bloc/goals_cubit.dart';
import '../data/goal.dart';
import '../data/goal_repository.dart';

/// Objetivos: save X to buy Y, with progress and a quick "+ Add".
class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GoalsCubit(context.read<GoalRepository>())..refresh(),
      child: const _GoalsView(),
    );
  }
}

class _GoalsView extends StatelessWidget {
  const _GoalsView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<GoalsCubit>();
    final l10n = context.l10n;

    return ListPage<List<Goal>>(
      state: cubit.state,
      onRefresh: cubit.refresh,
      addLabel: l10n.add,
      onAdd: () => _showGoalForm(context, cubit),
      builder: (context, goals) {
        final visible = goals.where((goal) => !cubit.state.hidden.contains(goal.id)).toList();
        if (visible.isEmpty) {
          return ListView(
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.7,
                child: EmptyState(
                  icon: AppDestination.goals.selectedIcon,
                  title: l10n.goalsEmptyTitle,
                  message: l10n.goalsEmptyMessage,
                ),
              ),
            ],
          );
        }
        return ListView(
          padding: listPadding,
          children: [
            for (final goal in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _GoalCard(goal: goal),
              ),
          ],
        );
      },
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GoalsCubit>();
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final colors = context.colors;
    final progressColor = goal.completed ? colors.positive : theme.colorScheme.primary;
    final deadline = goal.deadline;
    final months = goal.estimatedMonthsLeft;

    void delete() =>
        deleteWithUndo(context, cubit: cubit, id: goal.id, request: () => cubit.repository.delete(goal.id));

    return SwipeToDelete(
      id: goal.id,
      onDelete: delete,
      child: Card(
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: () => _showGoalForm(context, cubit, goal: goal, onDelete: delete),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.md, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name,
                            style: theme.textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (deadline != null)
                            Text(
                              l10n.goalDeadline(AppDates.day(deadline, locale)),
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    if (goal.completed)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: Chip(
                          avatar: Icon(Icons.check_rounded, color: colors.positive, size: 18),
                          label: Text(
                            l10n.goalCompleted,
                            style: theme.textTheme.labelLarge?.copyWith(color: colors.positive),
                          ),
                          side: BorderSide.none,
                          backgroundColor: colors.positive.withValues(alpha: 0.12),
                        ),
                      )
                    else
                      TextButton.icon(
                        onPressed: () => _showContributionForm(context, cubit, goal),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(l10n.add),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: (goal.progressPercent / 100).clamp(0, 1)),
                    duration: AppDurations.slow * 2,
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                      color: progressColor,
                      backgroundColor: colors.surfaceHigh,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.goalProgress(
                            Money.format(goal.savedCents, locale),
                            Money.format(goal.targetCents, locale),
                          ),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      Text(
                        '${goal.progressPercent}%',
                        style: theme.textTheme.titleSmall?.copyWith(color: progressColor),
                      ),
                    ],
                  ),
                ),
                if (!goal.completed) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    [
                      l10n.goalRemaining(Money.format(goal.remainingCents, locale)),
                      if (months != null && months > 0) l10n.goalMonthsLeft(months),
                    ].join(' · '),
                    style: theme.textTheme.bodySmall,
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

Future<bool> _showGoalForm(BuildContext context, GoalsCubit cubit, {Goal? goal, VoidCallback? onDelete}) {
  final locale = Localizations.localeOf(context);
  return showFormSheet(
    context,
    _GoalForm(
      cubit: cubit,
      goal: goal,
      initialTarget: goal == null ? '' : Money.formatInput(goal.targetCents, locale),
      initialSaved: goal == null ? '' : Money.formatInput(goal.savedCents, locale),
      onDelete: onDelete,
    ),
  );
}

class _GoalForm extends StatefulWidget {
  const _GoalForm({
    required this.cubit,
    required this.initialTarget,
    required this.initialSaved,
    this.goal,
    this.onDelete,
  });

  final GoalsCubit cubit;
  final Goal? goal;
  final String initialTarget;
  final String initialSaved;
  final VoidCallback? onDelete;

  @override
  State<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<_GoalForm> {
  late final _name = TextEditingController(text: widget.goal?.name);
  late final _target = TextEditingController(text: widget.initialTarget);
  late final _saved = TextEditingController(text: widget.initialSaved);
  late String? _deadline = widget.goal?.deadline;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _saved.dispose();
    super.dispose();
  }

  Future<void> _save() {
    final input = GoalInput(
      name: _name.text.trim(),
      targetCents: MoneyField.valueOf(_target)!,
      savedCents: MoneyField.valueOf(_saved) ?? 0,
      deadline: _deadline,
    );
    final existing = widget.goal;
    return existing == null ? widget.cubit.create(input) : widget.cubit.update(existing.id, input);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      title: widget.goal == null ? l10n.goalNew : l10n.goalEdit,
      onSave: _save,
      onDelete: widget.onDelete,
      fields: (submit) => [
        TextFormField(
          controller: _name,
          autofocus: widget.goal == null,
          decoration: InputDecoration(labelText: l10n.fieldGoalName),
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          inputFormatters: [LengthLimitingTextInputFormatter(80)],
          validator: AuthValidators.required(l10n),
        ),
        const SizedBox(height: AppSpacing.md),
        MoneyField(controller: _target, label: l10n.fieldTarget, textInputAction: TextInputAction.next),
        const SizedBox(height: AppSpacing.md),
        MoneyField(
          controller: _saved,
          label: l10n.fieldSaved,
          allowZero: true,
          optional: true,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        DateField(
          label: l10n.fieldDeadline,
          initialValue: _deadline,
          optional: true,
          allowFuture: true,
          onChanged: (value) => _deadline = value,
        ),
      ],
    );
  }
}

Future<bool> _showContributionForm(BuildContext context, GoalsCubit cubit, Goal goal) {
  return showFormSheet(
    context,
    _ContributionForm(
      cubit: cubit,
      goal: goal,
      savedText: Money.format(goal.savedCents, Localizations.localeOf(context)),
    ),
  );
}

class _ContributionForm extends StatefulWidget {
  const _ContributionForm({required this.cubit, required this.goal, required this.savedText});

  final GoalsCubit cubit;
  final Goal goal;
  final String savedText;

  @override
  State<_ContributionForm> createState() => _ContributionFormState();
}

class _ContributionFormState extends State<_ContributionForm> {
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      title: l10n.goalAddTitle(widget.goal.name),
      note: l10n.goalAddNote(widget.savedText),
      saveLabel: l10n.add,
      onSave: () => widget.cubit.addContribution(widget.goal.id, MoneyField.valueOf(_amount)!),
      fields: (submit) => [
        MoneyField(
          controller: _amount,
          label: l10n.fieldAmount,
          autofocus: true,
          onSubmitted: (_) => submit(),
        ),
      ],
    );
  }
}
