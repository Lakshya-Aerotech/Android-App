import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const supportedLocales = [Locale('en'), Locale('te')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('en'));
  }

  String t(String key) {
    final languageCode = locale.languageCode;
    return _localizedValues[languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  String translateText(String text) => t(text);

  String get appTitle => t('Lakshya Aerotech');
  String get language => t('Language');
  String get english => t('English');
  String get telugu => t('Telugu');
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String tr(String key) => AppLocalizations.of(this).t(key);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const Map<String, Map<String, String>> _localizedValues = {
  'en': {
    'Lakshya Aerotech': 'Lakshya Aerotech',
    'Login': 'Login',
    'Logout': 'Logout',
    'Are you sure you want to log out?': 'Are you sure you want to log out?',
    'Cancel': 'Cancel',
    'Confirm': 'Confirm',
    'Profile': 'Profile',
    'Settings': 'Settings',
    'Language': 'Language',
    'English': 'English',
    'Telugu': 'Telugu',
    'Edit Profile': 'Edit Profile',
    'Change Password': 'Change Password',
    'App Information': 'App Information',
    'Account Information': 'Account Information',
    'Phone': 'Phone',
    'Email': 'Email',
    'Village': 'Village',
    'District': 'District',
    'Member Since': 'Member Since',
    'Dashboard': 'Dashboard',
    'Employees': 'Employees',
    'Bookings': 'Bookings',
    'Home': 'Home',
    'Jobs': 'Jobs',
    'History': 'History',
    'Overview': 'Overview',
    'Quick Actions': 'Quick Actions',
    'Recent Activity': 'Recent Activity',
    'View All': 'View All',
    'All Recent Activity': 'All Recent Activity',
    'No recent activity': 'No recent activity',
    'Activities will appear here when the team starts using the app.':
        'Activities will appear here when the team starts using the app.',
    'Execution Overview': 'Execution Overview',
    'Today': 'Today',
    'Pending': 'Pending',
    'Completed': 'Completed',
    'Acres': 'Acres',
    'Active Mission': 'Active Mission',
    'No active mission.': 'No active mission.',
    'Overall Pilot Stats': 'Overall Pilot Stats',
    'Total Flight Hours': 'Total Flight Hours',
    'Total Missions': 'Total Missions',
    'My Jobs': 'My Jobs',
    'Assigned': 'Assigned',
    'In Progress': 'In Progress',
    'No jobs found': 'No jobs found',
    'Check back later for new assignments.':
        'Check back later for new assignments.',
    'Precision Spraying': 'Precision Spraying',
    'Better Yield': 'Better Yield',
    'Healthy Fields': 'Healthy Fields',
    'Book Now': 'Book Now',
    'Book New Service': 'Book New Service',
    'My Bookings': 'My Bookings',
    'My Farms': 'My Farms',
    'Service History': 'Service History',
    'Upcoming Booking': 'Upcoming Booking',
    'No upcoming bookings': 'No upcoming bookings',
    'Book a Service Now': 'Book a Service Now',
    'Total Farms': 'Total Farms',
    'Total Bookings': 'Total Bookings',
    'Total Acres': 'Total Acres',
    'Pending Bookings': 'Pending Bookings',
    'Add Employee': 'Add Employee',
    'Manage Employees': 'Manage Employees',
    'Manage Drones': 'Manage Drones',
    'Analytics & Reports': 'Analytics & Reports',
    'Admin Details': 'Admin Details',
    'Employee ID': 'Employee ID',
    'Admin Level': 'Admin Level',
    'Created Date': 'Created Date',
    'Farm Activity': 'Farm Activity',
    'Execution Stats': 'Execution Stats',
    'Missions': 'Missions',
    'Flight Hours': 'Flight Hours',
    'Avg Rating': 'Avg Rating',
    'Assignment': 'Assignment',
    'Current Drone': 'Current Drone',
    'Operations': 'Operations',
    'Bookings Handled': 'Bookings Handled',
    'Assigned Region': 'Assigned Region',
    'N/A': 'N/A',
    'User Name': 'User Name',
    'Admin': 'Admin',
    'Farmer': 'Farmer',
    'Pilot': 'Pilot',
    'Operations Member': 'Operations Member',
    'Password reset link sent to your email.':
        'Password reset link sent to your email.',
    'Unauthorized employee.': 'Unauthorized employee.',
    'Your account has been disabled. Please contact the administrator.':
        'Your account has been disabled. Please contact the administrator.',
    'The email address is badly formatted.':
        'The email address is badly formatted.',
    'No user found with this email.': 'No user found with this email.',
    'Incorrect password.': 'Incorrect password.',
    'Invalid credentials. Please check your email and password.':
        'Invalid credentials. Please check your email and password.',
    'Too many attempts. Please try again later.':
        'Too many attempts. Please try again later.',
    'Network request failed. Please check your connection.':
        'Network request failed. Please check your connection.',
    'The phone number is invalid.': 'The phone number is invalid.',
    'The OTP entered is incorrect.': 'The OTP entered is incorrect.',
    'An unknown error occurred.': 'An unknown error occurred.',
    'Reviewed': 'Reviewed',
    'Pilot Assigned': 'Pilot Assigned',
    'Drone Assigned': 'Drone Assigned',
    'Accepted': 'Accepted',
    'En Route': 'En Route',
    'Arrived': 'Arrived',
    'Confirmed': 'Confirmed',
    'Closed': 'Closed',
    'Issue Reported': 'Issue Reported',
    'Cancelled': 'Cancelled',
  },
  'te': {
    'Lakshya Aerotech': 'లక్ష్య ఏరోటెక్',
    'Login': 'లాగిన్',
    'Logout': 'లాగ్ అవుట్',
    'Are you sure you want to log out?':
        'మీరు ఖచ్చితంగా లాగ్ అవుట్ చేయాలనుకుంటున్నారా?',
    'Cancel': 'రద్దు',
    'Confirm': 'నిర్ధారించు',
    'Profile': 'ప్రొఫైల్',
    'Settings': 'సెట్టింగ్స్',
    'Language': 'భాష',
    'English': 'ఆంగ్లం',
    'Telugu': 'తెలుగు',
    'Edit Profile': 'ప్రొఫైల్ సవరించు',
    'Change Password': 'పాస్వర్డ్ మార్చు',
    'App Information': 'యాప్ సమాచారం',
    'Account Information': 'ఖాతా సమాచారం',
    'Phone': 'ఫోన్',
    'Email': 'ఈమెయిల్',
    'Village': 'గ్రామం',
    'District': 'జిల్లా',
    'Member Since': 'సభ్యత్వం ప్రారంభం',
    'Dashboard': 'డ్యాష్ బోర్డ్',
    'Employees': 'ఉద్యోగులు',
    'Bookings': 'బుకింగ్స్',
    'Home': 'హోమ్',
    'Jobs': 'పనులు',
    'History': 'చరిత్ర',
    'Overview': 'అవలోకనం',
    'Quick Actions': 'త్వరిత చర్యలు',
    'Recent Activity': 'తాజా కార్యకలాపాలు',
    'View All': 'అన్నీ చూడండి',
    'All Recent Activity': 'అన్ని తాజా కార్యకలాపాలు',
    'No recent activity': 'తాజా కార్యకలాపాలు లేవు',
    'Activities will appear here when the team starts using the app.':
        'బృందం యాప్ ఉపయోగించడం ప్రారంభించినప్పుడు కార్యకలాపాలు ఇక్కడ కనిపిస్తాయి.',
    'Execution Overview': 'అమలు అవలోకనం',
    'Today': 'ఈ రోజు',
    'Pending': 'పెండింగ్',
    'Completed': 'పూర్తయింది',
    'Acres': 'ఎకరాలు',
    'Active Mission': 'క్రియాశీల మిషన్',
    'No active mission.': 'క్రియాశీల మిషన్ లేదు.',
    'Overall Pilot Stats': 'మొత్తం పైలట్ గణాంకాలు',
    'Total Flight Hours': 'మొత్తం విమాన గంటలు',
    'Total Missions': 'మొత్తం మిషన్లు',
    'My Jobs': 'నా పనులు',
    'Assigned': 'కేటాయించబడింది',
    'In Progress': 'ప్రగతిలో ఉంది',
    'No jobs found': 'పనులు కనబడలేదు',
    'Check back later for new assignments.':
        'కొత్త కేటాయింపుల కోసం తరువాత చూడండి.',
    'Precision Spraying': 'ఖచ్చితమైన స్ప్రేయింగ్',
    'Better Yield': 'మెరుగైన దిగుబడి',
    'Healthy Fields': 'ఆరోగ్యకరమైన పొలాలు',
    'Book Now': 'ఇప్పుడే బుక్ చేయండి',
    'Book New Service': 'కొత్త సేవ బుక్ చేయండి',
    'My Bookings': 'నా బుకింగ్స్',
    'My Farms': 'నా పొలాలు',
    'Service History': 'సేవల చరిత్ర',
    'Upcoming Booking': 'రాబోయే బుకింగ్',
    'No upcoming bookings': 'రాబోయే బుకింగ్స్ లేవు',
    'Book a Service Now': 'ఇప్పుడే సేవ బుక్ చేయండి',
    'Total Farms': 'మొత్తం పొలాలు',
    'Total Bookings': 'మొత్తం బుకింగ్స్',
    'Total Acres': 'మొత్తం ఎకరాలు',
    'Pending Bookings': 'పెండింగ్ బుకింగ్స్',
    'Add Employee': 'ఉద్యోగిని జోడించు',
    'Manage Employees': 'ఉద్యోగులను నిర్వహించు',
    'Manage Drones': 'డ్రోన్లను నిర్వహించు',
    'Analytics & Reports': 'విశ్లేషణలు మరియు నివేదికలు',
    'Admin Details': 'అడ్మిన్ వివరాలు',
    'Employee ID': 'ఉద్యోగి ఐడి',
    'Admin Level': 'అడ్మిన్ స్థాయి',
    'Created Date': 'సృష్టించిన తేదీ',
    'Farm Activity': 'పొలం కార్యకలాపాలు',
    'Execution Stats': 'అమలు గణాంకాలు',
    'Missions': 'మిషన్లు',
    'Flight Hours': 'విమాన గంటలు',
    'Avg Rating': 'సగటు రేటింగ్',
    'Assignment': 'కేటాయింపు',
    'Current Drone': 'ప్రస్తుత డ్రోన్',
    'Operations': 'ఆపరేషన్స్',
    'Bookings Handled': 'నిర్వహించిన బుకింగ్స్',
    'Assigned Region': 'కేటాయించిన ప్రాంతం',
    'N/A': 'వర్తించదు',
    'User Name': 'వినియోగదారు పేరు',
    'Admin': 'అడ్మిన్',
    'Farmer': 'రైతు',
    'Pilot': 'పైలట్',
    'Operations Member': 'ఆపరేషన్స్ సభ్యుడు',
    'Password reset link sent to your email.':
        'పాస్వర్డ్ రీసెట్ లింక్ మీ ఈమెయిల్ కు పంపబడింది.',
    'Unauthorized employee.': 'అనధికార ఉద్యోగి.',
    'Your account has been disabled. Please contact the administrator.':
        'మీ ఖాతా నిలిపివేయబడింది. దయచేసి నిర్వాహకుడిని సంప్రదించండి.',
    'The email address is badly formatted.':
        'ఈమెయిల్ చిరునామా సరైన ఫార్మాట్ లో లేదు.',
    'No user found with this email.': 'ఈ ఈమెయిల్ తో వినియోగదారు లేరు.',
    'Incorrect password.': 'తప్పు పాస్వర్డ్.',
    'Invalid credentials. Please check your email and password.':
        'చెల్లని వివరాలు. మీ ఈమెయిల్ మరియు పాస్వర్డ్ తనిఖీ చేయండి.',
    'Too many attempts. Please try again later.':
        'చాలా ప్రయత్నాలు చేశారు. దయచేసి తరువాత ప్రయత్నించండి.',
    'Network request failed. Please check your connection.':
        'నెట్ వర్క్ అభ్యర్థన విఫలమైంది. మీ కనెక్షన్ తనిఖీ చేయండి.',
    'The phone number is invalid.': 'ఫోన్ నంబర్ చెల్లదు.',
    'The OTP entered is incorrect.': 'నమోదు చేసిన ఓటిపి తప్పు.',
    'An unknown error occurred.': 'తెలియని లోపం జరిగింది.',
    'Reviewed': 'సమీక్షించబడింది',
    'Pilot Assigned': 'పైలట్ కేటాయించబడింది',
    'Drone Assigned': 'డ్రోన్ కేటాయించబడింది',
    'Accepted': 'అంగీకరించబడింది',
    'En Route': 'మార్గంలో ఉంది',
    'Arrived': 'చేరుకుంది',
    'Confirmed': 'నిర్ధారించబడింది',
    'Closed': 'ముగిసింది',
    'Issue Reported': 'సమస్య నివేదించబడింది',
    'Cancelled': 'రద్దు చేయబడింది',
  },
};
