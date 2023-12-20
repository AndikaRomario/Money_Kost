import 'package:flutter/material.dart';
import 'package:money_kos/pages/category.dart';
import 'package:money_kos/pages/database_helper.dart';

class CategoryEditPage extends StatefulWidget {
  final Category category;

  const CategoryEditPage({Key? key, required this.category}) : super(key: key);

  @override
  _CategoryEditPageState createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.category.name;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2), // Adjust the duration as needed
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Category"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Name",
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                String categoryName = _nameController.text.trim();

                if (categoryName.isNotEmpty) {
                  Category updatedCategory = Category(
                    id: widget.category.id,
                    name: categoryName,
                    type: widget.category.type,
                  );

                  DatabaseHelper databaseHelper = DatabaseHelper();
                  await databaseHelper.updateCategory(updatedCategory);

                  // Show SnackBar on successful edit
                  _showSnackBar("Edit successful");

                  // Pop the page and send back the updated category
                  Navigator.of(context).pop(updatedCategory);
                }
              },
              child: Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}
