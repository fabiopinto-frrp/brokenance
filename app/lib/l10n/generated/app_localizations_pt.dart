// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Brokenance';

  @override
  String get navDashboard => 'Resumo';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navSubscriptions => 'Subscrições';

  @override
  String get navExpenses => 'Despesas';

  @override
  String get navOutings => 'Saídas/Férias';

  @override
  String get navLeisure => 'Lazer';

  @override
  String get navSavings => 'Poupança';

  @override
  String get navGoals => 'Objetivos';

  @override
  String get navSettings => 'Definições';

  @override
  String get navOpenMenu => 'Abrir menu';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageEnglish => 'English';

  @override
  String get comingSoonTitle => 'Em breve';

  @override
  String get comingSoonMessage => 'Este ecrã está a ser construído.';

  @override
  String get loginSubtitle => 'Inicia sessão para continuar.';

  @override
  String get loginButton => 'Entrar';

  @override
  String get loginNoAccount => 'Ainda não tens conta?';

  @override
  String get loginCreateAccount => 'Criar conta';

  @override
  String get registerTitle => 'Criar conta';

  @override
  String get registerSubtitle => 'Demora só um minuto.';

  @override
  String get registerButton => 'Criar conta';

  @override
  String get registerHaveAccount => 'Já tens conta?';

  @override
  String get registerLogin => 'Entrar';

  @override
  String get fieldFirstName => 'Nome';

  @override
  String get fieldLastName => 'Apelido';

  @override
  String get fieldUsername => 'Nome de utilizador';

  @override
  String get fieldPassword => 'Palavra-passe';

  @override
  String get fieldConfirmPassword => 'Confirmar palavra-passe';

  @override
  String get passwordShow => 'Mostrar palavra-passe';

  @override
  String get passwordHide => 'Esconder palavra-passe';

  @override
  String get validationRequired => 'Obrigatório';

  @override
  String get validationUsername => '3 a 30 letras, números, . _ ou -';

  @override
  String get validationPasswordLength => 'Pelo menos 8 caracteres';

  @override
  String get validationPasswordsMatch => 'As palavras-passe não coincidem';

  @override
  String get logout => 'Terminar sessão';

  @override
  String get logoutConfirmTitle => 'Terminar sessão?';

  @override
  String get logoutConfirmMessage =>
      'Vais precisar do nome de utilizador e da palavra-passe para voltar a entrar.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get edit => 'Editar';

  @override
  String get saved => 'Guardado';

  @override
  String get profileBalanceTitle => 'Saldo atual';

  @override
  String get profileBalanceEdit => 'Editar saldo';

  @override
  String get profileBalanceSetupTitle => 'Qual é o teu saldo hoje?';

  @override
  String get profileBalanceSetupMessage =>
      'Escreve o dinheiro que tens agora. A partir daí atualiza-se sozinho com o teu rendimento, despesas e subscrições.';

  @override
  String get profileBalanceSetupButton => 'Definir saldo';

  @override
  String get profileBalanceAdjustNote => 'A diferença fica guardada no teu histórico como um ajuste.';

  @override
  String get profileIncomeTitle => 'Rendimento mensal';

  @override
  String get profileIncomeHint => 'Somado no dia 1 de cada mês';

  @override
  String get profileIncomeNone => 'Não definido';

  @override
  String get profileIncomeNote =>
      'O que ganhas por mês. É somado ao teu saldo no dia 1 de cada mês, a partir do próximo. Usa 0 para desativar.';

  @override
  String get profileDetailsTitle => 'Dados pessoais';

  @override
  String get profileSecurityTitle => 'Segurança';

  @override
  String get profileChangePassword => 'Alterar palavra-passe';

  @override
  String get profileChangePasswordNote => 'Os teus outros dispositivos vão terminar sessão.';

  @override
  String get profilePasswordChanged => 'Palavra-passe alterada';

  @override
  String get fieldAmount => 'Valor';

  @override
  String get fieldCurrentPassword => 'Palavra-passe atual';

  @override
  String get fieldNewPassword => 'Nova palavra-passe';

  @override
  String get fieldConfirmNewPassword => 'Confirmar nova palavra-passe';

  @override
  String get validationAmount => 'Escreve um valor válido, por exemplo 12,50';

  @override
  String get validationAmountTooLarge => 'O valor é demasiado alto';

  @override
  String get errorNetwork => 'Não foi possível contactar o servidor. Verifica a tua ligação.';

  @override
  String get errorTimeout => 'O servidor demorou demasiado a responder. Tenta novamente.';

  @override
  String get errorSessionExpired => 'A tua sessão expirou. Inicia sessão novamente.';

  @override
  String get errorUnknown => 'Algo correu mal. Tenta novamente.';

  @override
  String get errorInvalidCredentials => 'Nome de utilizador ou palavra-passe incorretos.';

  @override
  String get errorUsernameTaken => 'Este nome de utilizador já está a ser usado.';

  @override
  String get errorRegistrationDisabled => 'A criação de novas contas está desativada.';

  @override
  String get errorTooManyRequests => 'Demasiadas tentativas. Espera uns minutos e tenta novamente.';

  @override
  String get errorValidation => 'Alguns campos não são válidos.';

  @override
  String get errorInvalidCurrentPassword => 'A palavra-passe atual está errada.';

  @override
  String get retry => 'Tentar novamente';
}
