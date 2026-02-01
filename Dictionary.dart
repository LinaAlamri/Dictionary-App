import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => DicCubit()),
        BlocProvider(create: (_) => FavoritesCubit()..loadFavorites()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hash Plus Dictionary',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: DictionaryPage(),
    );
  }
}

class DictionaryPage extends StatelessWidget {
  final TextEditingController controller = TextEditingController();

  DictionaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 205, 35, 168),
        centerTitle: true,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Hash Plus',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 0, 0, 0),
                  fontSize: 20,
                ),
              ),

              TextSpan(
                text: 'Dictionary',
                style: TextStyle(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FavoritesPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter a word...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                context.read<DicCubit>().getWord(value);
              },
            ),
            SizedBox(height: 30),
            Expanded(
              child: BlocBuilder<DicCubit, BaseState>(
                builder: (context, state) {
                  if (state is LoadingState) {
                    return Center(child: CircularProgressIndicator());
                  } else if (state is FalureState) {
                    return Center(child: Text(state.errorMassage));
                  } else if (state is SuccessState) {
                    final word = state.word;
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          InfoCard(
                            title: 'Word',
                            value: word,
                            backgroundColor: Color.fromARGB(255, 255, 192, 250),
                          ),
                          SizedBox(height: 20),
                          InfoCard(
                            title: 'Meaning',
                            value: state.meaning,
                            backgroundColor: Color.fromARGB(255, 182, 209, 255),
                          ),
                          SizedBox(height: 20),
                          InfoCard(
                            title: 'Example',
                            value: state.example,
                            backgroundColor: const Color.fromARGB(
                              223,
                              255,
                              242,
                              130,
                            ),
                            isItalic: true,
                          ),
                          SizedBox(height: 20),
                          BlocBuilder<FavoritesCubit, List<String>>(
                            builder: (context, favorites) {
                              final isFav = favorites.contains(word);
                              return IconButton(
                                icon: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.red,
                                  size: 30,
                                ),
                                onPressed: () {
                                  context.read<FavoritesCubit>().toggleFavorite(
                                    word,
                                  );
                                },
                              );
                            },
                          ),
                          SizedBox(height: 40),
                        ],
                      ),
                    );
                  } else {
                    return Center(
                      child: Text(
                        "Search a word to get started.",
                        style: TextStyle(color: Colors.blueAccent),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========= State Classes =========

class BaseState {}

class InitalState extends BaseState {}

class SuccessState extends BaseState {
  final String word;
  final String meaning;
  final String example;
  SuccessState(this.word, this.meaning, this.example);
}

class LoadingState extends BaseState {}

class FalureState extends BaseState {
  final String errorMassage;
  FalureState(this.errorMassage);
}

// ========= Dictionary Cubit =========

class DicCubit extends Cubit<BaseState> {
  final Dio dio = Dio();
  DicCubit() : super(InitalState());

  Future<void> getWord(String word) async {
    emit(LoadingState());
    try {
      final response = await dio.get(
        "https://api.dictionaryapi.dev/api/v2/entries/en/$word",
      );
      final data = response.data[0];
      final meaning =
          data["meanings"][0]["definitions"][0]["definition"] ??
          "No meaning found";
      final example =
          data["meanings"][0]["definitions"][0]["example"] ??
          "No example available.";
      emit(SuccessState(word, meaning, example));
    } catch (e) {
      emit(FalureState('There is an error'));
    }
  }
}

// ========= Favorites Cubit =========

class FavoritesCubit extends Cubit<List<String>> {
  FavoritesCubit() : super([]);
  void clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('favorites');
    emit([]);
  }

  void loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('favorites') ?? [];
    emit(list);
  }

  void toggleFavorite(String word) async {
    final prefs = await SharedPreferences.getInstance();
    final current = [...state];
    if (current.contains(word)) {
      current.remove(word);
    } else {
      current.add(word);
    }
    await prefs.setStringList('favorites', current);
    emit(current);
  }

  bool isFavorite(String word) {
    return state.contains(word);
  }
}

// ========= InfoCard Widget =========

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final Color backgroundColor;
  final bool isItalic;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.backgroundColor,
    this.isItalic = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(206, 116, 115, 122),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ========= Favorites Page =========
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesCubit>().state;

    return Scaffold(
      appBar: AppBar(title: Text('Favorites')),
      body: Column(
        children: [
          Expanded(
            child: favorites.isEmpty
                ? Center(child: Text('No favorites yet.'))
                : ListView.builder(
                    itemCount: favorites.length,
                    itemBuilder: (_, index) {
                      return ListTile(title: Text(favorites[index]));
                    },
                  ),
          ),
          if (favorites.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                label: Text("Clear All Favorites"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  context.read<FavoritesCubit>().clearFavorites();
                },
              ),
            ),
        ],
      ),
    );
  }
}
