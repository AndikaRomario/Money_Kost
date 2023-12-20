import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:money_kos/pages/category.dart';
import 'package:money_kos/pages/category_edit.dart';
import 'package:money_kos/pages/database_helper.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({Key? key}) : super(key: key);

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  int type = 0; // 0 for "expense", 1 for "income"
  final TextEditingController _nameController = TextEditingController();

  Future<void> openDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) => _buildAddCategoryDialog(),
    );
  }

  AlertDialog _buildAddCategoryDialog() {
    return AlertDialog(
      content: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Text(
                (type == 0) ? "Add Expense" : "Add Income",
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  color: (type == 0) ? Colors.red : Colors.blue,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Name",
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  String categoryName = _nameController.text.trim();

                  if (categoryName.isNotEmpty) {
                    Category category = Category(
                      name: categoryName,
                      type: type,
                    );

                    DatabaseHelper databaseHelper = DatabaseHelper();
                    await databaseHelper.insertCategory(category);

                    // Clear the text input
                    _nameController.clear();

                    // Refresh the UI after adding a new category
                    setState(() {});

                    // Close the dialog and show a Snackbar after adding a new category
                    Navigator.of(context).pop();
                    showSuccessSnackbar("Category added successfully");
                  }
                },
                child: Text("Save"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    // Show a confirmation dialog before deleting the category
    await showDialog(
      context: context,
      builder: (BuildContext context) => _buildDeleteCategoryDialog(category),
    );
  }

  AlertDialog _buildDeleteCategoryDialog(Category category) {
    return AlertDialog(
      title: const Text('Confirm Deletion'),
      content: const Text('Are you sure you want to delete this category?'),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            // Close the confirmation dialog
            Navigator.of(context).pop();

            // Delete the category and show a Snackbar after deleting
            await DatabaseHelper().deleteCategory(category.id!);
            showSuccessSnackbar("Category deleted successfully");

            // Refresh the UI after deleting the category
            setState(() {});
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }

  void showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories) {
    List<Category>? filteredCategories =
        categories.where((category) => category.type == type).toList();

    if (filteredCategories.isEmpty) {
      return Center(
        child: Text('No ${type == 0 ? "expense" : "income"} data'),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: filteredCategories.length,
        itemBuilder: (context, index) {
          Category category = filteredCategories[index];

          Color leadingColor = (category.type == 0) ? Colors.red : Colors.blue;
          Color trailingIconColor =
              (category.type == 0) ? Colors.red : Colors.blue;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 10,
              child: ListTile(
                leading: Icon(Icons.attach_money, color: leadingColor),
                title: Text(category.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () async {
                        var updatedCategory = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                CategoryEditPage(category: category),
                          ),
                        );

                        if (updatedCategory != null) {
                          setState(() {
                            int index = categories.indexOf(category);
                            categories[index] = updatedCategory;
                          });
                        }
                      },
                      icon: Icon(Icons.edit, color: trailingIconColor),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () {
                        _deleteCategory(category);
                      },
                      icon: Icon(Icons.delete, color: trailingIconColor),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Switch(
                  value: type == 1, // Keep the value for "income"
                  onChanged: (bool value) {
                    setState(() {
                      type = value ? 1 : 0;
                    });
                  },
                  inactiveTrackColor: Colors.red[200],
                  inactiveThumbColor: Colors.red,
                  activeColor: Colors.blue,
                ),
                IconButton(
                  onPressed: () {
                    openDialog();
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          FutureBuilder<List<Category>>(
            future: DatabaseHelper().getAllCategories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                List<Category>? categories = snapshot.data;

                if (categories == null || categories.isEmpty) {
                  return const Center(
                    child: Text('No data available'),
                  );
                }

                return _buildCategoryList(categories);
              }
            },
          ),
        ],
      ),
    );
  }
}
