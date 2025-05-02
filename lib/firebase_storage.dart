import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insert Data to Firestore',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: InsertCategoryPage(),
    );
  }
}

class InsertCategoryPage extends StatefulWidget {
  const InsertCategoryPage({super.key});

  @override
  _InsertCategoryPageState createState() => _InsertCategoryPageState();
}

class _InsertCategoryPageState extends State<InsertCategoryPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _insertCategory() async {
    String name = _nameController.text;
    String description = _descriptionController.text;

    // Check if name and description are not empty
    if (name.isNotEmpty && description.isNotEmpty) {
      try {
        await _firestore.collection('categories').add({
          'name': name,
          'description': description,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Clear the input fields after insertion
        _nameController.clear();
        _descriptionController.clear();

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category Added Successfully!')),
        );
      } catch (e) {
        // Handle errors during insertion
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add category: $e')),
        );
      }
    } else {
      // Show an error message if fields are empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in both fields!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Insert Category'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input for Category Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            // Input for Category Description
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Category Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            // Insert Button
            ElevatedButton(
              onPressed: _insertCategory,
              child: Text('Insert Category'),
            ),
          ],
        ),
      ),
    );
  }
}
