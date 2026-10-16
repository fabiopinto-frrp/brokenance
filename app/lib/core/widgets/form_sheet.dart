import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import '../network/api_error_message.dart';
import '../network/api_exception.dart';
import '../theme/app_tokens.dart';
import 'error_banner.dart';

/// Opens [form] in a bottom sheet. Returns true when the form saved something.
///
/// [form] is usually a small StatefulWidget that owns its text controllers (so they are disposed
/// only after the sheet has closed) and builds a [FormSheet].
Future<bool> showFormSheet(BuildContext context, Widget form) async {
  // A message from the previous save would cover the sheet's Save button.
  ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => form,
  );
  return saved ?? false;
}

/// The layout and behaviour of every "edit" sheet: title, optional note, fields, and a Save
/// button. [onSave] sends the form: when it completes the sheet closes; when it throws an
/// [ApiException] the error is shown and the sheet stays open.
class FormSheet extends StatefulWidget {
  const FormSheet({
    super.key,
    required this.title,
    required this.fields,
    required this.onSave,
    this.note,
    this.saveLabel,
    this.onDelete,
  });

  final String title;
  final String? note;
  final String? saveLabel;

  /// The inputs. `submit` sends the form (for the keyboard's "done" button).
  final List<Widget> Function(VoidCallback submit) fields;
  final Future<void> Function() onSave;

  /// When set, a "Delete" button is shown. The sheet closes first, then this runs (it usually
  /// calls `deleteWithUndo` with the screen's context).
  final VoidCallback? onDelete;

  @override
  State<FormSheet> createState() => _FormSheetState();
}

class _FormSheetState extends State<FormSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  ApiException? _error;

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave();
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Padding(
      // Keeps the form above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.title, style: theme.textTheme.headlineSmall),
              if (widget.note != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(widget.note!, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (_error != null) ...[
                ErrorBanner(message: apiErrorMessage(l10n, _error!)),
                const SizedBox(height: AppSpacing.lg),
              ],
              ...widget.fields(_submit),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _submit,
                child: AnimatedSwitcher(
                  duration: AppDurations.fast,
                  child: _saving
                      ? SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : Text(widget.saveLabel ?? l10n.save),
                ),
              ),
              if (widget.onDelete != null) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(l10n.delete),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                    widget.onDelete!();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
