import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:english_words/english_words.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet/snapping_sheet.dart';

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
            home: MainScreen()));
  }
}

class AccountGrabbingWidget extends StatelessWidget {
  const AccountGrabbingWidget({Key? key}) : super(key: key);

  String _truncateWithEllipsis(String myString, int cutoff) {
    return (myString.length <= cutoff)
        ? myString
        : '${myString.substring(0, cutoff)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(blurRadius: 25, color: Colors.black.withOpacity(0.2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            "Welcome back, ${_truncateWithEllipsis(context.read<UserDataNotifier>().user!.email!, 12)}",
            style: _biggerFont,
          ),
          const Icon(
            Icons.keyboard_arrow_up_rounded,
            color: Colors.black,
          ),
        ],
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  MainScreen({Key? key}) : super(key: key);

  final _snappingSheetController = SnappingSheetController();
  final _imagePicker = ImagePicker();
  double? _startSheetPosition;

  static const _startSnapPosition = SnappingPosition.factor(
    positionFactor: 0.0,
    snappingCurve: Curves.easeOutExpo,
    snappingDuration: Duration(seconds: 1),
    grabbingContentOffset: GrabbingContentOffset.top,
  );

  static const _finalSnapPosition = SnappingPosition.pixels(
    snappingCurve: Curves.elasticOut,
    snappingDuration: Duration(milliseconds: 1750),
    positionPixels: 160,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Startup Name Generator'),
          actions: [
            IconButton(
              icon: const Icon(Icons.star),
              onPressed: () => _pushSaved(context),
              tooltip: 'Saved Suggestions',
            ),
            context.watch<UserDataNotifier>().status == AuthStatus.authenticated
                ? IconButton(
                    icon: const Icon(Icons.exit_to_app),
                    onPressed: () => _pushLogout(context),
                    tooltip: 'Logout',
                  )
                : IconButton(
                    icon: const Icon(Icons.login),
                    onPressed: () => _pushLogin(context),
                    tooltip: 'Login',
                  )
          ],
        ),
        body: context.read<UserDataNotifier>().status ==
                AuthStatus.authenticated
            ? SnappingSheet(
                controller: _snappingSheetController,
                grabbing: GestureDetector(
                  onTap: _toggleSnappingSheet,
                  child: const AccountGrabbingWidget(),
                ),
                grabbingHeight: 75,
                snappingPositions: const [
                  _startSnapPosition,
                  _finalSnapPosition,
                ],
                sheetBelow: SnappingSheetContent(
                    sizeBehavior: SheetSizeStatic(size: 120),
                    draggable: false,
                    child: Container(
                      alignment: Alignment.topCenter,
                      color: Colors.white,
                      child: Row(
                        children: [
                          Flexible(
                              fit: FlexFit.tight,
                              flex: 2,
                              child: FutureBuilder<ImageProvider>(
                                  future:
                                      context.watch<UserDataNotifier>().avatar,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return CircleAvatar(
                                        radius: 45,
                                        backgroundImage: snapshot.requireData,
                                      );
                                    }
                                    return const LoadingWidget();
                                  })),
                          Flexible(
                            fit: FlexFit.tight,
                            flex: 5,
                            child: SizedBox(
                              height: 120,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context
                                        .read<UserDataNotifier>()
                                        .user!
                                        .email!,
                                    style: _biggerFont,
                                  ),
                                  ElevatedButton(
                                      onPressed: () => _changeAvatar(
                                          context.read<UserDataNotifier>()),
                                      style: ElevatedButton.styleFrom(
                                        textStyle: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                        backgroundColor: Colors.blue,
                                        foregroundColor: _foregroundColor,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30.0)),
                                      ),
                                      child: const Text("Change avatar"))
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    )),
                child: const RandomWordsRoute(),
              )
            : const RandomWordsRoute());
  }

  Future<void> _changeAvatar(UserDataNotifier userdata) async {
    XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      userdata.updateAvatar(File(image.path));
    }
  }

  void _toggleSnappingSheet() {
    _startSheetPosition ??= _snappingSheetController.currentPosition;
    if (_snappingSheetController.currentPosition > _startSheetPosition!) {
      _snappingSheetController.snapToPosition(_startSnapPosition);
    } else {
      _snappingSheetController.snapToPosition(_finalSnapPosition);
    }
  }

  void _pushSaved(BuildContext context) {
    Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (context) => const SavedRoute()));
  }

  void _pushLogin(BuildContext context) {
    Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (context) => const LoginRoute()));
  }

  void _pushLogout(BuildContext context) {
    context.read<UserDataNotifier>()
      ..signOut()
      ..status = AuthStatus.unauthenticated;
    showSnackbar(context, "Successfully logged out");
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
    return ListView.builder(
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
        });
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
  final _formKey = GlobalKey<FormState>();

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
                        showModalBottomSheet(
                            context: context,
                            builder: (context) => Form(
                                  key: _formKey,
                                  child: SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                            0.3 +
                                        MediaQuery.of(context)
                                            .viewInsets
                                            .bottom,
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const Text(
                                            "Please confirm your password below:",
                                            style: _biggerFont,
                                          ),
                                          const SizedBox(height: _baseIndent),
                                          TextFormField(
                                            validator: (value) {
                                              if (value !=
                                                  _passwordController.text) {
                                                return "Passwords must match";
                                              }
                                              return null;
                                            },
                                            decoration: const InputDecoration(
                                                hintText: "Password"),
                                            obscureText: true,
                                          ),
                                          const SizedBox(height: _baseIndent),
                                          ElevatedButton(
                                              onPressed: () {
                                                if (_formKey.currentState!
                                                    .validate()) {
                                                  context
                                                      .read<UserDataNotifier>()
                                                      .signUp(
                                                          _emailController.text,
                                                          _passwordController
                                                              .text);
                                                  Navigator.of(context)
                                                    ..pop()
                                                    ..pop();
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                  textStyle: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  backgroundColor: Colors.blue,
                                                  foregroundColor:
                                                      _foregroundColor,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              30.0)),
                                                  minimumSize:
                                                      const Size.fromHeight(
                                                          40)),
                                              child: const Text("Confirm")),
                                        ],
                                      ),
                                    ),
                                  ),
                                ));
                      },
                      style: ElevatedButton.styleFrom(
                          textStyle: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          backgroundColor: _primaryColor,
                          foregroundColor: _foregroundColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0)),
                          minimumSize: const Size.fromHeight(40)),
                      child: const Text("New user? Click to sign up"),
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
  static final _avatars = FirebaseStorage.instance.ref().child("avatars");
  static final _auth = FirebaseAuth.instance;
  var _status = AuthStatus.unauthenticated;
  User? _user;
  File? _localAvatar;

  UserDataNotifier() {
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser == null) {
        _user = null;
        _localAvatar = null;
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

  Future<ImageProvider> get avatar async {
    if (_localAvatar == null) {
      try {
        Completer<NetworkImage> completer = Completer<NetworkImage>();
        NetworkImage avatar =
            NetworkImage(await _avatars.child(_user!.uid).getDownloadURL());
        avatar.resolve(ImageConfiguration.empty).addListener(
            ImageStreamListener((info, call) => completer.complete(avatar)));
        return completer.future;
      } on FirebaseException catch (_) {
        return const AssetImage("images/default_avatar.png");
      }
    } else {
      return FileImage(_localAvatar!);
    }
  }

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

  Future<void> updateAvatar(File image) async {
    _localAvatar = image;
    notifyListeners();
    await _avatars.child(_user!.uid).putFile(image);
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
