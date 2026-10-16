// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Brokenance';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navProfile => 'Profile';

  @override
  String get navSubscriptions => 'Subscriptions';

  @override
  String get navExpenses => 'Expenses';

  @override
  String get navOutings => 'Outings & holidays';

  @override
  String get navLeisure => 'Leisure';

  @override
  String get navSavings => 'Savings';

  @override
  String get navGoals => 'Goals';

  @override
  String get navSettings => 'Settings';

  @override
  String get navOpenMenu => 'Open menu';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageSystem => 'System';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageEnglish => 'English';

  @override
  String get comingSoonTitle => 'Coming soon';

  @override
  String get comingSoonMessage => 'This screen is being built.';

  @override
  String get loginSubtitle => 'Log in to continue.';

  @override
  String get loginButton => 'Log in';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get loginCreateAccount => 'Create account';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerSubtitle => 'It only takes a minute.';

  @override
  String get registerButton => 'Create account';

  @override
  String get registerHaveAccount => 'Already have an account?';

  @override
  String get registerLogin => 'Log in';

  @override
  String get fieldFirstName => 'First name';

  @override
  String get fieldLastName => 'Last name';

  @override
  String get fieldUsername => 'Username';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldConfirmPassword => 'Confirm password';

  @override
  String get passwordShow => 'Show password';

  @override
  String get passwordHide => 'Hide password';

  @override
  String get validationRequired => 'Required';

  @override
  String get validationUsername => '3 to 30 letters, numbers, . _ or -';

  @override
  String get validationPasswordLength => 'At least 8 characters';

  @override
  String get validationPasswordsMatch => 'The passwords don\'t match';

  @override
  String get logout => 'Log out';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmMessage =>
      'You\'ll need your username and password to log in again.';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get saved => 'Saved';

  @override
  String get profileBalanceTitle => 'Current balance';

  @override
  String get profileBalanceEdit => 'Edit balance';

  @override
  String get profileBalanceSetupTitle => 'What\'s your balance today?';

  @override
  String get profileBalanceSetupMessage =>
      'Type the money you have now. From then on it updates by itself with your income, expenses and subscriptions.';

  @override
  String get profileBalanceSetupButton => 'Set balance';

  @override
  String get profileBalanceAdjustNote =>
      'The difference is saved in your history as an adjustment.';

  @override
  String get profileIncomeTitle => 'Monthly income';

  @override
  String get profileIncomeHint => 'Added on the 1st of every month';

  @override
  String get profileIncomeNone => 'Not set';

  @override
  String get profileIncomeNote =>
      'What you earn per month. It is added to your balance on the 1st of every month, starting next month. Use 0 to turn it off.';

  @override
  String get profileDetailsTitle => 'Personal details';

  @override
  String get profileSecurityTitle => 'Security';

  @override
  String get profileChangePassword => 'Change password';

  @override
  String get profileChangePasswordNote =>
      'Your other devices will be logged out.';

  @override
  String get profilePasswordChanged => 'Password changed';

  @override
  String get fieldAmount => 'Amount';

  @override
  String get fieldCurrentPassword => 'Current password';

  @override
  String get fieldNewPassword => 'New password';

  @override
  String get fieldConfirmNewPassword => 'Confirm new password';

  @override
  String get validationAmount => 'Enter a valid amount, like 12.50';

  @override
  String get validationAmountTooLarge => 'The amount is too large';

  @override
  String get add => 'Add';

  @override
  String get delete => 'Delete';

  @override
  String get deleted => 'Deleted';

  @override
  String get undo => 'Undo';

  @override
  String get clear => 'Clear';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldDate => 'Date';

  @override
  String get fieldNote => 'Note (optional)';

  @override
  String get transactionsThisMonth => 'Spent this month';

  @override
  String get expensesEmptyTitle => 'No expenses yet';

  @override
  String get expensesEmptyMessage =>
      'Add what you spend, like groceries or bills.';

  @override
  String get outingsEmptyTitle => 'No outings or holidays yet';

  @override
  String get outingsEmptyMessage => 'Add dinners out, trips and holidays.';

  @override
  String get leisureEmptyTitle => 'No leisure yet';

  @override
  String get leisureEmptyMessage => 'Add cinema, games, hobbies and the like.';

  @override
  String get expenseNew => 'New expense';

  @override
  String get expenseEdit => 'Edit expense';

  @override
  String get outingNew => 'New outing';

  @override
  String get outingEdit => 'Edit outing';

  @override
  String get leisureNew => 'New leisure';

  @override
  String get leisureEdit => 'Edit leisure';

  @override
  String get subscriptionsEmptyTitle => 'No subscriptions yet';

  @override
  String get subscriptionsEmptyMessage =>
      'Add the gym, Netflix or your insurance. They are charged automatically on their day.';

  @override
  String get subscriptionNew => 'New subscription';

  @override
  String get subscriptionEdit => 'Edit subscription';

  @override
  String get subscriptionsPerMonth => 'Per month, on average';

  @override
  String subscriptionsMonthlyTotal(String amount) {
    return 'Monthly: $amount';
  }

  @override
  String subscriptionsYearlyTotal(String amount) {
    return 'Yearly: $amount';
  }

  @override
  String get periodMonthly => 'Monthly';

  @override
  String get periodYearly => 'Yearly';

  @override
  String get fieldBillingDay => 'Day of the month';

  @override
  String get fieldBillingMonth => 'Month';

  @override
  String subscriptionEveryMonth(int day) {
    return 'Every month on day $day';
  }

  @override
  String subscriptionEveryYear(String date) {
    return 'Every year on $date';
  }

  @override
  String subscriptionNextCharge(String date) {
    return 'Next charge: $date';
  }

  @override
  String get subscriptionPaused => 'Paused';

  @override
  String get subscriptionActive => 'Active';

  @override
  String get subscriptionShortMonthNote =>
      'In months without that day, it is charged on the last day of the month. If the date is today, it is charged right away.';

  @override
  String get validationDayInMonth => 'That month doesn\'t have this day';

  @override
  String get savingsEmptyTitle => 'No savings target yet';

  @override
  String get savingsEmptyMessage => 'Set how much you want to save per month.';

  @override
  String get savingsNew => 'New savings target';

  @override
  String get savingsEdit => 'Edit savings target';

  @override
  String get savingsNewNote =>
      'It becomes your current target. The previous one stays in the history.';

  @override
  String get savingsCurrentLabel => 'You want to save per month';

  @override
  String savingsSince(String date) {
    return 'Since $date';
  }

  @override
  String get savingsHistory => 'History';

  @override
  String get fieldEffectiveDate => 'From';

  @override
  String get goalsEmptyTitle => 'No goals yet';

  @override
  String get goalsEmptyMessage =>
      'Save for something: a laptop, a trip, a car.';

  @override
  String get goalNew => 'New goal';

  @override
  String get goalEdit => 'Edit goal';

  @override
  String get fieldGoalName => 'What are you saving for?';

  @override
  String get fieldTarget => 'Target amount';

  @override
  String get fieldSaved => 'Already saved';

  @override
  String get fieldDeadline => 'Deadline (optional)';

  @override
  String goalProgress(String saved, String target) {
    return '$saved of $target';
  }

  @override
  String goalRemaining(String amount) {
    return '$amount to go';
  }

  @override
  String get goalCompleted => 'Completed';

  @override
  String goalMonthsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'About $count months at your savings target',
      one: 'About 1 month at your savings target',
    );
    return '$_temp0';
  }

  @override
  String goalDeadline(String date) {
    return 'By $date';
  }

  @override
  String goalAddTitle(String name) {
    return 'Add to $name';
  }

  @override
  String goalAddNote(String amount) {
    return 'Saved so far: $amount';
  }

  @override
  String get errorNetwork => 'Can\'t reach the server. Check your connection.';

  @override
  String get errorTimeout => 'The server took too long to answer. Try again.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please log in again.';

  @override
  String get errorUnknown => 'Something went wrong. Try again.';

  @override
  String get errorInvalidCredentials => 'Wrong username or password.';

  @override
  String get errorUsernameTaken => 'This username is already taken.';

  @override
  String get errorRegistrationDisabled =>
      'Creating new accounts is turned off.';

  @override
  String get errorTooManyRequests =>
      'Too many attempts. Wait a few minutes and try again.';

  @override
  String get errorValidation => 'Some fields are not valid.';

  @override
  String get errorInvalidCurrentPassword => 'The current password is wrong.';

  @override
  String get retry => 'Try again';
}
