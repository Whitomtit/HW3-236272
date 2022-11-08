import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:english_words/english_words.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const _biggerFontSize = 18.0;
const _biggerFont = TextStyle(fontSize: _biggerFontSize);
const _primaryColor = Colors.deepPurple;
const _foregroundColor = Colors.white;
const _baseIndent = 16.0;

void showSnackbar(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(text, style: _biggerFont)));
}

void notImplemented(BuildContext context, String feature) {
  showSnackbar(context, "$feature is not implemented yet");
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  App({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return const MyApp();
        }
        return const LoadingWidget();
      },
    );
  }
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<UserDataNotifier>(
              create: (_) => UserDataNotifier()),
          ChangeNotifierProxyProvider<UserDataNotifier, SavedNotifier>(
              create: (context) =>
                  SavedNotifier(context.read<UserDataNotifier>()),
              update: (context, userDataNotifier, savedNotifier) =>
                  savedNotifier?.update(userDataNotifier) ??
                  SavedNotifier(userDataNotifier))
        ],
        child: MaterialApp(
            title: 'Startup Name Generator',
            theme: ThemeData(
                appBarTheme: const AppBarTheme(
              backgroundColor: _primaryColor,
              foregroundColor: _foregroundColor,
            )),
            home: const RandomWordsRoute()));
  }
}

class RandomWordsRoute extends StatefulWidget {
  const RandomWordsRoute({Key? key}) : super(key: key);

  @override
  State<RandomWordsRoute> createState() => _RandomWordsRouteState();
}

class _RandomWordsRouteState extends State<RandomWordsRoute> {
  final _suggestions = <String>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Startup Name Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: _pushSaved,
            tooltip: 'Saved Suggestions',
          ),
          context.watch<UserDataNotifier>().status == AuthStatus.authenticated
              ? IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  onPressed: _pushLogout,
                  tooltip: 'Logout',
                )
              : IconButton(
                  icon: const Icon(Icons.login),
                  onPressed: _pushLogin,
                  tooltip: 'Login',
                )
        ],
      ),
      body: ListView.builder(
          padding: const EdgeInsets.all(_baseIndent),
          itemBuilder: (context, i) {
            if (i.isOdd) return const Divider();

            final index = i ~/ 2;
            if (index >= _suggestions.length) {
              _suggestions.addAll(
                  generateWordPairs().take(10).map((e) => e.asPascalCase));
            }

            final alreadySaved = context
                .watch<SavedNotifier>()
                .saved
                .contains(_suggestions[index]);
            return ListTile(
              title: Text(
                _suggestions[index],
                style: _biggerFont,
              ),
              trailing: Icon(
                alreadySaved ? Icons.favorite : Icons.favorite_border,
                color: alreadySaved ? Colors.red : null,
                semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
              ),
              onTap: () {
                setState(() {
                  if (alreadySaved) {
                    context.read<SavedNotifier>().remove(_suggestions[index]);
                  } else {
                    context.read<SavedNotifier>().add(_suggestions[index]);
                  }
                });
              },
            );
          }),
    );
  }

  void _pushSaved() {
    Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (context) => const SavedRoute()));
  }

  void _pushLogin() {
    Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (context) => const LoginRoute()));
  }

  void _pushLogout() {
    context.read<UserDataNotifier>()
      ..signOut()
      ..status = AuthStatus.unauthenticated;
    showSnackbar(context, "Successfully logged out");
  }
}

class SavedRoute extends StatelessWidget {
  const SavedRoute({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tiles = context.watch<SavedNotifier>().saved.map((pair) {
      return Dismissible(
          key: ValueKey<String>(pair),
          background: Container(
            color: _primaryColor,
            child: Row(
              children: const [
                SizedBox(width: _baseIndent),
                Icon(Icons.delete, color: _foregroundColor),
                SizedBox(width: _baseIndent),
                Text(
                  "Delete Suggestion",
                  style: TextStyle(
                      color: _foregroundColor, fontSize: _biggerFontSize),
                )
              ],
            ),
          ),
          confirmDismiss: (_) => showDialog<bool>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                    title: const Text("Delete Suggestion"),
                    content: Text(
                        "Are you sure you want to delete $pair from your saved suggestions?"),
                    actions: <Widget>[
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            textStyle: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                            foregroundColor: _primaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0))),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text("Yes"),
                      ),
                      ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: ElevatedButton.styleFrom(
                            textStyle: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                            backgroundColor: _primaryColor,
                            foregroundColor: _foregroundColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0)),
                          ),
                          child: const Text("No")),
                    ],
                  )),
          onDismissed: (_) => context.read<SavedNotifier>().remove(pair),
          child: ListTile(
              title: Text(
            pair,
            style: _biggerFont,
          )));
    });
    final divided = tiles.isNotEmpty
        ? ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList()
        : <Widget>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Suggestions'),
      ),
      body: ListView(children: divided),
    );
  }
}

class LoginRoute extends StatefulWidget {
  const LoginRoute({Key? key}) : super(key: key);

  @override
  State<LoginRoute> createState() => _LoginRouteState();
}

class _LoginRouteState extends State<LoginRoute> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BusyChildWidget(
        loading: context.watch<UserDataNotifier>().status !=
            AuthStatus.unauthenticated,
        child: Scaffold(
            appBar: AppBar(
              title: const Text("Login"),
            ),
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                child: Column(
                  children: [
                    const Text(
                        "Welcome to Startup Names Generator"
                        "\nPlease log in!",
                        style: _biggerFont),
                    const SizedBox(height: _baseIndent),
                    TextFormField(
                      decoration: const InputDecoration(hintText: "Email"),
                      controller: _emailController,
                    ),
                    const SizedBox(height: _baseIndent),
                    TextFormField(
                      decoration: const InputDecoration(hintText: "Password"),
                      obscureText: true,
                      controller: _passwordController,
                    ),
                    const SizedBox(height: _baseIndent),
                    OutlinedButton(
                      onPressed: () async {
                        if (await context.read<UserDataNotifier>().login(
                            _emailController.text, _passwordController.text)) {
                          Navigator.of(context).pop();
                        } else {
                          showSnackbar(context,
                              "There was an error logging into the app");
                        }
                      },
                      style: OutlinedButton.styleFrom(
                          textStyle: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          foregroundColor: _primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0)),
                          minimumSize: const Size.fromHeight(40)),
                      child: const Text("Log in"),
                    ),
                    const SizedBox(height: _baseIndent),
                    ElevatedButton(
                      onPressed: () async {
                        if (await context.read<UserDataNotifier>().signUp(
                                _emailController.text,
                                _passwordController.text) !=
                            null) {
                          Navigator.of(context).pop();
                        } else {
                          showSnackbar(context,
                              "There was an error signing up into the app");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          textStyle: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          backgroundColor: _primaryColor,
                          foregroundColor: _foregroundColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0)),
                          minimumSize: const Size.fromHeight(40)),
                      child: const Text("Sign up"),
                    )
                  ],
                ),
              ),
            )));
  }
}

class BusyChildWidget extends StatelessWidget {
  final Widget child;
  final Widget loadingWidget;
  final bool loading;

  const BusyChildWidget({
    Key? key,
    required this.child,
    required this.loading,
    Widget? loadingWidget,
  })  : loadingWidget = loadingWidget ?? const LoadingWidget(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Opacity(
          opacity: loading ? 0.8 : 1.0,
          child: AbsorbPointer(
            absorbing: loading,
            child: child,
          ),
        ),
        Opacity(
          opacity: loading ? 1.0 : 0,
          child: loadingWidget,
        ),
      ],
    );
  }
}

enum AuthStatus { authenticated, unauthenticated, authenticating }

class UserDataNotifier extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  var _status = AuthStatus.unauthenticated;
  User? _user;

  UserDataNotifier() {
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser == null) {
        _user = null;
        _status = AuthStatus.unauthenticated;
      } else {
        _user = firebaseUser;
        _status = AuthStatus.authenticated;
      }
      notifyListeners();
    });
  }

  AuthStatus get status => _status;

  User? get user => _user;

  set status(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      _status = AuthStatus.authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<UserCredential?> signUp(String email, String password) async {
    try {
      _status = AuthStatus.authenticating;
      notifyListeners();
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

class SavedNotifier extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _saved = <String>{};
  UserDataNotifier _userdata;

  Set<String> get saved => Set.unmodifiable(_saved);

  SavedNotifier(this._userdata) {
    _sync(true);
  }

  bool add(String pair) {
    if (_saved.add(pair)) {
      notifyListeners();
      return true;
    }
    return false;
  }

  bool remove(String pair) {
    if (_saved.remove(pair)) {
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> _sync(bool merge) async {
    if (_userdata.status != AuthStatus.authenticated) return;
    if (merge) {
      var queryRes =
          await _firestore.collection("users").doc(_userdata.user?.uid).get();
      _saved.addAll(((queryRes.data()?["saved"] ?? <String>[]) as List)
          .map((e) => e as String));
    }
    await _firestore
        .collection("users")
        .doc(_userdata.user?.uid)
        .set({"saved": _saved.toList()}, SetOptions(merge: true));
    if (merge) notifyListeners();
  }

  @override
  void notifyListeners() {
    _sync(false);
    super.notifyListeners();
  }

  SavedNotifier update(UserDataNotifier userdata) {
    _userdata = userdata;
    _sync(true);
    return this;
  }
}
