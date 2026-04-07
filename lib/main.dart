import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cryptography/cryptography.dart';
import 'package:mime/mime.dart';

const _supabaseUrl = String.fromEnvironment(
  "SUPABASE_URL",
  defaultValue: "",
);
const _supabaseAnonKey = String.fromEnvironment(
  "SUPABASE_ANON_KEY",
  defaultValue: "",
);

const _chatCryptoSecret = String.fromEnvironment(
  "CHAT_CRYPTO_SECRET",
  defaultValue: "",
);
const _ru = "ru";
const _kk = 'kk';

const _i18n = <String, Map<String, String>>{
  'app_name': {
    _ru: 'PMessenger',
    _kk: 'PMessenger',
  },
  'subtitle': {
    _ru: 'быстрый чат без лишнего',
    _kk: 'достарга арналған мессенджер',
  },
  'email': {
    _ru: 'Логин',
    _kk: 'Логин',
  },
  'alias': {
    _ru: 'Псевдоним',
    _kk: 'Лақап ат',
  },
  'password': {
    _ru: 'Пароль',
    _kk: 'Құпия сөз',
  },
  'your_name': {
    _ru: 'Твое имя',
    _kk: 'Атың',
  },
  'login': {
    _ru: 'Войти',
    _kk: 'Кіру',
  },
  'register': {
    _ru: 'Регистрация',
    _kk: 'Тіркелу',
  },
  'create_account': {
    _ru: 'Создать аккаунт',
    _kk: 'Аккаунт ашу',
  },
  'no_account': {
    _ru: 'Нет аккаунта? Регистрация',
    _kk: 'Аккаунт жоқ па? Тіркелу',
  },
  'has_account': {
    _ru: 'Уже есть аккаунт? Вход',
    _kk: 'Аккаунт бар ма? Кіру',
  },
  'friends': {
    _ru: 'Друзья',
    _kk: 'Достар',
  },
  'find_friend': {
    _ru: 'Найти друга',
    _kk: 'Досты табу',
  },
  'empty_friends': {
    _ru: 'Пока никого нет',
    _kk: 'Әзірге ешкім жоқ',
  },
  'ask_friends': {
    _ru: 'Попроси друзей зарегистрироваться.',
    _kk: 'Достарыңды тіркелуге шақыр.',
  },
  'message_hint': {
    _ru: 'Напиши сообщение...',
    _kk: 'Хабарлама жаз...',
  },
  'settings': {
    _ru: 'Настройки',
    _kk: 'Баптаулар',
  },
  'language': {
    _ru: 'Язык интерфейса',
    _kk: 'Интерфейс тілі',
  },
  'russian': {
    _ru: 'Русский',
    _kk: 'Орыс тілі',
  },
  'kazakh': {
    _ru: 'Казахский',
    _kk: 'Қазақ тілі',
  },
  'liquid_glass': {
    _ru: 'Liquid Glass',
    _kk: 'Liquid Glass',
  },
  'liquid_glass_desc': {
    _ru: 'Световые блики и стеклянные панели',
    _kk: 'Жарық шағылысуы мен шыны панельдер',
  },
  'blur': {
    _ru: 'Блюр',
    _kk: 'Блюр',
  },
  'blur_desc': {
    _ru: 'Размытие заднего фона карточек',
    _kk: 'Карточка артқы фонын бұлдырату',
  },
  'transparency': {
    _ru: 'Прозрачность',
    _kk: 'Мөлдірлік',
  },
  'transparency_desc': {
    _ru: 'Полупрозрачный интерфейс',
    _kk: 'Жартылай мөлдір интерфейс',
  },
  'logout': {
    _ru: 'Выход',
    _kk: 'Шығу',
  },
  'auth_created': {
    _ru: 'Аккаунт создан. Теперь заходи по логину и паролю.',
    _kk: 'Аккаунт ашылды. Енді логин мен құпия сөзбен кір.',
  },
  'dns_help': {
    _ru: 'Ошибка сети/DNS. Проверь интернет и Private DNS на телефоне.',
    _kk: 'Желі/DNS қатесі. Телефондағы интернет пен Private DNS тексер.',
  },
  'over_rate': {
    _ru: 'Лимит регистрации на Supabase временно достигнут. Попробуй позже или войди в уже созданный аккаунт.',
    _kk: 'Supabase тіркелу лимиті уақытша бітті. Кейінірек қайтала немесе бар аккаунтқа кір.',
  },

  'copy': {
    _ru: 'Копировать',
    _kk: 'Көшіру',
  },
  'delete': {
    _ru: 'Удалить',
    _kk: 'Жою',
  },
  'online': {
    _ru: 'в сети',
    _kk: 'желіде',
  },
  'last_seen': {
    _ru: 'был(а) ',
    _kk: 'соңғы рет ',
  },
  'name_optional': {
    _ru: 'Имя (необязательно)',
    _kk: 'Аты (міндетті емес)',
  },
};

String tr(String lang, String key) => _i18n[key]?[lang] ?? key;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  final prefs = await SharedPreferences.getInstance();
  final settings = AppSettings.load(prefs);
  runApp(PMessengerApp(settings: settings, prefs: prefs));
}

SupabaseClient get _db => Supabase.instance.client;

class MessageCrypto {
  MessageCrypto(this.secret);

  final String secret;
  static final AesGcm _algo = AesGcm.with256bits();

  final _rand = Random.secure();

  Future<SecretKey> _keyForConversation(String conversationId) async {
    final seed = utf8.encode('${secret}::${conversationId}');
    final hash = await Sha256().hash(seed);
    return SecretKey(hash.bytes);
  }

  List<int> _nonce() => List<int>.generate(12, (_) => _rand.nextInt(256));

  Future<String> encryptText(String plainText, {required String conversationId}) async {
    final encrypted = await _algo.encrypt(
      utf8.encode(plainText),
      secretKey: await _keyForConversation(conversationId),
      nonce: _nonce(),
    );
    final payload = Uint8List.fromList([
      ...encrypted.cipherText,
      ...encrypted.mac.bytes,
    ]);
    return 'enc:v1:${base64Encode(encrypted.nonce)}:${base64Encode(payload)}';
  }

  Future<String> decryptText(String encryptedText, {required String conversationId}) async {
    if (!encryptedText.startsWith('enc:v1:')) return encryptedText;

    final parts = encryptedText.split(':');
    if (parts.length < 4) return encryptedText;

    try {
      final nonce = base64Decode(parts[2]);
      final payload = base64Decode(parts.sublist(3).join(':'));
      if (payload.length < 16) return encryptedText;

      final cipherText = payload.sublist(0, payload.length - 16);
      final mac = Mac(payload.sublist(payload.length - 16));

      final clear = await _algo.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: mac),
        secretKey: await _keyForConversation(conversationId),
      );
      return utf8.decode(clear);
    } catch (_) {
      return encryptedText;
    }
  }
}
class AppSettings {
  AppSettings({
    required this.lang,
    required this.liquidGlass,
    required this.blur,
    required this.transparency,
  });

  final String lang;
  final bool liquidGlass;
  final bool blur;
  final bool transparency;

  AppSettings copyWith({
    String? lang,
    bool? liquidGlass,
    bool? blur,
    bool? transparency,
  }) {
    return AppSettings(
      lang: lang ?? this.lang,
      liquidGlass: liquidGlass ?? this.liquidGlass,
      blur: blur ?? this.blur,
      transparency: transparency ?? this.transparency,
    );
  }

  static AppSettings load(SharedPreferences prefs) {
    return AppSettings(
      lang: prefs.getString('lang') ?? _ru,
      liquidGlass: prefs.getBool('liquidGlass') ?? true,
      blur: prefs.getBool('blur') ?? true,
      transparency: prefs.getBool('transparency') ?? true,
    );
  }
}

class PMessengerApp extends StatefulWidget {
  const PMessengerApp({super.key, required this.settings, required this.prefs});

  final AppSettings settings;
  final SharedPreferences prefs;

  @override
  State<PMessengerApp> createState() => _PMessengerAppState();
}

class _PMessengerAppState extends State<PMessengerApp> {
  late AppSettings settings;

  @override
  void initState() {
    super.initState();
    settings = widget.settings;
  }

  Future<void> _updateSettings(AppSettings next) async {
    setState(() => settings = next);
    await widget.prefs.setString('lang', next.lang);
    await widget.prefs.setBool('liquidGlass', next.liquidGlass);
    await widget.prefs.setBool('blur', next.blur);
    await widget.prefs.setBool('transparency', next.transparency);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PMessenger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Monocraft',
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF28C4D9),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF070A12),
        useMaterial3: true,
      ),
      home: EntryGate(
        settings: settings,
        onSettingsChanged: _updateSettings,
      ),
    );
  }
}

class EntryGate extends StatelessWidget {
  const EntryGate({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final AppSettings settings;
  final Future<void> Function(AppSettings next) onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _db.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = _db.auth.currentUser;
        if (user == null) {
          return AuthPage(settings: settings);
        }
        return FriendsPage(
          settings: settings,
          onSettingsChanged: onSettingsChanged,
        );
      },
    );
  }
}

class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.settings,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = 22,
  });

  final AppSettings settings;
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final alpha = settings.transparency ? 0.18 : 0.95;
    final sigma = settings.blur ? 14.0 : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: const SizedBox.expand(),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(alpha),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.white.withOpacity(0.20)),
              boxShadow: settings.liquidGlass
                  ? [
                      BoxShadow(
                        blurRadius: 24,
                        spreadRadius: 1,
                        offset: const Offset(0, 10),
                        color: const Color(0xFF00D4FF).withOpacity(0.15),
                      ),
                    ]
                  : null,
            ),
            child: Padding(padding: padding, child: child),
          ),
          if (settings.liquidGlass)
            Positioned(
              top: -16,
              left: -30,
              right: -20,
              child: IgnorePointer(
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.34),
                        Colors.white.withOpacity(0.0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _login = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _isLogin = true;
  bool _busy = false;
  bool _obscurePassword = true;

  String _normalizeLogin(String login) {
    return login.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_.-]'), '');
  }

  String _toAuthEmail(String login) {
    final normalized = _normalizeLogin(login);
    return '$normalized@pmessenger.local';
  }

  Future<void> _syncProfile({required String login, required String displayName}) async {
    final user = _db.auth.currentUser;
    if (user == null) return;
    await _db.rpc('upsert_profile', params: {'p_user': user.id});
    await _db
        .from('profiles')
        .update({
          'username': _normalizeLogin(login),
          'full_name': displayName,
          'last_seen': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id);
  }

  Future<void> _submit() async {
    final loginRaw = _login.text.trim();
    if (loginRaw.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Логин должен быть минимум 3 символа')),
      );
      return;
    }

    if (_password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароль должен быть минимум 6 символов')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      if (_isLogin) {
        await _db.auth.signInWithPassword(
          email: _toAuthEmail(_login.text),
          password: _password.text,
        );
        await _syncProfile(
          login: _login.text,
          displayName: _name.text.trim().isEmpty ? _login.text.trim() : _name.text.trim(),
        );
      } else {
        await _db.auth.signUp(
          email: _toAuthEmail(_login.text),
          password: _password.text,
          data: {
            'full_name': _name.text.trim().isEmpty ? _login.text.trim() : _name.text.trim(),
          },
        );
        await _syncProfile(
          login: _login.text,
          displayName: _name.text.trim().isEmpty ? _login.text.trim() : _name.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr(widget.settings.lang, 'auth_created'))));
      }
    } catch (e) {
      if (!mounted) return;
      final text = e.toString();
      final lower = text.toLowerCase();
      String message = text;
      if (lower.contains('over_email_send_rate_limit') || lower.contains('statuscode: 429')) {
        message = tr(widget.settings.lang, 'over_rate');
      } else if (text.contains('Failed host lookup')) {
        message = '${text}\n${tr(widget.settings.lang, 'dns_help')}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.settings.lang;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF070A12), Color(0xFF0D1B2A), Color(0xFF11283A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Glass(
                settings: widget.settings,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.forum_rounded, size: 48, color: Color(0xFF28C4D9)),
                    const SizedBox(height: 10),
                    Text(
                      tr(lang, 'app_name'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr(lang, 'subtitle'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: Text(tr(lang, 'login')),
                          selected: _isLogin,
                          onSelected: _busy ? null : (_) => setState(() => _isLogin = true),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(tr(lang, 'register')),
                          selected: !_isLogin,
                          onSelected: _busy ? null : (_) => setState(() => _isLogin = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (!_isLogin)
                      TextField(
                        controller: _name,
                        decoration: InputDecoration(labelText: tr(lang, 'alias')),
                      ),
                    if (!_isLogin) const SizedBox(height: 10),
                    TextField(
                      controller: _login,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: tr(lang, 'email'),
                        prefixIcon: const Icon(Icons.alternate_email_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: tr(lang, 'password'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _busy ? null : _submit,
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward_rounded),
                      label: Text(_isLogin ? tr(lang, 'login') : tr(lang, 'create_account')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FriendsPage extends StatefulWidget {
  const FriendsPage({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  final AppSettings settings;
  final Future<void> Function(AppSettings next) onSettingsChanged;

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _friends = const [];
  List<Map<String, dynamic>> _suggested = const [];
  List<Map<String, dynamic>> _groups = const [];
  bool _loading = true;
  int _tab = 0; // 0 friends, 1 groups

  @override
  void initState() {
    super.initState();
    _touchLastSeen();
    _loadAll();
  }

  Future<void> _touchLastSeen() async {
    final current = _db.auth.currentUser;
    if (current == null) return;
    await _db
        .from('profiles')
        .update({'last_seen': DateTime.now().toUtc().toIso8601String()})
        .eq('id', current.id);
  }

  String _presenceText(Map<String, dynamic> friend) {
    final lang = widget.settings.lang;
    final raw = friend['last_seen'];
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return '';
    final delta = DateTime.now().toUtc().difference(dt.toUtc());
    if (delta.inMinutes <= 2) return tr(lang, 'online');
    return '${tr(lang, 'last_seen')}${timeago.format(dt.toLocal(), locale: 'en_short')}';
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadFriends(), _loadGroups(), _loadSuggested()]);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _loadFriends() async {
    final current = _db.auth.currentUser;
    if (current == null) return;
    await _touchLastSeen();

    final rows = await _db.rpc('get_my_friends');

    if (!mounted) return;
    setState(() {
      _friends = List<Map<String, dynamic>>.from(rows);
    });
  }

  Future<void> _loadSuggested() async {
    final current = _db.auth.currentUser;
    if (current == null) return;

    final rows = await _db.rpc('get_friend_suggestions', params: {'limit_count': 10});
    if (!mounted) return;
    setState(() {
      _suggested = List<Map<String, dynamic>>.from(rows);
    });
  }

  Future<void> _loadGroups() async {
    final current = _db.auth.currentUser;
    if (current == null) return;

    final links = await _db
        .from('conversation_participants')
        .select('conversation_id, role')
        .eq('user_id', current.id);

    final participantRows = List<Map<String, dynamic>>.from(links);
    final ids = participantRows.map((e) => e['conversation_id']).whereType<String>().toList();
    final roleByConversation = {
      for (final row in participantRows)
        row['conversation_id'].toString(): row['role']?.toString() ?? 'member',
    };

    if (ids.isEmpty) {
      if (!mounted) return;
      setState(() {
        _groups = const [];
      });
      return;
    }

    final rows = await _db
        .from('conversations')
        .select('id, title, description, icon_url, updated_at')
        .inFilter('id', ids)
        .eq('is_group', true)
        .order('updated_at', ascending: false);

    final groups = List<Map<String, dynamic>>.from(rows).map((g) {
      g['my_role'] = roleByConversation[g['id'].toString()] ?? 'member';
      return g;
    }).toList();

    if (!mounted) return;
    setState(() {
      _groups = groups;
    });
  }

  Future<void> _openChat(Map<String, dynamic> friend) async {
    final conversationId = await _db.rpc(
      'start_dm',
      params: {'other_user': friend['id']},
    ) as String;

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          settings: widget.settings,
          conversationId: conversationId,
          peerName: (friend['full_name'] ?? friend['username'] ?? 'Friend').toString(),
        ),
      ),
    );
  }


  Future<void> _openSelfChat() async {
    final conversationId = await _db.rpc('start_self_chat') as String;
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          settings: widget.settings,
          conversationId: conversationId,
          peerName: 'Избранное',
        ),
      ),
    );
  }

  Future<void> _showFindUsersDialog() async {
    final ctrl = TextEditingController();
    List<Map<String, dynamic>> users = [];

    Future<void> search(StateSetter setLocal) async {
      final rows = await _db.rpc('search_users', params: {'p_query': ctrl.text.trim(), 'limit_count': 30});
      users = List<Map<String, dynamic>>.from(rows);
      setLocal(() {});
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Найти пользователя'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(labelText: 'Ник или имя', prefixIcon: Icon(Icons.search)),
                  onSubmitted: (_) => search(setLocal),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => search(setLocal),
                    icon: const Icon(Icons.search),
                    label: const Text('Искать'),
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: users.map((u) {
                      return ListTile(
                        title: Text((u['full_name'] ?? u['username'] ?? 'User').toString()),
                        subtitle: Text('@${u['username'] ?? 'user'}'),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline_rounded),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await _openChat(u);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.person_add_alt_1_rounded),
                              onPressed: () async {
                                final username = (u['username'] ?? '').toString();
                                if (username.isEmpty) return;
                                try {
                                  await _db.rpc('add_friend_by_username', params: {'p_username': username});
                                  await _loadAll();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Друг добавлен')));
                                  }
                                } catch (_) {}
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Закрыть')),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddFriendDialog() async {
    final usernameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Добавить друга'),
        content: TextField(
          controller: usernameCtrl,
          decoration: const InputDecoration(labelText: 'Username (без @)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Добавить')),
        ],
      ),
    );

    if (ok != true) return;
    final username = usernameCtrl.text.trim().replaceFirst('@', '');
    if (username.isEmpty) return;

    try {
      await _db.rpc('add_friend_by_username', params: {'p_username': username});
      await _loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Друг добавлен')));
    } catch (e) {
      if (!mounted) return;
      final text = e.toString().toLowerCase();
      if (text.contains('user_not_found')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пользователь не найден')));
      } else if (text.contains('cannot_add_self')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Нельзя добавить себя')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _openGroup(Map<String, dynamic> group) async {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          settings: widget.settings,
          conversationId: group['id'].toString(),
          peerName: (group['title'] ?? 'Группа').toString(),
        ),
      ),
    );
  }

  Future<void> _createGroup() async {
    final me = _db.auth.currentUser;
    if (me == null) return;

    final candidatesRaw = await _db
        .from('profiles')
        .select('id, username, full_name')
        .neq('id', me.id)
        .order('full_name');
    final candidates = List<Map<String, dynamic>>.from(candidatesRaw);

    final titleCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    final iconCtrl = TextEditingController();
    final selected = <String>{};

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Новая группа'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Название группы'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionCtrl,
                      decoration: const InputDecoration(labelText: 'Описание группы'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: iconCtrl,
                      decoration: const InputDecoration(labelText: 'URL иконки (опц.)'),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: candidates.map((u) {
                          final uid = u['id'].toString();
                          final checked = selected.contains(uid);
                          return CheckboxListTile(
                            value: checked,
                            title: Text((u['full_name'] ?? u['username'] ?? 'User').toString()),
                            subtitle: Text('@${u['username'] ?? 'user'}'),
                            onChanged: (v) {
                              setLocalState(() {
                                if (v == true) {
                                  selected.add(uid);
                                } else {
                                  selected.remove(uid);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Создать'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;

    final conversationId = await _db.rpc(
      'create_group_chat',
      params: {
        'group_title': titleCtrl.text.trim(),
        'member_ids': selected.toList(),
        'group_description': descriptionCtrl.text.trim(),
        'group_icon_url': iconCtrl.text.trim(),
      },
    ) as String;

    await _loadGroups();
    if (!mounted) return;
    final group = _groups.firstWhere(
      (g) => g['id'].toString() == conversationId,
      orElse: () => {
        'id': conversationId,
        'title': titleCtrl.text.trim().isEmpty ? 'Группа' : titleCtrl.text.trim(),
      },
    );
    _openGroup(group);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.settings.lang;
    final q = _search.text.trim().toLowerCase();
    final friends = _friends.where((f) {
      final name = (f['full_name'] ?? f['username'] ?? '').toString().toLowerCase();
      return q.isEmpty || name.contains(q);
    }).toList();
    final groups = _groups.where((g) {
      final name = (g['title'] ?? '').toString().toLowerCase();
      return q.isEmpty || name.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${tr(lang, 'app_name')} - ${tr(lang, 'friends')}'),
        actions: [
          if (_tab == 0)
            IconButton(
              onPressed: _showAddFriendDialog,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              tooltip: 'Добавить друга',
            ),
          if (_tab == 0)
            IconButton(
              onPressed: _showFindUsersDialog,
              icon: const Icon(Icons.travel_explore_rounded),
              tooltip: 'Найти пользователя',
            ),
          IconButton(
            onPressed: _openSelfChat,
            icon: const Icon(Icons.bookmark_outline_rounded),
            tooltip: 'Избранное',
          ),
          if (_tab == 1)
            IconButton(
              onPressed: _createGroup,
              icon: const Icon(Icons.group_add_rounded),
              tooltip: 'Создать группу',
            ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsPage(
                    settings: widget.settings,
                    onChanged: widget.onSettingsChanged,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.settings),
            tooltip: tr(lang, 'settings'),
          ),
          IconButton(
            onPressed: () async => _db.auth.signOut(),
            icon: const Icon(Icons.logout),
            tooltip: tr(lang, 'logout'),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF070A12), Color(0xFF0F1E32)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadAll,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, icon: Icon(Icons.people_alt_outlined), label: Text('Личные')),
                  ButtonSegment(value: 1, icon: Icon(Icons.groups_rounded), label: Text('Группы')),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
              ),
              const SizedBox(height: 10),
              Glass(
                settings: widget.settings,
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: _tab == 0 ? tr(lang, 'find_friend') : 'Найти группу',
                    border: InputBorder.none,
                    icon: const Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_tab == 0)
                ...[
                  ...(friends.isEmpty
                      ? [
                          Glass(
                            settings: widget.settings,
                            child: ListTile(
                              title: Text(tr(lang, 'empty_friends')),
                              subtitle: Text(tr(lang, 'ask_friends')),
                            ),
                          )
                        ]
                      : friends.map(
                          (friend) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Glass(
                              settings: widget.settings,
                              child: ListTile(
                                onTap: () => _openChat(friend),
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFF28C4D9),
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                title: Text((friend['full_name'] ?? friend['username'] ?? 'Friend').toString()),
                                subtitle: Text(
                                  _presenceText(friend).isEmpty
                                      ? '@${friend['username'] ?? 'user'}'
                                      : _presenceText(friend),
                                ),
                                trailing: const Icon(Icons.chat_bubble_outline_rounded),
                              ),
                            ),
                          ),
                        )),
                  if (_suggested.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Возможные друзья', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    ..._suggested.take(10).map(
                      (u) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Glass(
                          settings: widget.settings,
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF6C5CE7),
                              child: Icon(Icons.person_outline_rounded, color: Colors.white),
                            ),
                            title: Text((u['full_name'] ?? u['username'] ?? 'User').toString()),
                            subtitle: Text('@${u['username'] ?? 'user'}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.person_add_alt_1_rounded),
                              onPressed: () async {
                                final username = (u['username'] ?? '').toString();
                                if (username.isEmpty) return;
                                try {
                                  await _db.rpc('add_friend_by_username', params: {'p_username': username});
                                  await _loadAll();
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Друг добавлен')));
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ]
              else
                ...(groups.isEmpty
                    ? [
                        Glass(
                          settings: widget.settings,
                          child: const ListTile(
                            title: Text('Пока нет групп'),
                            subtitle: Text('Создай первую группу и добавь участников.'),
                          ),
                        )
                      ]
                    : groups.map(
                        (group) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Glass(
                            settings: widget.settings,
                            child: ListTile(
                              onTap: () => _openGroup(group),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF00B894),
                                backgroundImage: (group['icon_url'] ?? '').toString().isNotEmpty
                                    ? NetworkImage(group['icon_url'].toString())
                                    : null,
                                child: (group['icon_url'] ?? '').toString().isNotEmpty
                                    ? null
                                    : const Icon(Icons.groups_2_rounded, color: Colors.white),
                              ),
                              title: Text((group['title'] ?? 'Группа').toString()),
                              subtitle: Text(
                                (group['description'] ?? '').toString().isEmpty
                                    ? 'Роль: ${group['my_role'] ?? 'member'}'
                                    : (group['description']).toString(),
                              ),
                              trailing: const Icon(Icons.chat_rounded),
                            ),
                          ),
                        ),
                      )),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.settings,
    required this.conversationId,
    required this.peerName,
  });

  final AppSettings settings;
  final String conversationId;
  final String peerName;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _input = TextEditingController();
  final _crypto = MessageCrypto(_chatCryptoSecret);
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = const [];
  RealtimeChannel? _channel;
  bool _isGroup = false;
  String _myRole = 'member';

  String get _me => _db.auth.currentUser!.id;

  Future<String> _decryptBody(dynamic rawBody) async {
    final value = (rawBody ?? '').toString();
    return _crypto.decryptText(value, conversationId: widget.conversationId);
  }

  Future<String> _encryptBody(String plainText) async {
    return _crypto.encryptText(plainText, conversationId: widget.conversationId);
  }

  @override
  void initState() {
    super.initState();
    _loadConversationMeta();
    _loadMessages();
    _listenRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadConversationMeta() async {
    final convoRows = await _db
        .from('conversations')
        .select('is_group')
        .eq('id', widget.conversationId)
        .limit(1);

    final partRows = await _db
        .from('conversation_participants')
        .select('role')
        .eq('conversation_id', widget.conversationId)
        .eq('user_id', _me)
        .limit(1);

    if (!mounted) return;
    setState(() {
      _isGroup = convoRows.isNotEmpty && convoRows.first['is_group'] == true;
      _myRole = partRows.isEmpty ? 'member' : (partRows.first['role']?.toString() ?? 'member');
    });
  }

  Future<void> _openGroupMembers() async {
    if (!_isGroup) return;

    final rows = await _db
        .from('conversation_participants')
        .select('user_id, role')
        .eq('conversation_id', widget.conversationId)
        .order('created_at');
    final members = List<Map<String, dynamic>>.from(rows);
    final ids = members.map((e) => e['user_id'].toString()).toList();

    final profilesRows = ids.isEmpty
        ? <dynamic>[]
        : await _db
            .from('profiles')
            .select('id, username, full_name')
            .inFilter('id', ids);
    final profiles = {
      for (final p in List<Map<String, dynamic>>.from(profilesRows)) p['id'].toString(): p,
    };

    if (!mounted) return;

    Future<void> refresh() async {
      Navigator.of(context).pop();
      await _loadConversationMeta();
      await _openGroupMembers();
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Участники группы', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: members.map((m) {
                    final uid = m['user_id'].toString();
                    final role = m['role']?.toString() ?? 'member';
                    final p = profiles[uid] ?? const <String, dynamic>{};
                    final name = (p['full_name'] ?? p['username'] ?? uid).toString();
                    final uname = (p['username'] ?? 'user').toString();
                    final canManage = (_myRole == 'owner' || _myRole == 'admin') && uid != _me && role != 'owner';
                    return ListTile(
                      title: Text(name),
                      subtitle: Text('@$uname · $role'),
                      trailing: canManage
                          ? PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'admin' || v == 'member') {
                                  await _db.rpc(
                                    'set_group_role',
                                    params: {
                                      'group_id': widget.conversationId,
                                      'member_id': uid,
                                      'new_role': v,
                                    },
                                  );
                                  if (!mounted) return;
                                  await refresh();
                                }
                                if (v == 'remove') {
                                  await _db.rpc(
                                    'remove_group_member',
                                    params: {
                                      'group_id': widget.conversationId,
                                      'member_id': uid,
                                    },
                                  );
                                  if (!mounted) return;
                                  await refresh();
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'admin', child: Text('Сделать админом')),
                                PopupMenuItem(value: 'member', child: Text('Сделать участником')),
                                PopupMenuItem(value: 'remove', child: Text('Удалить из группы')),
                              ],
                            )
                          : null,
                    );
                  }).toList(),
                ),
              ),
              if (_myRole == 'owner' || _myRole == 'admin')
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final allUsersRaw = await _db
                          .from('profiles')
                          .select('id, username, full_name')
                          .neq('id', _me)
                          .order('full_name');
                      final allUsers = List<Map<String, dynamic>>.from(allUsersRaw);
                      final existing = members.map((e) => e['user_id'].toString()).toSet();
                      final available = allUsers.where((u) => !existing.contains(u['id'].toString())).toList();

                      final selected = await showDialog<String>(
                        context: ctx,
                        builder: (dctx) => AlertDialog(
                          title: const Text('Добавить участника'),
                          content: SizedBox(
                            width: 360,
                            child: ListView(
                              shrinkWrap: true,
                              children: available
                                  .map((u) => ListTile(
                                        title: Text((u['full_name'] ?? u['username'] ?? 'User').toString()),
                                        subtitle: Text('@${u['username'] ?? 'user'}'),
                                        onTap: () => Navigator.pop(dctx, u['id'].toString()),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      );

                      if (selected == null) return;
                      await _db.from('conversation_participants').insert({
                        'conversation_id': widget.conversationId,
                        'user_id': selected,
                        'role': 'member',
                      });
                      if (!mounted) return;
                      await refresh();
                    },
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Добавить участника'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadMessages() async {
    final rows = await _db
        .from('messages')
        .select('id, body, created_at, edited_at, sender_id, message_type, media_url, file_name, mime_type, latitude, longitude')
        .eq('conversation_id', widget.conversationId)
        .order('created_at');

    if (!mounted) return;
    setState(() => _messages = List<Map<String, dynamic>>.from(rows));

    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (_scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
  }

  void _listenRealtime() {
    _channel = _db
        .channel('messages-${widget.conversationId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: widget.conversationId,
          ),
          callback: (_) => _loadMessages(),
        )
        .subscribe();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();

    try {
      final encryptedBody = await _encryptBody(text);
      await _db.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': _me,
        'body': encryptedBody,
        'message_type': 'text',
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки сообщения: $e')),
      );
    }
  }

  Future<void> _pickAndSendAttachment(String type) async {
    FileType pickerType = FileType.any;
    if (type == 'image' || type == 'gif' || type == 'sticker') {
      pickerType = FileType.image;
    } else if (type == 'video') {
      pickerType = FileType.video;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
      type: pickerType,
    );

    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;

    Uint8List? bytes = picked.bytes;
    if (bytes == null && picked.path != null) {
      bytes = await File(picked.path!).readAsBytes();
    }
    if (bytes == null) return;

    final name = (picked.name.isEmpty ? 'file_${DateTime.now().millisecondsSinceEpoch}' : picked.name)
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final objectPath = '${widget.conversationId}/${DateTime.now().millisecondsSinceEpoch}_$name';
    final inferredMime = lookupMimeType(picked.name) ?? 'application/octet-stream';

    try {
      await _db.storage.from('chat-media').uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(
              upsert: false,
              contentType: inferredMime,
            ),
          );

      final url = _db.storage.from('chat-media').getPublicUrl(objectPath);

      await _db.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': _me,
        'body': await _encryptBody(picked.name),
        'message_type': type,
        'media_url': url,
        'file_name': picked.name,
        'mime_type': inferredMime,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки файла: $e')),
      );
    }
  }

  Future<void> _sendLocation() async {
    final latCtrl = TextEditingController();
    final lonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отправить геолокацию'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: latCtrl, decoration: const InputDecoration(labelText: 'Широта')),
            const SizedBox(height: 8),
            TextField(controller: lonCtrl, decoration: const InputDecoration(labelText: 'Долгота')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Отправить')),
        ],
      ),
    );
    if (ok != true) return;
    final lat = double.tryParse(latCtrl.text.trim());
    final lon = double.tryParse(lonCtrl.text.trim());
    if (lat == null || lon == null) return;
    await _db.from('messages').insert({
      'conversation_id': widget.conversationId,
      'sender_id': _me,
      'body': await _encryptBody('Геолокация'),
      'message_type': 'location',
      'latitude': lat,
      'longitude': lon,
    });
  }

  Future<void> _openAttachmentMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.emoji_emotions_outlined), title: const Text('Стикер'), onTap: () => Navigator.pop(ctx, 'sticker')),
            ListTile(leading: const Icon(Icons.image_outlined), title: const Text('Изображение'), onTap: () => Navigator.pop(ctx, 'image')),
            ListTile(leading: const Icon(Icons.gif_box_outlined), title: const Text('GIF'), onTap: () => Navigator.pop(ctx, 'gif')),
            ListTile(leading: const Icon(Icons.videocam_outlined), title: const Text('Видео'), onTap: () => Navigator.pop(ctx, 'video')),
            ListTile(leading: const Icon(Icons.attach_file_rounded), title: const Text('Файл/Документ'), onTap: () => Navigator.pop(ctx, 'file')),
            ListTile(leading: const Icon(Icons.location_on_outlined), title: const Text('Геолокация'), onTap: () => Navigator.pop(ctx, 'location')),
          ],
        ),
      ),
    );

    switch (action) {
      case 'sticker':
      case 'image':
      case 'gif':
      case 'video':
      case 'file':
        await _pickAndSendAttachment(action!);
        break;
      case 'location':
        await _sendLocation();
        break;
      default:
        break;
    }
  }

  Future<void> _deleteMessage(String id) async {
    await _db.from('messages').delete().eq('id', id);
  }

  Future<void> _editMessage(String id, String currentText) async {
    final ctrl = TextEditingController(text: currentText);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Редактировать сообщение'),
        content: TextField(
          controller: ctrl,
          minLines: 1,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Новый текст'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Сохранить')),
        ],
      ),
    );

    if (ok != true) return;
    final next = ctrl.text.trim();
    if (next.isEmpty) return;

    await _db.from('messages').update({'body': await _encryptBody(next)}).eq('id', id);
  }

  Future<void> _onMessageLongPress(Map<String, dynamic> message) async {
    final lang = widget.settings.lang;
    final isMine = message['sender_id'] == _me;
    final canModerateOthers = _isGroup && (_myRole == 'owner' || _myRole == 'admin');
    final canDelete = isMine || canModerateOthers;

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: Text(tr(lang, 'copy')),
              onTap: () => Navigator.of(ctx).pop('copy'),
            ),
            if (isMine)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Редактировать'),
                onTap: () => Navigator.of(ctx).pop('edit'),
              ),
            if (canDelete)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: Text(tr(lang, 'delete')),
                onTap: () => Navigator.of(ctx).pop('delete'),
              ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;
    if (action == 'copy') {
      final body = await _decryptBody(message['body']);
      await Clipboard.setData(ClipboardData(text: body));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Скопировано')));
    } else if (action == 'edit' && isMine) {
      final plain = await _decryptBody(message['body']);
      await _editMessage(message['id'].toString(), plain);
    } else if (action == 'delete' && canDelete) {
      await _deleteMessage(message['id'].toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.settings.lang;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peerName),
        actions: [
          if (_isGroup)
            IconButton(
              onPressed: _openGroupMembers,
              icon: const Icon(Icons.manage_accounts_rounded),
              tooltip: 'Участники и роли',
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF060A12), Color(0xFF0D1C33)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final m = _messages[index];
                  final isMine = m['sender_id'] == _me;
                  final ts = DateTime.parse(m['created_at'].toString()).toLocal();
                  return Align(
                    alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: GestureDetector(
                        onLongPress: () => _onMessageLongPress(m),
                        child: Glass(
                          settings: widget.settings,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          radius: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                FutureBuilder<String>(
                                  future: _decryptBody(m['body']),
                                  builder: (context, snapshot) => Text(snapshot.data ?? ''),
                                ),
                                if ((m['media_url'] ?? '').toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: m['message_type'] == 'image' || m['message_type'] == 'gif' || m['message_type'] == 'sticker'
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              (m['media_url']).toString(),
                                              width: 180,
                                              height: 180,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Text(
                                                (m['media_url']).toString(),
                                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                                              ),
                                            ),
                                          )
                                        : Text(
                                            (m['media_url']).toString(),
                                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                                          ),
                                  ),
                                if (m['message_type'] == 'location' && m['latitude'] != null && m['longitude'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('📍 ${m['latitude']}, ${m['longitude']}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                  ),
                              ]),
                              const SizedBox(height: 4),
                              Text(
                                '${isMine ? '✓ ' : ''}${timeago.format(ts, locale: 'en_short')}${m['edited_at'] != null ? ' · изм.' : ''}',
                                style: const TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                child: Glass(
                  settings: widget.settings,
                  radius: 16,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _openAttachmentMenu,
                        icon: const Icon(Icons.add_circle_outline_rounded),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: tr(lang, 'message_hint'),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: _send,
                        child: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final AppSettings settings;
  final Future<void> Function(AppSettings next) onChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifyEnabled = true;
  bool _notifyPreview = true;
  bool _notifySound = true;
  bool _notifyVibration = true;

  Future<void> _loadNotifyPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifyEnabled = prefs.getBool('notify_enabled') ?? true;
      _notifyPreview = prefs.getBool('notify_preview') ?? true;
      _notifySound = prefs.getBool('notify_sound') ?? true;
      _notifyVibration = prefs.getBool('notify_vibration') ?? true;
    });
  }

  Future<void> _setNotify(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (!mounted) return;
    setState(() {
      if (key == 'notify_enabled') _notifyEnabled = value;
      if (key == 'notify_preview') _notifyPreview = value;
      if (key == 'notify_sound') _notifySound = value;
      if (key == 'notify_vibration') _notifyVibration = value;
    });
  }

  Future<void> _editProfileDialog() async {
    final me = _db.auth.currentUser;
    if (me == null) return;

    final rows = await _db.from('profiles').select('username, full_name').eq('id', me.id).limit(1);
    final existing = rows.isEmpty ? <String, dynamic>{} : Map<String, dynamic>.from(rows.first);

    final usernameCtrl = TextEditingController(text: (existing['username'] ?? '').toString());
    final nameCtrl = TextEditingController(text: (existing['full_name'] ?? '').toString());

    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Профиль'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'Никнейм')),
            const SizedBox(height: 8),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Имя')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Сохранить')),
        ],
      ),
    );

    if (ok != true) return;

    final username = usernameCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_.-]'), '');
    final fullName = nameCtrl.text.trim();

    if (username.length < 3) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ник минимум 3 символа')));
      return;
    }

    try {
      await _db.from('profiles').update({'username': username, 'full_name': fullName.isEmpty ? username : fullName}).eq('id', me.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Профиль обновлен')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка профиля: $e')));
    }
  }

  Future<void> _changePasswordDialog() async {
    final passCtrl = TextEditingController();
    final pass2Ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Сменить пароль'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Новый пароль')),
            const SizedBox(height: 8),
            TextField(controller: pass2Ctrl, obscureText: true, decoration: const InputDecoration(labelText: 'Повтори пароль')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Обновить')),
        ],
      ),
    );

    if (ok != true) return;

    final p1 = passCtrl.text;
    final p2 = pass2Ctrl.text;
    if (p1.length < 6 || p1 != p2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Проверь пароль (мин 6 символов и совпадение)')));
      return;
    }

    try {
      await _db.auth.updateUser(UserAttributes(password: p1));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пароль обновлен')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка смены пароля: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadNotifyPrefs();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final lang = settings.lang;

    Future<void> setLang(String v) => widget.onChanged(settings.copyWith(lang: v));
    Future<void> setLiquid(bool v) => widget.onChanged(settings.copyWith(liquidGlass: v));
    Future<void> setBlur(bool v) => widget.onChanged(settings.copyWith(blur: v));
    Future<void> setTransparency(bool v) => widget.onChanged(settings.copyWith(transparency: v));

    return Scaffold(
      appBar: AppBar(title: Text(tr(lang, 'settings'))),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF070A12), Color(0xFF132845)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Glass(
              settings: settings,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr(lang, 'language')),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: lang,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(value: _ru, child: Text(tr(lang, 'russian'))),
                      DropdownMenuItem(value: _kk, child: Text(tr(lang, 'kazakh'))),
                    ],
                    onChanged: (v) {
                      if (v != null) setLang(v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Glass(
              settings: settings,
              child: Column(
                children: [
                  SwitchListTile(
                    value: settings.liquidGlass,
                    onChanged: (v) => setLiquid(v),
                    title: Text(tr(lang, 'liquid_glass')),
                    subtitle: Text(tr(lang, 'liquid_glass_desc')),
                  ),
                  SwitchListTile(
                    value: settings.blur,
                    onChanged: (v) => setBlur(v),
                    title: Text(tr(lang, 'blur')),
                    subtitle: Text(tr(lang, 'blur_desc')),
                  ),
                  SwitchListTile(
                    value: settings.transparency,
                    onChanged: (v) => setTransparency(v),
                    title: Text(tr(lang, 'transparency')),
                    subtitle: Text(tr(lang, 'transparency_desc')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Glass(
              settings: settings,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.badge_outlined),
                    title: const Text('Профиль'),
                    subtitle: const Text('Никнейм и имя'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _editProfileDialog,
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Пароль'),
                    subtitle: const Text('Сменить пароль аккаунта'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _changePasswordDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Glass(
              settings: settings,
              child: Column(
                children: [
                  SwitchListTile(
                    value: _notifyEnabled,
                    onChanged: (v) => _setNotify('notify_enabled', v),
                    title: const Text('Уведомления'),
                  ),
                  SwitchListTile(
                    value: _notifyPreview,
                    onChanged: _notifyEnabled ? (v) => _setNotify('notify_preview', v) : null,
                    title: const Text('Показывать текст в уведомлениях'),
                  ),
                  SwitchListTile(
                    value: _notifySound,
                    onChanged: _notifyEnabled ? (v) => _setNotify('notify_sound', v) : null,
                    title: const Text('Звук уведомлений'),
                  ),
                  SwitchListTile(
                    value: _notifyVibration,
                    onChanged: _notifyEnabled ? (v) => _setNotify('notify_vibration', v) : null,
                    title: const Text('Вибрация'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
