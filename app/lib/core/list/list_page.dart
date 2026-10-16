import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../widgets/error_view.dart';
import 'list_cubit.dart';

/// The frame of every list screen: spinner on the first load, "Try again" when it fails, pull to
/// refresh, and the "+ Add" button. [builder] draws the loaded data.
class ListPage<D> extends StatelessWidget {
  const ListPage({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.builder,
    required this.addLabel,
    required this.onAdd,
  });

  final ListState<D> state;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext context, D data) builder;
  final String addLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final data = state.data;
    final Widget body;
    if (data != null) {
      body = RefreshIndicator(onRefresh: onRefresh, child: builder(context, data));
    } else if (state.status == ListStatus.failure) {
      body = ErrorView(error: state.error!, onRetry: onRefresh);
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedSwitcher(duration: AppDurations.medium, child: body),
      floatingActionButton: data == null
          ? null
          : FloatingActionButton.extended(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(addLabel),
            ),
    );
  }
}

/// Padding for a list's content, leaving room at the bottom for the "+ Add" button.
const listPadding = EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, 120);

/// A row that can be swiped left to delete.
class SwipeToDelete extends StatelessWidget {
  const SwipeToDelete({super.key, required this.id, required this.onDelete, required this.child});

  final String id;
  final VoidCallback onDelete;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.negative;
    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: AppRadius.card),
        child: Icon(Icons.delete_outline_rounded, color: color),
      ),
      child: child,
    );
  }
}

/// Money in a list row: tabular figures so amounts line up.
class AmountText extends StatelessWidget {
  const AmountText(this.text, {super.key, this.color, this.large = false});

  final String text;
  final Color? color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = large ? theme.textTheme.displaySmall : theme.textTheme.titleMedium;
    return Text(
      text,
      style: style?.copyWith(color: color, fontFeatures: const [FontFeature.tabularFigures()]),
      maxLines: 1,
    );
  }
}
