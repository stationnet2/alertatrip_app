import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _values = {
    'es': {
      'appName': 'AlertaTrip',
      'search': 'Buscar',
      'alerts': 'Alertas',
      'explore': 'Explorar',
      'profile': 'Perfil',
      'login': 'Iniciar sesion',
      'register': 'Crear cuenta',
      'email': 'Email',
      'password': 'Contrasena',
      'repeatPassword': 'Repetir contrasena',
      'enter': 'Ingresar',
      'createAccount': 'Crear cuenta',
      'noAccount': 'No tenes cuenta? Registrate',
      'haveAccount': 'Ya tenes cuenta? Iniciar sesion',
      'verifyEmail': 'Verifica tu email',
      'verifyEmailDesc': 'Te enviamos un link de verificacion. Abri tu correo, toca el link, y volve aca para continuar.',
      'spamWarning': 'Si no lo encontras, revisa la carpeta de Spam o Promociones.',
      'resendEmail': 'Reenviar email de verificacion',
      'continueText': 'Continuar',
      'logout': 'Cerrar sesion',
      'language': 'Idioma',
      'spanish': 'Espanol',
      'english': 'Ingles',
      'portuguese': 'Portugues',
      'needLoginForAlerts': 'Inicia sesion para guardar alertas',
      'needLoginForMyAlerts': 'Inicia sesion para ver tus alertas',
      'loginToContinue': 'Iniciar sesion para continuar',
      'cancel': 'Cancelar',
      'alertLimitReached': 'Llegaste al limite de alertas',
      'emailNotVerified': 'Debes verificar tu email antes de crear alertas',
      'guest': 'Invitado',
      'saveAlert': 'Guardar alerta',
      'loginToSave': 'Iniciar sesion para guardar',
      'priceTooLow': 'El precio minimo es USD 20',
    },
    'en': {
      'appName': 'AlertaTrip',
      'search': 'Search',
      'alerts': 'Alerts',
      'explore': 'Explore',
      'profile': 'Profile',
      'login': 'Log in',
      'register': 'Sign up',
      'email': 'Email',
      'password': 'Password',
      'repeatPassword': 'Repeat password',
      'enter': 'Log in',
      'createAccount': 'Sign up',
      'noAccount': "Don't have an account? Sign up",
      'haveAccount': 'Already have an account? Log in',
      'verifyEmail': 'Verify your email',
      'verifyEmailDesc': 'We sent you a verification link. Open your email, click the link, and come back here to continue.',
      'spamWarning': "If you can't find it, check your Spam or Promotions folder.",
      'resendEmail': 'Resend verification email',
      'continueText': 'Continue',
      'logout': 'Log out',
      'language': 'Language',
      'spanish': 'Spanish',
      'english': 'English',
      'portuguese': 'Portuguese',
      'needLoginForAlerts': 'Log in to save alerts',
      'needLoginForMyAlerts': 'Log in to view your alerts',
      'loginToContinue': 'Log in to continue',
      'cancel': 'Cancel',
      'alertLimitReached': 'You reached the alert limit',
      'emailNotVerified': 'You must verify your email before creating alerts',
      'guest': 'Guest',
      'saveAlert': 'Save alert',
      'loginToSave': 'Log in to save',
      'priceTooLow': 'Minimum price is USD 20',
    },
    'pt': {
      'appName': 'AlertaTrip',
      'search': 'Buscar',
      'alerts': 'Alertas',
      'explore': 'Explorar',
      'profile': 'Perfil',
      'login': 'Entrar',
      'register': 'Criar conta',
      'email': 'Email',
      'password': 'Senha',
      'repeatPassword': 'Repetir senha',
      'enter': 'Entrar',
      'createAccount': 'Criar conta',
      'noAccount': 'Nao tem conta? Cadastre-se',
      'haveAccount': 'Ja tem conta? Entrar',
      'verifyEmail': 'Verifique seu email',
      'verifyEmailDesc': 'Enviamos um link de verificacao. Abra seu email, clique no link e volte aqui para continuar.',
      'spamWarning': 'Se nao encontrar, verifique a pasta de Spam ou Promocoes.',
      'resendEmail': 'Reenviar email de verificacao',
      'continueText': 'Continuar',
      'logout': 'Sair',
      'language': 'Idioma',
      'spanish': 'Espanhol',
      'english': 'Ingles',
      'portuguese': 'Portugues',
      'needLoginForAlerts': 'Faca login para salvar alertas',
      'needLoginForMyAlerts': 'Faca login para ver seus alertas',
      'loginToContinue': 'Faca login para continuar',
      'cancel': 'Cancelar',
      'alertLimitReached': 'Voce atingiu o limite de alertas',
      'emailNotVerified': 'Voce deve verificar seu email antes de criar alertas',
      'guest': 'Visitante',
      'saveAlert': 'Salvar alerta',
      'loginToSave': 'Faca login para salvar',
      'priceTooLow': 'Preco minimo e USD 20',
    },
  };

  String _get(String key) => _values[locale.languageCode]?[key] ?? _values['es']![key]!;

  String get appName => _get('appName');
  String get search => _get('search');
  String get alerts => _get('alerts');
  String get explore => _get('explore');
  String get profile => _get('profile');
  String get login => _get('login');
  String get register => _get('register');
  String get email => _get('email');
  String get password => _get('password');
  String get repeatPassword => _get('repeatPassword');
  String get enter => _get('enter');
  String get createAccount => _get('createAccount');
  String get noAccount => _get('noAccount');
  String get haveAccount => _get('haveAccount');
  String get verifyEmail => _get('verifyEmail');
  String get verifyEmailDesc => _get('verifyEmailDesc');
  String get spamWarning => _get('spamWarning');
  String get resendEmail => _get('resendEmail');
  String get continueText => _get('continueText');
  String get logout => _get('logout');
  String get language => _get('language');
  String get spanish => _get('spanish');
  String get english => _get('english');
  String get portuguese => _get('portuguese');
  String get needLoginForAlerts => _get('needLoginForAlerts');
  String get needLoginForMyAlerts => _get('needLoginForMyAlerts');
  String get loginToContinue => _get('loginToContinue');
  String get cancel => _get('cancel');
  String get alertLimitReached => _get('alertLimitReached');
  String get emailNotVerified => _get('emailNotVerified');
  String get guest => _get('guest');
  String get saveAlert => _get('saveAlert');
  String get loginToSave => _get('loginToSave');
  String get priceTooLow => _get('priceTooLow');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['es', 'en', 'pt'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
