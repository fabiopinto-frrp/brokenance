import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/password_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_form_cubit.dart';
import '../data/auth_repository.dart';
import 'auth_layout.dart';
import 'auth_validators.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthFormCubit(context.read<AuthBloc>()),
      child: const _LoginForm(),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final repository = context.read<AuthRepository>();
    TextInput.finishAutofillContext();
    context.read<AuthFormCubit>().submit(
      () => repository.login(username: _username.text.trim(), password: _password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final form = context.watch<AuthFormCubit>().state;
    final sessionExpired = context.select((AuthBloc bloc) => bloc.state.sessionExpired);
    final clearError = context.read<AuthFormCubit>().clearError;

    return AuthLayout(
      showLogo: true,
      title: l10n.appTitle,
      subtitle: l10n.loginSubtitle,
      children: [
        if (form.error != null) ...[
          ErrorBanner(message: apiErrorMessage(l10n, form.error!)),
          const SizedBox(height: AppSpacing.lg),
        ] else if (sessionExpired) ...[
          ErrorBanner(message: l10n.errorSessionExpired, icon: Icons.lock_clock_outlined),
          const SizedBox(height: AppSpacing.lg),
        ],
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _username,
                  decoration: InputDecoration(labelText: l10n.fieldUsername),
                  autofillHints: const [AutofillHints.username],
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [LengthLimitingTextInputFormatter(30)],
                  validator: AuthValidators.required(l10n),
                  onChanged: (_) => clearError(),
                ),
                const SizedBox(height: AppSpacing.md),
                PasswordField(
                  controller: _password,
                  label: l10n.fieldPassword,
                  textInputAction: TextInputAction.done,
                  validator: AuthValidators.required(l10n),
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) => clearError(),
                ),
                const SizedBox(height: AppSpacing.xl),
                SubmitButton(label: l10n.loginButton, loading: form.isSubmitting, onPressed: _submit),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AuthSwitchLink(
          question: l10n.loginNoAccount,
          action: l10n.loginCreateAccount,
          onPressed: () => context.push(AppRoutes.register),
        ),
      ],
    );
  }
}
