import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

IconData _getIconFromName(String iconName) {
  switch (iconName) {
    case 'syringe':
      return FontAwesomeIcons.syringe;
    case 'heart':
      return FontAwesomeIcons.heartbeat;
    case 'lungs':
      return FontAwesomeIcons.lungs;
    case 'allergies':
      return FontAwesomeIcons.allergies;
    case 'pills':
      return FontAwesomeIcons.pills;
    case 'bone':
      return FontAwesomeIcons.bone;
    case 'brain':
      return FontAwesomeIcons.brain;
    case 'female':
      return FontAwesomeIcons.female;
    default:
      return FontAwesomeIcons.medkit;
  }
}

class MedicationsScreen extends StatelessWidget {
  final bool isAdmin;
  final List<String> medications;

  const MedicationsScreen(
      {super.key, required this.medications, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('medications')),
        backgroundColor: Color(0xFF4A148C),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final color =
                  Color(int.parse(category['color'].replaceAll('#', '0xFF')));

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: Icon(
                      _getIconFromName(category['icon']),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    category['name'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A148C),
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward, color: Colors.white),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DrugListScreen(
                          categoryId: category.id,
                          categoryColor: color,
                          isAdmin: isAdmin,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMedicationScreen(),
                  ),
                );
              },
              backgroundColor: Colors.white,
              child: Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }
}

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  _AddMedicationScreenState createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  String medicationName = '';
  String description = '';
  String? selectedCategoryId;
  List<Map<String, dynamic>> categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('categories').get();

      setState(() {
        categories = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['name'],
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addMedication() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (selectedCategoryId == null || selectedCategoryId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('please_select_category'))),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // إنشاء معرف مستند من اسم الدواء
        String documentId = medicationName
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '_')
            .replaceAll(RegExp(r'_+'), '_'); // استبدال أي _ متكررة بواحدة

        await FirebaseFirestore.instance
            .collection('categories')
            .doc(selectedCategoryId)
            .collection('medications')
            .doc(documentId) // استخدام documentId بدلاً من add()
            .set({
          'name': medicationName,
          'description': description,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('medication_added_successfully'))),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding medication: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('add_medication')),
        backgroundColor: Color(0xFF4A148C),
      ),
      body: _isLoading && categories.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: tr('medication_name'),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return tr('please_enter_name');
                          }
                          return null;
                        },
                        onSaved: (value) => medicationName = value!,
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: tr('medication_description'),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return tr('please_enter_description');
                          }
                          return null;
                        },
                        onSaved: (value) => description = value!,
                      ),
                      SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: tr('select_category'),
                          border: OutlineInputBorder(),
                        ),
                        value: selectedCategoryId,
                        items: categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category['id'],
                            child: Text(category['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategoryId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return tr('please_select_category');
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 30),
                      _isLoading
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _addMedication,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 15),
                              ),
                              child: Text(tr('add')),
                            ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class DrugListScreen extends StatelessWidget {
  final String categoryId;
  final Color categoryColor;
  final bool isAdmin;

  const DrugListScreen({
    super.key,
    required this.categoryId,
    required this.categoryColor,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('medications_list')),
        backgroundColor: categoryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('categories')
            .doc(categoryId)
            .collection('medications')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final medications = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: medications.length,
            itemBuilder: (context, index) {
              final medication = medications[index];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  title: Text(
                    medication['name'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: categoryColor,
                    ),
                  ),
                  subtitle: Text(
                    medication['description'] ?? '',
                    style: TextStyle(fontSize: 14),
                  ),
                  trailing: Icon(Icons.info, color: Colors.white),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DrugDetailScreen(
                          categoryId: categoryId,
                          medicationId: medication.id,
                          medicationData: {},
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DrugDetailScreen extends StatelessWidget {
  final String medicationId;
  final String categoryId;

  const DrugDetailScreen({
    super.key,
    required this.medicationId,
    required this.categoryId,
    required Map<String, dynamic> medicationData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('drug_details')),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('categories')
            .doc(categoryId)
            .collection('medications')
            .doc(medicationId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: EdgeInsets.all(10),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data['imageUrl'] != null)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          data['imageUrl'],
                          height: 450,
                          width: 559,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  SizedBox(height: 20),
                  Text(
                    data['name'] ?? tr('unnamed_medication'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  if (data['description'] != null)
                    Text(
                      data['description'],
                      style: TextStyle(fontSize: 16),
                    ),
                  SizedBox(height: 20),
                  if (data['sideEffects'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('side_effects'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        if (data['sideEffects'] is List)
                          ...(data['sideEffects'] as List).map((effect) {
                            return Text('- $effect');
                          })
                        else
                          Text(data['sideEffects'].toString()),
                      ],
                    ),
                  SizedBox(height: 20),
                  if (data['brands'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('brands'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        if (data['brands'] is List)
                          Wrap(
                            spacing: 8,
                            children: (data['brands'] as List).map((brand) {
                              return Chip(
                                label: Text(brand),
                              );
                            }).toList(),
                          )
                        else
                          Text(data['brands'].toString()),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
