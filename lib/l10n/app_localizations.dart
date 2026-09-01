import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
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
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

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
    Locale('es'),
    Locale('fr'),
    Locale('pt'),
    Locale('ru')
  ];

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

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get somethingWentWrong;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSounds.
  ///
  /// In en, this message translates to:
  /// **'Sounds'**
  String get navSounds;

  /// No description provided for @navBreathing.
  ///
  /// In en, this message translates to:
  /// **'Breathing'**
  String get navBreathing;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordQ.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordQ;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @logInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Log In with Apple'**
  String get logInWithApple;

  /// No description provided for @logInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Log In with Google'**
  String get logInWithGoogle;

  /// No description provided for @logInWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Log In with Email'**
  String get logInWithEmail;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log In'**
  String get alreadyHaveAccount;

  /// No description provided for @firstTimeHere.
  ///
  /// In en, this message translates to:
  /// **'First time here? Sign Up'**
  String get firstTimeHere;

  /// No description provided for @orLogInWith.
  ///
  /// In en, this message translates to:
  /// **'or Log In with'**
  String get orLogInWith;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: August 2, 2025'**
  String get lastUpdated;

  /// No description provided for @enterBothEmailAndPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter both email and password'**
  String get enterBothEmailAndPassword;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get invalidEmailFormat;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get enterYourEmail;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent to your email'**
  String get resetLinkSent;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed'**
  String get googleSignInFailed;

  /// No description provided for @appleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed'**
  String get appleSignInFailed;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get incorrectPassword;

  /// No description provided for @noUserForEmail.
  ///
  /// In en, this message translates to:
  /// **'No user found for this email'**
  String get noUserForEmail;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long'**
  String get passwordTooShort;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get fillAllFields;

  /// No description provided for @signInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was cancelled.'**
  String get signInCancelled;

  /// No description provided for @enterPasswordToContinue.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to continue.'**
  String get enterPasswordToContinue;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password.'**
  String get wrongPassword;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @couldNotOpenEmail.
  ///
  /// In en, this message translates to:
  /// **'Could not open email client'**
  String get couldNotOpenEmail;

  /// No description provided for @userNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'User not loaded'**
  String get userNotLoaded;

  /// No description provided for @moodIndex.
  ///
  /// In en, this message translates to:
  /// **'Mood index'**
  String get moodIndex;

  /// No description provided for @whatDoYouFeelNow.
  ///
  /// In en, this message translates to:
  /// **'What do you feel now?'**
  String get whatDoYouFeelNow;

  /// No description provided for @couldNotLoadData.
  ///
  /// In en, this message translates to:
  /// **'Could not load your data. Check your connection.'**
  String get couldNotLoadData;

  /// No description provided for @recordMood.
  ///
  /// In en, this message translates to:
  /// **'Record Mood'**
  String get recordMood;

  /// No description provided for @moodRecord.
  ///
  /// In en, this message translates to:
  /// **'Mood Record'**
  String get moodRecord;

  /// No description provided for @addTrigger.
  ///
  /// In en, this message translates to:
  /// **'Add Trigger'**
  String get addTrigger;

  /// No description provided for @triggerHint.
  ///
  /// In en, this message translates to:
  /// **'work, family etc.'**
  String get triggerHint;

  /// No description provided for @addOptionalNote.
  ///
  /// In en, this message translates to:
  /// **'Add optional note...'**
  String get addOptionalNote;

  /// No description provided for @addTriggerButton.
  ///
  /// In en, this message translates to:
  /// **'+ Add trigger'**
  String get addTriggerButton;

  /// No description provided for @triggersLabel.
  ///
  /// In en, this message translates to:
  /// **'Triggers:'**
  String get triggersLabel;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note:'**
  String get noteLabel;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get levelLabel;

  /// No description provided for @indexLabel.
  ///
  /// In en, this message translates to:
  /// **'Index:'**
  String get indexLabel;

  /// No description provided for @swipeOrTapToAdjust.
  ///
  /// In en, this message translates to:
  /// **'Swipe or tap to adjust'**
  String get swipeOrTapToAdjust;

  /// No description provided for @tapToRecord.
  ///
  /// In en, this message translates to:
  /// **'Tap to record'**
  String get tapToRecord;

  /// No description provided for @holdForOptions.
  ///
  /// In en, this message translates to:
  /// **'Hold for options'**
  String get holdForOptions;

  /// No description provided for @deleteRecordQ.
  ///
  /// In en, this message translates to:
  /// **'Delete record?'**
  String get deleteRecordQ;

  /// No description provided for @deleteRecordBody.
  ///
  /// In en, this message translates to:
  /// **'This action will permanently delete this Mood Record'**
  String get deleteRecordBody;

  /// No description provided for @failedToSaveMood.
  ///
  /// In en, this message translates to:
  /// **'Failed to save mood'**
  String get failedToSaveMood;

  /// No description provided for @savedLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedLabel;

  /// No description provided for @deletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deletedLabel;

  /// No description provided for @moodAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Mood Analysis'**
  String get moodAnalysis;

  /// No description provided for @moodCurveHourly.
  ///
  /// In en, this message translates to:
  /// **'Mood curve (Hourly)'**
  String get moodCurveHourly;

  /// No description provided for @moodIndexDaily.
  ///
  /// In en, this message translates to:
  /// **'Mood index (Daily)'**
  String get moodIndexDaily;

  /// No description provided for @calculatedAsAverage.
  ///
  /// In en, this message translates to:
  /// **'Calculated as the average of the last 7 days'**
  String get calculatedAsAverage;

  /// No description provided for @addAMoodRecord.
  ///
  /// In en, this message translates to:
  /// **'Add a mood record'**
  String get addAMoodRecord;

  /// No description provided for @couldNotLoadRecords.
  ///
  /// In en, this message translates to:
  /// **'Could not load your records. Check your connection.'**
  String get couldNotLoadRecords;

  /// No description provided for @wellnessNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get wellnessNoData;

  /// No description provided for @wellnessPeak.
  ///
  /// In en, this message translates to:
  /// **'Peak'**
  String get wellnessPeak;

  /// No description provided for @wellnessHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get wellnessHigh;

  /// No description provided for @wellnessAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get wellnessAverage;

  /// No description provided for @wellnessLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get wellnessLow;

  /// No description provided for @wellnessBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get wellnessBottom;

  /// No description provided for @suggestionNoData.
  ///
  /// In en, this message translates to:
  /// **'Add a mood record'**
  String get suggestionNoData;

  /// No description provided for @suggestionPeak.
  ///
  /// In en, this message translates to:
  /// **'Perfect, ride the wave!'**
  String get suggestionPeak;

  /// No description provided for @suggestionHigh.
  ///
  /// In en, this message translates to:
  /// **'Looking good, respect!'**
  String get suggestionHigh;

  /// No description provided for @suggestionAverage.
  ///
  /// In en, this message translates to:
  /// **'Not bad, but kick it up!'**
  String get suggestionAverage;

  /// No description provided for @suggestionLow.
  ///
  /// In en, this message translates to:
  /// **'Take a deep breath.'**
  String get suggestionLow;

  /// No description provided for @suggestionBottom.
  ///
  /// In en, this message translates to:
  /// **'Caution! Need a reset.'**
  String get suggestionBottom;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// No description provided for @deleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Delete Profile'**
  String get deleteProfile;

  /// No description provided for @deleteProfileQ.
  ///
  /// In en, this message translates to:
  /// **'Delete profile?'**
  String get deleteProfileQ;

  /// No description provided for @deleteProfileBody.
  ///
  /// In en, this message translates to:
  /// **'This action will permanently delete your profile and all your data. Are you sure you want to continue?'**
  String get deleteProfileBody;

  /// No description provided for @deletingYourData.
  ///
  /// In en, this message translates to:
  /// **'Deleting your data...'**
  String get deletingYourData;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

  /// No description provided for @birthDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Birth Date'**
  String get birthDateLabel;

  /// No description provided for @confirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmYourPassword;

  /// No description provided for @cropPhoto.
  ///
  /// In en, this message translates to:
  /// **'Crop Photo'**
  String get cropPhoto;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// No description provided for @couldNotUploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Could not upload the photo. Try again.'**
  String get couldNotUploadPhoto;

  /// No description provided for @couldNotDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the account. Try again.'**
  String get couldNotDeleteAccount;

  /// No description provided for @purring.
  ///
  /// In en, this message translates to:
  /// **'Purring'**
  String get purring;

  /// No description provided for @purringSubtitle.
  ///
  /// In en, this message translates to:
  /// **'plays while the player is empty'**
  String get purringSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @recentlyPlayed.
  ///
  /// In en, this message translates to:
  /// **'Recently played'**
  String get recentlyPlayed;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @myMixes.
  ///
  /// In en, this message translates to:
  /// **'My mixes'**
  String get myMixes;

  /// No description provided for @searchSounds.
  ///
  /// In en, this message translates to:
  /// **'Search sounds'**
  String get searchSounds;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'NOW PLAYING'**
  String get nowPlaying;

  /// No description provided for @addASound.
  ///
  /// In en, this message translates to:
  /// **'Add a sound'**
  String get addASound;

  /// No description provided for @addToMix.
  ///
  /// In en, this message translates to:
  /// **'Add to mix'**
  String get addToMix;

  /// No description provided for @inMix.
  ///
  /// In en, this message translates to:
  /// **'in mix'**
  String get inMix;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimer;

  /// No description provided for @sleepTimerOff.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleepTimerOff;

  /// No description provided for @saveMix.
  ///
  /// In en, this message translates to:
  /// **'Save mix'**
  String get saveMix;

  /// No description provided for @saveMixHint.
  ///
  /// In en, this message translates to:
  /// **'Name is filled in from the layers — change it if you like'**
  String get saveMixHint;

  /// No description provided for @layersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} layers'**
  String layersCount(int count);

  /// No description provided for @noSoundsFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get noSoundsFound;

  /// No description provided for @mixReplaced.
  ///
  /// In en, this message translates to:
  /// **'Mix replaced'**
  String get mixReplaced;

  /// No description provided for @noMixesYet.
  ///
  /// In en, this message translates to:
  /// **'No saved mixes yet'**
  String get noMixesYet;

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing in favorites yet'**
  String get noFavoritesYet;

  /// No description provided for @noRecentYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing played yet'**
  String get noRecentYet;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @phaseInhale.
  ///
  /// In en, this message translates to:
  /// **'Inhale'**
  String get phaseInhale;

  /// No description provided for @phaseHold.
  ///
  /// In en, this message translates to:
  /// **'Hold'**
  String get phaseHold;

  /// No description provided for @phaseExhale.
  ///
  /// In en, this message translates to:
  /// **'Exhale'**
  String get phaseExhale;

  /// No description provided for @phaseWait.
  ///
  /// In en, this message translates to:
  /// **'Wait'**
  String get phaseWait;

  /// No description provided for @getReady.
  ///
  /// In en, this message translates to:
  /// **'Get ready'**
  String get getReady;

  /// No description provided for @howLong.
  ///
  /// In en, this message translates to:
  /// **'How long'**
  String get howLong;

  /// No description provided for @startPractice.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startPractice;

  /// No description provided for @finishPractice.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishPractice;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @vibrationHint.
  ///
  /// In en, this message translates to:
  /// **'marks every phase and counts the holds'**
  String get vibrationHint;

  /// No description provided for @keepSoundPlaying.
  ///
  /// In en, this message translates to:
  /// **'Keep the sound playing'**
  String get keepSoundPlaying;

  /// No description provided for @keepSoundHint.
  ///
  /// In en, this message translates to:
  /// **'quieter, under the breathing'**
  String get keepSoundHint;

  /// No description provided for @endsOnExhale.
  ///
  /// In en, this message translates to:
  /// **'practice ends on a full exhale'**
  String get endsOnExhale;

  /// No description provided for @sessionProgress.
  ///
  /// In en, this message translates to:
  /// **'{time} left · cycle {current} of {total}'**
  String sessionProgress(String time, int current, int total);

  /// No description provided for @soundKeepsPlaying.
  ///
  /// In en, this message translates to:
  /// **'{title} keeps playing'**
  String soundKeepsPlaying(String title);

  /// No description provided for @wellDone.
  ///
  /// In en, this message translates to:
  /// **'Well done'**
  String get wellDone;

  /// No description provided for @oneMoreRound.
  ///
  /// In en, this message translates to:
  /// **'One more round'**
  String get oneMoreRound;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @breathingStats.
  ///
  /// In en, this message translates to:
  /// **'Breathing'**
  String get breathingStats;

  /// No description provided for @statBestStreak.
  ///
  /// In en, this message translates to:
  /// **'best streak'**
  String get statBestStreak;

  /// No description provided for @noPracticesYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get noPracticesYet;

  /// No description provided for @cyclesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} cycle} other{{count} cycles}}'**
  String cyclesCount(int count);

  /// No description provided for @statStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{day in a row} other{days in a row}}'**
  String statStreakLabel(int count);

  /// No description provided for @statSessionsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{practice} other{practices}}'**
  String statSessionsLabel(int count);

  /// No description provided for @totalTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'total time'**
  String get totalTimeLabel;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr', 'pt', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'es':
      return AppL10nEs();
    case 'fr':
      return AppL10nFr();
    case 'pt':
      return AppL10nPt();
    case 'ru':
      return AppL10nRu();
  }

  throw FlutterError(
      'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
