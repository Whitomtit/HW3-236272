import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';

const _biggerFontSize = 18.0;
const _biggerFont = TextStyle(fontSize: _biggerFontSize);
const _primaryColor = Colors.deepPurple;
const _foregroundColor = Colors.white;
const _baseIndent = 16.0;

final _saved = <WordPair>{};

void notImplemented(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("$feature is not implemented yet", style: _biggerFont)));
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Startup Name Generator',
        theme: ThemeData(
            appBarTheme: const AppBarTheme(
          backgroundColor: _primaryColor,
          foregroundColor: _foregroundColor,
        )),
        home: const RandomWordsRoute());
  }
}

class RandomWordsRoute extends StatefulWidget {
  const RandomWordsRoute({Key? key}) : super(key: key);

  @override
  State<RandomWordsRoute> createState() => _RandomWordsRouteState();
}

class _RandomWordsRouteState extends State<RandomWordsRoute> {
  final _suggestions = <WordPair>[];

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
          IconButton(
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
              _suggestions.addAll(generateWordPairs().take(10));
            }

            final alreadySaved = _saved.contains(_suggestions[index]);
            return ListTile(
              title: Text(
                _suggestions[index].asPascalCase,
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
                    _saved.remove(_suggestions[index]);
                  } else {
                    _saved.add(_suggestions[index]);
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
}

class SavedRoute extends StatelessWidget {
  const SavedRoute({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tiles = _saved.map((pair) {
      return Dismissible(
          key: ValueKey<WordPair>(pair),
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
          confirmDismiss: (_) => Future(() {
                notImplemented(context, "Deletion");
                return false;
              }),
          child: ListTile(
              title: Text(
            pair.asPascalCase,
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

class LoginRoute extends StatelessWidget {
  const LoginRoute({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                ),
                const SizedBox(height: _baseIndent),
                TextFormField(
                  decoration: const InputDecoration(hintText: "Password"),
                ),
                const SizedBox(height: _baseIndent),
                ElevatedButton(
                  onPressed: () => notImplemented(context, "Login"),
                  style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      backgroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0)),
                      minimumSize: const Size.fromHeight(40)),
                  child: const Text("Log in"),
                )
              ],
            ),
          ),
        ));
  }
}
