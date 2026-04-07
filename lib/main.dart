import 'package:flutter/material.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  runApp(const PigMessengerApp());
}

SupabaseClient get _db => Supabase.instance.client;

class PigMessengerApp extends StatelessWidget {
  const PigMessengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PIG MESSENGER',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B6B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
      ),
      home: const EntryGate(),
    );
  }
}

class EntryGate extends StatelessWidget {
  const EntryGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _db.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = _db.auth.currentUser;
        if (user == null) return const AuthPage();
        return const FriendsPage();
      },
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _isLogin = true;
  bool _busy = false;

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      if (_isLogin) {
        await _db.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await _db.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'full_name': _name.text.trim()},
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Аккаунт создан. Если включено подтверждение почты - проверь email.'),
            ),
          );
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1117), Color(0xFF1C252E), Color(0xFF4A1E1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: const Color(0xCC111822),
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'PIG MESSENGER',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text('chat for friends'),
                    const SizedBox(height: 18),
                    if (!_isLogin)
                      TextField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Your name',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                    if (!_isLogin) const SizedBox(height: 12),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _busy ? null : _submit,
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(_isLogin ? 'Login' : 'Create account'),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin
                            ? 'No account yet? Register'
                            : 'Already have an account? Sign in',
                      ),
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
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _friends = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final current = _db.auth.currentUser;
    if (current == null) return;

    final rows = await _db
        .from('profiles')
        .select('id, username, full_name, avatar_url, last_seen')
        .neq('id', current.id)
        .order('last_seen', ascending: false);

    if (!mounted) return;
    setState(() {
      _friends = List<Map<String, dynamic>>.from(rows);
      _loading = false;
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
          conversationId: conversationId,
          peerName: (friend['full_name'] ?? friend['username'] ?? 'Friend').toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final list = _friends.where((f) {
      final name = (f['full_name'] ?? f['username'] ?? '').toString().toLowerCase();
      return q.isEmpty || name.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PIG MESSENGER'),
        actions: [
          IconButton(
            onPressed: () async => _db.auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFriends,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Find friend',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (list.isEmpty)
              const ListTile(
                title: Text('No users yet'),
                subtitle: Text('Ask your friends to register in the app.'),
              )
            else
              ...list.map(
                (friend) => Card(
                  child: ListTile(
                    onTap: () => _openChat(friend),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFF8A65),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      (friend['full_name'] ?? friend['username'] ?? 'Friend').toString(),
                    ),
                    subtitle: Text('@${friend['username'] ?? 'user'}'),
                    trailing: const Icon(Icons.chat_bubble_outline_rounded),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.conversationId,
    required this.peerName,
  });

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

  String get _me => _db.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
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

  Future<void> _loadMessages() async {
    final rows = await _db
        .from('messages')
        .select('id, body, created_at, sender_id')
        .eq('conversation_id', widget.conversationId)
        .order('created_at');

    if (!mounted) return;
    setState(() {
      _messages = List<Map<String, dynamic>>.from(rows);
    });

    await Future<void>.delayed(const Duration(milliseconds: 20));
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.peerName)),
      body: Column(
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
                  alignment:
                      isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    constraints: const BoxConstraints(maxWidth: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMine
                          ? const Color(0xFFFF6B6B)
                          : const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m['body'].toString()),
                        const SizedBox(height: 4),
                        Text(
                          timeago.format(ts, locale: 'en_short'),
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Write a message...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _send,
                    child: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
