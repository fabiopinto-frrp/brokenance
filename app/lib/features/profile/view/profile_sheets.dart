import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/format/money.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/form_sheet.dart';
import '../../../core/widgets/money_field.dart';
import '../../../core/widgets/password_field.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/view/auth_validators.dart';
import '../bloc/profile_cubit.dart';
import '../data/profile.dart';

// The edit forms of the Profile screen. Each returns true when something was saved.
// The cubit and repository are read before opening the sheet: the sheet is a new route.

Future<bool> showBalanceSheet(BuildContext context, Profile profile) {
  final locale = Localizations.localeOf(context);
  final initial = profile.netWorthSet ? Money.formatInput(profile.netWorthCents, locale) : '';
  return showFormSheet(
    context,
    _BalanceForm(isSet: profile.netWorthSet, initialText: initial, cubit: context.read<ProfileCubit>()),
  );
}

Future<bool> showIncomeSheet(BuildContext context, Profile profile) {
  final income = profile.monthlyIncomeCents;
  final initial = income > 0 ? Money.formatInput(income, Localizations.localeOf(context)) : '';
  return showFormSheet(context, _IncomeForm(initialText: initial, cubit: context.read<ProfileCubit>()));
}

Future<bool> showNameSheet(BuildContext context, Profile profile) =>
    showFormSheet(context, _NameForm(profile: profile, cubit: context.read<ProfileCubit>()));

Future<bool> showChangePasswordSheet(BuildContext context) =>
    showFormSheet(context, _ChangePasswordForm(repository: context.read<AuthRepository>()));

class _BalanceForm extends StatefulWidget {
  const _BalanceForm({required this.isSet, required this.initialText, required this.cubit});

  final bool isSet;
  final String initialText;
  final ProfileCubit cubit;

  @override
  State<_BalanceForm> createState() => _BalanceFormState();
}

class _BalanceFormState extends State<_BalanceForm> {
  late final _amount = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      title: widget.isSet ? l10n.profileBalanceEdit : l10n.profileBalanceSetupTitle,
      note: widget.isSet ? l10n.profileBalanceAdjustNote : l10n.profileBalanceSetupMessage,
      fields: (submit) => [
        MoneyField(
          controller: _amount,
          label: l10n.profileBalanceTitle,
          allowNegative: true,
          allowZero: true,
          autofocus: true,
          onSubmitted: (_) => submit(),
        ),
      ],
      onSave: () => widget.cubit.setNetWorth(MoneyField.valueOf(_amount)!),
    );
  }
}

class _IncomeForm extends StatefulWidget {
  const _IncomeForm({required this.initialText, required this.cubit});

  final String initialText;
  final ProfileCubit cubit;

  @override
  State<_IncomeForm> createState() => _IncomeFormState();
}

class _IncomeFormState extends State<_IncomeForm> {
  late final _amount = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      title: l10n.profileIncomeTitle,
      note: l10n.profileIncomeNote,
      fields: (submit) => [
        MoneyField(
          controller: _amount,
          label: l10n.fieldAmount,
          allowZero: true,
          autofocus: true,
          onSubmitted: (_) => submit(),
        ),
      ],
      onSave: () => widget.cubit.updateMonthlyIncome(MoneyField.valueOf(_amount)!),
    );
  }
}

class _NameForm extends StatefulWidget {
  const _NameForm({required this.profile, required this.cubit});

  final Profile profile;
  final ProfileCubit cubit;

  @override
  State<_NameForm> createState() => _NameFormState();
}

class _NameFormState extends State<_NameForm> {
  late final _firstName = TextEditingController(text: widget.profile.firstName);
  late final _lastName = TextEditingController(text: widget.profile.lastName);

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      title: l10n.profileDetailsTitle,
      fields: (submit) => [
        TextFormField(
          controller: _firstName,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.fieldFirstName),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
          validator: AuthValidators.required(l10n),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _lastName,
          decoration: InputDecoration(labelText: l10n.fieldLastName),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
          validator: AuthValidators.required(l10n),
          onFieldSubmitted: (_) => submit(),
        ),
      ],
      onSave: () =>
          widget.cubit.updateName(firstName: _firstName.text.trim(), lastName: _lastName.text.trim()),
    );
  }
}

class _ChangePasswordForm extends StatefulWidget {
  const _ChangePasswordForm({required this.repository});

  final AuthRepository repository;

  @override
  State<_ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<_ChangePasswordForm> {
  final _current = TextEditingController();
  final _fresh = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _fresh.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      title: l10n.profileChangePassword,
      note: l10n.profileChangePasswordNote,
      fields: (submit) => [
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PasswordField(
                controller: _current,
                label: l10n.fieldCurrentPassword,
                validator: AuthValidators.required(l10n),
              ),
              const SizedBox(height: AppSpacing.md),
              PasswordField(
                controller: _fresh,
                label: l10n.fieldNewPassword,
                isNew: true,
                validator: AuthValidators.newPassword(l10n),
              ),
              const SizedBox(height: AppSpacing.md),
              PasswordField(
                controller: _confirm,
                label: l10n.fieldConfirmNewPassword,
                isNew: true,
                textInputAction: TextInputAction.done,
                validator: AuthValidators.confirmPassword(l10n, () => _fresh.text),
                onSubmitted: (_) => submit(),
              ),
            ],
          ),
        ),
      ],
      onSave: () async {
        await widget.repository.changePassword(currentPassword: _current.text, newPassword: _fresh.text);
        TextInput.finishAutofillContext();
      },
    );
  }
}
