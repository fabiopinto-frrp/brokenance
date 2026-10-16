import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Brokenance'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get navSubscriptions;

  /// No description provided for @navExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get navExpenses;

  /// No description provided for @navOutings.
  ///
  /// In en, this message translates to:
  /// **'Outings & holidays'**
  String get navOutings;

  /// No description provided for @navLeisure.
  ///
  /// In en, this message translates to:
  /// **'Leisure'**
  String get navLeisure;

  /// No description provided for @navSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get navSavings;

  /// No description provided for @navGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get navGoals;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navOpenMenu.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get navOpenMenu;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Português'**
  String get languagePortuguese;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @comingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'This screen is being built.'**
  String get comingSoonMessage;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to continue.'**
  String get loginSubtitle;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginButton;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginNoAccount;

  /// No description provided for @loginCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get loginCreateAccount;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'It only takes a minute.'**
  String get registerSubtitle;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerButton;

  /// No description provided for @registerHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get registerHaveAccount;

  /// No description provided for @registerLogin.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get registerLogin;

  /// No description provided for @fieldFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get fieldFirstName;

  /// No description provided for @fieldLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get fieldLastName;

  /// No description provided for @fieldUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get fieldUsername;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @fieldConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get fieldConfirmPassword;

  /// No description provided for @passwordShow.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get passwordShow;

  /// No description provided for @passwordHide.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get passwordHide;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get validationRequired;

  /// No description provided for @validationUsername.
  ///
  /// In en, this message translates to:
  /// **'3 to 30 letters, numbers, . _ or -'**
  String get validationUsername;

  /// No description provided for @validationPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get validationPasswordLength;

  /// No description provided for @validationPasswordsMatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords don\'t match'**
  String get validationPasswordsMatch;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need your username and password to log in again.'**
  String get logoutConfirmMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @profileBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get profileBalanceTitle;

  /// No description provided for @profileBalanceEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit balance'**
  String get profileBalanceEdit;

  /// No description provided for @profileBalanceSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your balance today?'**
  String get profileBalanceSetupTitle;

  /// No description provided for @profileBalanceSetupMessage.
  ///
  /// In en, this message translates to:
  /// **'Type the money you have now. From then on it updates by itself with your income, expenses and subscriptions.'**
  String get profileBalanceSetupMessage;

  /// No description provided for @profileBalanceSetupButton.
  ///
  /// In en, this message translates to:
  /// **'Set balance'**
  String get profileBalanceSetupButton;

  /// No description provided for @profileBalanceAdjustNote.
  ///
  /// In en, this message translates to:
  /// **'The difference is saved in your history as an adjustment.'**
  String get profileBalanceAdjustNote;

  /// No description provided for @profileIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly income'**
  String get profileIncomeTitle;

  /// No description provided for @profileIncomeHint.
  ///
  /// In en, this message translates to:
  /// **'Added on the 1st of every month'**
  String get profileIncomeHint;

  /// No description provided for @profileIncomeNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get profileIncomeNone;

  /// No description provided for @profileIncomeNote.
  ///
  /// In en, this message translates to:
  /// **'What you earn per month. It is added to your balance on the 1st of every month, starting next month. Use 0 to turn it off.'**
  String get profileIncomeNote;

  /// No description provided for @profileDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get profileDetailsTitle;

  /// No description provided for @profileSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get profileSecurityTitle;

  /// No description provided for @profileChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get profileChangePassword;

  /// No description provided for @profileChangePasswordNote.
  ///
  /// In en, this message translates to:
  /// **'Your other devices will be logged out.'**
  String get profileChangePasswordNote;

  /// No description provided for @profilePasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get profilePasswordChanged;

  /// No description provided for @fieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get fieldAmount;

  /// No description provided for @fieldCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get fieldCurrentPassword;

  /// No description provided for @fieldNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get fieldNewPassword;

  /// No description provided for @fieldConfirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get fieldConfirmNewPassword;

  /// No description provided for @validationAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount, like 12.50'**
  String get validationAmount;

  /// No description provided for @validationAmountTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The amount is too large'**
  String get validationAmountTooLarge;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get fieldDate;

  /// No description provided for @fieldNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get fieldNote;

  /// No description provided for @transactionsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Spent this month'**
  String get transactionsThisMonth;

  /// No description provided for @expensesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get expensesEmptyTitle;

  /// No description provided for @expensesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add what you spend, like groceries or bills.'**
  String get expensesEmptyMessage;

  /// No description provided for @outingsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No outings or holidays yet'**
  String get outingsEmptyTitle;

  /// No description provided for @outingsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add dinners out, trips and holidays.'**
  String get outingsEmptyMessage;

  /// No description provided for @leisureEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No leisure yet'**
  String get leisureEmptyTitle;

  /// No description provided for @leisureEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add cinema, games, hobbies and the like.'**
  String get leisureEmptyMessage;

  /// No description provided for @expenseNew.
  ///
  /// In en, this message translates to:
  /// **'New expense'**
  String get expenseNew;

  /// No description provided for @expenseEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get expenseEdit;

  /// No description provided for @outingNew.
  ///
  /// In en, this message translates to:
  /// **'New outing'**
  String get outingNew;

  /// No description provided for @outingEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit outing'**
  String get outingEdit;

  /// No description provided for @leisureNew.
  ///
  /// In en, this message translates to:
  /// **'New leisure'**
  String get leisureNew;

  /// No description provided for @leisureEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit leisure'**
  String get leisureEdit;

  /// No description provided for @subscriptionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions yet'**
  String get subscriptionsEmptyTitle;

  /// No description provided for @subscriptionsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add the gym, Netflix or your insurance. They are charged automatically on their day.'**
  String get subscriptionsEmptyMessage;

  /// No description provided for @subscriptionNew.
  ///
  /// In en, this message translates to:
  /// **'New subscription'**
  String get subscriptionNew;

  /// No description provided for @subscriptionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit subscription'**
  String get subscriptionEdit;

  /// No description provided for @subscriptionsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Per month, on average'**
  String get subscriptionsPerMonth;

  /// No description provided for @subscriptionsMonthlyTotal.
  ///
  /// In en, this message translates to:
  /// **'Monthly: {amount}'**
  String subscriptionsMonthlyTotal(String amount);

  /// No description provided for @subscriptionsYearlyTotal.
  ///
  /// In en, this message translates to:
  /// **'Yearly: {amount}'**
  String subscriptionsYearlyTotal(String amount);

  /// No description provided for @periodMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get periodMonthly;

  /// No description provided for @periodYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get periodYearly;

  /// No description provided for @fieldBillingDay.
  ///
  /// In en, this message translates to:
  /// **'Day of the month'**
  String get fieldBillingDay;

  /// No description provided for @fieldBillingMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get fieldBillingMonth;

  /// No description provided for @subscriptionEveryMonth.
  ///
  /// In en, this message translates to:
  /// **'Every month on day {day}'**
  String subscriptionEveryMonth(int day);

  /// No description provided for @subscriptionEveryYear.
  ///
  /// In en, this message translates to:
  /// **'Every year on {date}'**
  String subscriptionEveryYear(String date);

  /// No description provided for @subscriptionNextCharge.
  ///
  /// In en, this message translates to:
  /// **'Next charge: {date}'**
  String subscriptionNextCharge(String date);

  /// No description provided for @subscriptionPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get subscriptionPaused;

  /// No description provided for @subscriptionActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get subscriptionActive;

  /// No description provided for @subscriptionShortMonthNote.
  ///
  /// In en, this message translates to:
  /// **'In months without that day, it is charged on the last day of the month. If the date is today, it is charged right away.'**
  String get subscriptionShortMonthNote;

  /// No description provided for @validationDayInMonth.
  ///
  /// In en, this message translates to:
  /// **'That month doesn\'t have this day'**
  String get validationDayInMonth;

  /// No description provided for @savingsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No savings target yet'**
  String get savingsEmptyTitle;

  /// No description provided for @savingsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Set how much you want to save per month.'**
  String get savingsEmptyMessage;

  /// No description provided for @savingsNew.
  ///
  /// In en, this message translates to:
  /// **'New savings target'**
  String get savingsNew;

  /// No description provided for @savingsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit savings target'**
  String get savingsEdit;

  /// No description provided for @savingsNewNote.
  ///
  /// In en, this message translates to:
  /// **'It becomes your current target. The previous one stays in the history.'**
  String get savingsNewNote;

  /// No description provided for @savingsCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'You want to save per month'**
  String get savingsCurrentLabel;

  /// No description provided for @savingsSince.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String savingsSince(String date);

  /// No description provided for @savingsHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get savingsHistory;

  /// No description provided for @fieldEffectiveDate.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fieldEffectiveDate;

  /// No description provided for @goalsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No goals yet'**
  String get goalsEmptyTitle;

  /// No description provided for @goalsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Save for something: a laptop, a trip, a car.'**
  String get goalsEmptyMessage;

  /// No description provided for @goalNew.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get goalNew;

  /// No description provided for @goalEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get goalEdit;

  /// No description provided for @fieldGoalName.
  ///
  /// In en, this message translates to:
  /// **'What are you saving for?'**
  String get fieldGoalName;

  /// No description provided for @fieldTarget.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get fieldTarget;

  /// No description provided for @fieldSaved.
  ///
  /// In en, this message translates to:
  /// **'Already saved'**
  String get fieldSaved;

  /// No description provided for @fieldDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline (optional)'**
  String get fieldDeadline;

  /// No description provided for @goalProgress.
  ///
  /// In en, this message translates to:
  /// **'{saved} of {target}'**
  String goalProgress(String saved, String target);

  /// No description provided for @goalRemaining.
  ///
  /// In en, this message translates to:
  /// **'{amount} to go'**
  String goalRemaining(String amount);

  /// No description provided for @goalCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get goalCompleted;

  /// No description provided for @goalMonthsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{About 1 month at your savings target} other{About {count} months at your savings target}}'**
  String goalMonthsLeft(int count);

  /// No description provided for @goalDeadline.
  ///
  /// In en, this message translates to:
  /// **'By {date}'**
  String goalDeadline(String date);

  /// No description provided for @goalAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to {name}'**
  String goalAddTitle(String name);

  /// No description provided for @goalAddNote.
  ///
  /// In en, this message translates to:
  /// **'Saved so far: {amount}'**
  String goalAddNote(String amount);

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server. Check your connection.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server took too long to answer. Try again.'**
  String get errorTimeout;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get errorSessionExpired;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorUnknown;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong username or password.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is already taken.'**
  String get errorUsernameTaken;

  /// No description provided for @errorRegistrationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Creating new accounts is turned off.'**
  String get errorRegistrationDisabled;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a few minutes and try again.'**
  String get errorTooManyRequests;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Some fields are not valid.'**
  String get errorValidation;

  /// No description provided for @errorInvalidCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'The current password is wrong.'**
  String get errorInvalidCurrentPassword;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
