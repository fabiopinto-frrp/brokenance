import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/password_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_form_cubit.dart';
import '../data/auth_repository.dart';
import 'auth_layout.dart';
import 'auth_validators.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthFormCubit(context.read<AuthBloc>()),
      child: const _RegisterForm(),
    );
  }
}

class _RegisterForm extends StatefulWidget {
  const _RegisterForm();

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void dispose() {
    for (final controller in [_firstName, _lastName, _username, _password, _confirmPassword]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final repository = context.read<AuthRepository>();
    TextInput.finishAutofillContext();
    context.read<AuthFormCubit>().submit(
      () => repository.register(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        username: _username.text.trim(),
        password: _password.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final form = context.watch<AuthFormCubit>().state;
    final clearError = context.read<AuthFormCubit>().clearError;
    // "Username taken" is shown on the username field itself, other errors above the form.
    final usernameTaken = form.error?.code == 'username_taken';

    InputDecoration decoration(String label) => InputDecoration(labelText: label);

    return AuthLayout(
      title: l10n.registerTitle,
      subtitle: l10n.registerSubtitle,
      leading: BackButton(onPressed: () => context.pop()),
      children: [
        if (form.error != null && !usernameTaken) ...[
          ErrorBanner(message: apiErrorMessage(l10n, form.error!)),
          const SizedBox(height: AppSpacing.lg),
        ],
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstName,
                        decoration: decoration(l10n.fieldFirstName),
                        autofillHints: const [AutofillHints.givenName],
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [LengthLimitingTextInputFormatter(50)],
                        validator: AuthValidators.required(l10n),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _lastName,
                        decoration: decoration(l10n.fieldLastName),
                        autofillHints: const [AutofillHints.familyName],
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [LengthLimitingTextInputFormatter(50)],
                        validator: AuthValidators.required(l10n),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _username,
                  decoration: decoration(l10n.fieldUsername)
                      .copyWith(errorText: usernameTaken ? l10n.errorUsernameTaken : null),
                  autofillHints: const [AutofillHints.newUsername],
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(30),
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  validator: AuthValidators.username(l10n),
                  onChanged: (_) => clearError(),
                ),
                const SizedBox(height: AppSpacing.md),
                PasswordField(
                  controller: _password,
                  label: l10n.fieldPassword,
                  isNew: true,
                  validator: AuthValidators.newPassword(l10n),
                ),
                const SizedBox(height: AppSpacing.md),
                PasswordField(
                  controller: _confirmPassword,
                  label: l10n.fieldConfirmPassword,
                  isNew: true,
                  textInputAction: TextInputAction.done,
                  validator: AuthValidators.confirmPassword(l10n, () => _password.text),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.xl),
                SubmitButton(label: l10n.registerButton, loading: form.isSubmitting, onPressed: _submit),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AuthSwitchLink(
          question: l10n.registerHaveAccount,
          action: l10n.registerLogin,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}
