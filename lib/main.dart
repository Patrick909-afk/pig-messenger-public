import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://tmgiciwryliplkvewlhp.supabase.co',
);
const _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRtZ2ljaXdyeWxpcGxrdmV3bGhwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1MjU4NzEsImV4cCI6MjA5MTEwMTg3MX0.z0X3Yo5VCDxxvhswI3Q_rF99w2My8nWfspXN3fxBJAM',
);

const _ru = 'ru';
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

  String _toAuthEmail(String login) {
    final normalized = login.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_.-]'), '');
    return '$normalized@pmessenger.local';
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
      } else {
        await _db.auth.signUp(
          email: _toAuthEmail(_login.text),
          password: _password.text,
          data: {
            'full_name': _name.text.trim().isEmpty ? _login.text.trim() : _name.text.trim(),
          },
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
    await Future.wait([_loadFriends(), _loadGroups()]);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _loadFriends() async {
    final current = _db.auth.currentUser;
    if (current == null) return;
    await _touchLastSeen();

    final rows = await _db
        .from('profiles')
        .select('id, username, full_name, last_seen')
        .neq('id', current.id)
        .order('last_seen', ascending: false);

    if (!mounted) return;
    setState(() {
      _friends = List<Map<String, dynamic>>.from(rows);
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
        .select('id, title, updated_at')
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
                      ))
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
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF00B894),
                                child: Icon(Icons.groups_2_rounded, color: Colors.white),
                              ),
                              title: Text((group['title'] ?? 'Группа').toString()),
                              subtitle: Text('Роль: ${group['my_role'] ?? 'member'}'),
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
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = const [];
  RealtimeChannel? _channel;
  bool _isGroup = false;
  String _myRole = 'member';

  String get _me => _db.auth.currentUser!.id;

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
        .select('id, body, created_at, sender_id, message_type, media_url, file_name, mime_type, latitude, longitude')
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
    await _db.from('messages').insert({
      'conversation_id': widget.conversationId,
      'sender_id': _me,
      'body': text,
      'message_type': 'text',
    });
  }

  Future<void> _sendMediaLink({
    required String type,
    required String title,
    String? defaultLabel,
  }) async {
    final ctrl = TextEditingController();
    final labelCtrl = TextEditingController(text: defaultLabel ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: 'URL или путь'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: 'Подпись'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Отправить')),
        ],
      ),
    );
    if (ok != true) return;
    final url = ctrl.text.trim();
    if (url.isEmpty) return;
    await _db.from('messages').insert({
      'conversation_id': widget.conversationId,
      'sender_id': _me,
      'body': labelCtrl.text.trim().isEmpty ? title : labelCtrl.text.trim(),
      'message_type': type,
      'media_url': url,
      'file_name': labelCtrl.text.trim(),
    });
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
      'body': 'Геолокация',
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
        await _sendMediaLink(type: 'sticker', title: 'Стикер', defaultLabel: 'Стикер');
        break;
      case 'image':
        await _sendMediaLink(type: 'image', title: 'Изображение');
        break;
      case 'gif':
        await _sendMediaLink(type: 'gif', title: 'GIF');
        break;
      case 'video':
        await _sendMediaLink(type: 'video', title: 'Видео');
        break;
      case 'file':
        await _sendMediaLink(type: 'file', title: 'Файл');
        break;
      case 'location':
        await _sendLocation();
        break;
      default:
        break;
    }
  }

  Future<void> _deleteMessage(String id) async {
    await _db.from('messages').delete().eq('id', id).eq('sender_id', _me);
  }

  Future<void> _onMessageLongPress(Map<String, dynamic> message) async {
    final lang = widget.settings.lang;
    final isMine = message['sender_id'] == _me;
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
      await Clipboard.setData(ClipboardData(text: message['body'].toString()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Скопировано')));
    } else if (action == 'delete' && isMine) {
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
                                Text(m['body']?.toString() ?? ''),
                                if ((m['media_url'] ?? '').toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text((m['media_url']).toString(), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                  ),
                                if (m['message_type'] == 'location' && m['latitude'] != null && m['longitude'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('📍 ${m['latitude']}, ${m['longitude']}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                  ),
                              ]),
                              const SizedBox(height: 4),
                              Text(
                                isMine
                                    ? '✓ ${timeago.format(ts, locale: 'en_short')}'
                                    : timeago.format(ts, locale: 'en_short'),
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

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final AppSettings settings;
  final Future<void> Function(AppSettings next) onChanged;

  @override
  Widget build(BuildContext context) {
    final lang = settings.lang;

    Future<void> setLang(String v) => onChanged(settings.copyWith(lang: v));
    Future<void> setLiquid(bool v) => onChanged(settings.copyWith(liquidGlass: v));
    Future<void> setBlur(bool v) => onChanged(settings.copyWith(blur: v));
    Future<void> setTransparency(bool v) => onChanged(settings.copyWith(transparency: v));

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
          ],
        ),
      ),
    );
  }
}
