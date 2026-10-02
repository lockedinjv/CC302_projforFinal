import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

// ============================================================
// RECIPE MODEL
// ============================================================

class Recipe {
  String name;
  String ingredients;
  String instructions;
  String imageUrl;

  Recipe({
    required this.name,
    required this.ingredients,
    required this.instructions,
    required this.imageUrl,
  });

  // Convert API JSON data into a Recipe object
  factory Recipe.fromJson(Map<String, dynamic> json) {
    List<String> ingredientList = [];

    // TheMealDB stores ingredients in strIngredient1
    // through strIngredient20.
    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];

      if (ingredient != null &&
          ingredient.toString().trim().isNotEmpty) {
        final measure = json['strMeasure$i'] ?? '';

        ingredientList.add(
          '$measure $ingredient'.trim(),
        );
      }
    }

    return Recipe(
      name: json['strMeal'] ?? 'Unknown Recipe',
      ingredients: ingredientList.isEmpty
          ? 'No ingredients available'
          : ingredientList.join(', '),
      instructions:
          json['strInstructions'] ?? 'No instructions available',
      imageUrl: json['strMealThumb'] ?? '',
    );
  }
}

// ============================================================
// MAIN APP
// ============================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Recipe Collection',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: const ProfilePage(),
    );
  }
}

// ============================================================
// PROFILE PAGE
// ============================================================

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // List where API recipes will be stored
  List<Recipe> recipes = [];

  // Loading state
  bool isLoading = true;

  // Error message
  String errorMessage = '';

  // TheMealDB API
  final String apiUrl =
      'https://www.themealdb.com/api/json/v1/1/search.php?s=';

  // ==========================================================
  // LOAD API DATA WHEN APP STARTS
  // ==========================================================

  @override
  void initState() {
    super.initState();

    fetchRecipes();
  }

  // ==========================================================
  // FETCH RECIPES FROM API
  // ==========================================================

  Future<void> fetchRecipes() async {
    try {
      // Request recipes containing "chicken"
      final response = await http.get(
        Uri.parse('${apiUrl}chicken'),
      );

      // Check if request was successful
      if (response.statusCode == 200) {
        // Convert JSON response into Dart data
        final data = jsonDecode(response.body);

        // Get meals from the response
        final List meals = data['meals'] ?? [];

        // Convert every meal into a Recipe object
        final List<Recipe> fetchedRecipes = meals
            .map(
              (meal) => Recipe.fromJson(
                meal as Map<String, dynamic>,
              ),
            )
            .toList();

        setState(() {
          recipes = fetchedRecipes;
          isLoading = false;
          errorMessage = '';
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage =
              'Failed to load recipes.\n'
              'Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage =
            'Unable to connect to the API.\n\n$e';
      });
    }
  }

  // ==========================================================
  // ADD RECIPE
  // ==========================================================

  void addRecipe() {
    final nameController = TextEditingController();
    final ingredientsController = TextEditingController();
    final instructionsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Recipe'),

          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Recipe Name',
                    prefixIcon: Icon(Icons.restaurant),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: ingredientsController,
                  decoration: const InputDecoration(
                    labelText: 'Ingredients',
                    prefixIcon: Icon(
                      Icons.shopping_basket,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: instructionsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Instructions',
                    prefixIcon: Icon(
                      Icons.menu_book,
                    ),
                  ),
                ),
              ],
            ),
          ),

          actions: [
            // CANCEL
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),

            // ADD
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty &&
                    ingredientsController.text
                        .trim()
                        .isNotEmpty &&
                    instructionsController.text
                        .trim()
                        .isNotEmpty) {
                  setState(() {
                    recipes.add(
                      Recipe(
                        name: nameController.text.trim(),
                        ingredients:
                            ingredientsController.text.trim(),
                        instructions:
                            instructionsController.text.trim(),

                        // Manually added recipes don't have
                        // an API image.
                        imageUrl: '',
                      ),
                    );
                  });

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Recipe added successfully!',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Add Recipe'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // SHOW RECIPE DETAILS
  // ==========================================================

  void showRecipe(Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(recipe.name),

          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // Recipe image
                if (recipe.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(12),
                    child: Image.network(
                      recipe.imageUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,

                      // If image fails
                      errorBuilder:
                          (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 20),

                // Ingredients title
                const Text(
                  'Ingredients',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(recipe.ingredients),

                const SizedBox(height: 20),

                // Instructions title
                const Text(
                  'Instructions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(recipe.instructions),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // DELETE RECIPE
  // ==========================================================

  void deleteRecipe(int index) {
    setState(() {
      recipes.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recipe deleted'),
      ),
    );
  }

  // ==========================================================
  // REFRESH API DATA
  // ==========================================================

  Future<void> refreshRecipes() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    await fetchRecipes();
  }

  // ==========================================================
  // BUILD UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ======================================================
      // APP BAR
      // ======================================================

      appBar: AppBar(
        title: const Text(
          'Student Recipe Collection',
        ),
        centerTitle: true,

        backgroundColor:
            const Color.fromARGB(255, 237, 233, 238),

        foregroundColor: Colors.black,

        actions: [
          // Refresh button
          IconButton(
            onPressed: refreshRecipes,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Recipes',
          ),
        ],
      ),

      // ======================================================
      // ADD RECIPE BUTTON
      // ======================================================

      floatingActionButton: FloatingActionButton(
        onPressed: addRecipe,

        backgroundColor: Colors.deepPurple,

        foregroundColor: Colors.white,

        child: const Icon(Icons.add),
      ),

      // ======================================================
      // BODY
      // ======================================================

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red,
                        ),

                        const SizedBox(height: 15),

                        Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 20),

                        ElevatedButton.icon(
                          onPressed: refreshRecipes,
                          icon: const Icon(
                            Icons.refresh,
                          ),
                          label: const Text(
                            'Try Again',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // =========================================
                    // HEADER
                    // =========================================

                    Container(
                      width: double.infinity,

                      padding: const EdgeInsets.all(20),

                      margin: const EdgeInsets.all(15),

                      decoration: BoxDecoration(
                        color: const Color.fromARGB(
                          255,
                          20,
                          2,
                          34,
                        ),

                        borderRadius:
                            BorderRadius.circular(15),
                      ),

                      child: const Column(
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 55,
                            color: Colors.white,
                          ),

                          SizedBox(height: 8),

                          Text(
                            'Student Recipe Collection',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            'Recipes loaded from an API',
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // =========================================
                    // RECIPE COUNT
                    // =========================================

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                      ),

                      child: Align(
                        alignment: Alignment.centerLeft,

                        child: Text(
                          '${recipes.length} Recipes',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // =========================================
                    // LIST VIEW BUILDER
                    // =========================================

                    Expanded(
                      child: recipes.isEmpty
                          ? const Center(
                              child: Text(
                                'No recipes available.',
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 15,
                              ),

                              // Number of items
                              itemCount: recipes.length,

                              // Build every recipe
                              itemBuilder:
                                  (context, index) {
                                final recipe =
                                    recipes[index];

                                return Container(
                                  margin:
                                      const EdgeInsets
                                          .only(
                                    bottom: 12,
                                  ),

                                  decoration:
                                      BoxDecoration(
                                    color: Colors.white,

                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      12,
                                    ),

                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors
                                            .grey
                                            .withOpacity(
                                          0.2,
                                        ),
                                        blurRadius: 5,
                                        offset:
                                            const Offset(
                                          0,
                                          3,
                                        ),
                                      ),
                                    ],
                                  ),

                                  child: Padding(
                                    padding:
                                        const EdgeInsets
                                            .all(15),

                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,

                                      children: [
                                        // =================================
                                        // RECIPE IMAGE
                                        // =================================

                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            10,
                                          ),

                                          child: recipe
                                                  .imageUrl
                                                  .isNotEmpty
                                              ? Image
                                                  .network(
                                                  recipe
                                                      .imageUrl,

                                                  width: 80,

                                                  height: 80,

                                                  fit: BoxFit
                                                      .cover,

                                                  errorBuilder:
                                                      (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) {
                                                    return
                                                        Container(
                                                      width:
                                                          80,
                                                      height:
                                                          80,
                                                      color: Colors
                                                          .deepPurple
                                                          .shade100,
                                                      child:
                                                          const Icon(
                                                        Icons
                                                            .restaurant,
                                                        color: Colors
                                                            .deepPurple,
                                                        size:
                                                            35,
                                                      ),
                                                    );
                                                  },
                                                )
                                              : Container(
                                                  width: 80,
                                                  height: 80,
                                                  color: Colors
                                                      .deepPurple
                                                      .shade100,
                                                  child:
                                                      const Icon(
                                                    Icons
                                                        .restaurant,
                                                    color: Colors
                                                        .deepPurple,
                                                    size: 35,
                                                  ),
                                                ),
                                        ),

                                        const SizedBox(
                                          width: 15,
                                        ),

                                        // =================================
                                        // RECIPE INFORMATION
                                        // =================================

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,

                                            children: [
                                              Text(
                                                recipe.name,

                                                maxLines: 2,

                                                overflow:
                                                    TextOverflow
                                                        .ellipsis,

                                                style:
                                                    const TextStyle(
                                                  fontSize:
                                                      18,
                                                  fontWeight:
                                                      FontWeight
                                                          .bold,
                                                ),
                                              ),

                                              const SizedBox(
                                                height: 5,
                                              ),

                                              Text(
                                                recipe
                                                    .ingredients,

                                                maxLines: 2,

                                                overflow:
                                                    TextOverflow
                                                        .ellipsis,

                                                style:
                                                    TextStyle(
                                                  color: Colors
                                                      .grey[600],
                                                ),
                                              ),

                                              const SizedBox(
                                                height: 8,
                                              ),

                                              // View button
                                              ElevatedButton
                                                  .icon(
                                                onPressed: () =>
                                                    showRecipe(
                                                  recipe,
                                                ),

                                                icon:
                                                    const Icon(
                                                  Icons
                                                      .visibility,
                                                ),

                                                label:
                                                    const Text(
                                                  'View Recipe',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // =================================
                                        // DELETE BUTTON
                                        // =================================

                                        IconButton(
                                          onPressed: () =>
                                              deleteRecipe(
                                            index,
                                          ),

                                          icon:
                                              const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),

                                          tooltip:
                                              'Delete Recipe',
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
