import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import '../list/list_cubit.dart';
import '../network/api_error_message.dart';
import '../network/api_exception.dart';

/// Removes an item from the list right away and shows "Deleted · Undo". The delete is only sent
/// to the API when the message goes away without "Undo".
Future<void> deleteWithUndo(
  BuildContext context, {
  required ListCubit<Object?> cubit,
  required String id,
  required Future<void> Function() request,
}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);

  cubit.hide(id);
  messenger.hideCurrentSnackBar();
  final reason = await messenger
      .showSnackBar(
        SnackBar(
          content: Text(l10n.deleted),
          duration: const Duration(seconds: 4),
          // Snack bars with an action stay until tapped by default; this one must go away on its
          // own, because the delete is only sent when it does.
          persist: false,
          action: SnackBarAction(label: l10n.undo, onPressed: () {}),
        ),
      )
      .closed;

  if (reason == SnackBarClosedReason.action) {
    cubit.restore(id);
    return;
  }
  try {
    await cubit.delete(id, request);
  } on ApiException catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(l10n, error))));
  }
}
