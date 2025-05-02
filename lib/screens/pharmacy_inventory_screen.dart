import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class PharmacyInventoryScreen extends StatefulWidget {
  const PharmacyInventoryScreen({super.key});

  @override
  State<PharmacyInventoryScreen> createState() =>
      _PharmacyInventoryScreenState();
}

class _PharmacyInventoryScreenState extends State<PharmacyInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearchResults = false;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  Future<bool> _checkInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> _searchMedications(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _showSearchResults = false;
          _searchResults = [];
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isSearching = true;
        _searchResults = [];
      });
    }

    try {
      final queryLower = query.toLowerCase();
      final pharmaciesSnapshot = await FirebaseFirestore.instance
          .collection('pharmacy_inventory')
          .get();

      List<Map<String, dynamic>> results = [];

      for (var pharmacyDoc in pharmaciesSnapshot.docs) {
        final medicationsSnapshot = await FirebaseFirestore.instance
            .collection('pharmacy_inventory')
            .doc(pharmacyDoc.id)
            .collection('medications')
            .get();

        for (var medDoc in medicationsSnapshot.docs) {
          final medData = medDoc.data();
          final medName = medData['name']?.toString().toLowerCase() ?? '';

          if (medName.contains(queryLower)) {
            results.add({
              ...medData,
              'pharmacyId': pharmacyDoc.id,
              'pharmacyName': pharmacyDoc['name'] ?? pharmacyDoc.id,
              'pharmacyHotline': pharmacyDoc['hotline'] ?? 'N/A',
              'pharmacyAdminCode': pharmacyDoc['adminCode'] ?? '',
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
          _showSearchResults = true;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
      debugPrint("Search error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('search_error'.tr())),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (mounted) {
        setState(() {
          _searchQuery = query;
        });
      }
      if (query.isNotEmpty) {
        _searchMedications(query);
      } else {
        if (mounted) {
          setState(() {
            _showSearchResults = false;
            _searchResults = [];
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showSearchResults
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'search_medications'.tr(),
                  border: InputBorder.none,
                  hintStyle: const TextStyle(color: Colors.white),
                ),
                style: const TextStyle(color: Colors.white),
                autofocus: true,
              )
            : Text('partner_pharmacies'.tr()),
        backgroundColor: const Color(0xFF4A148C),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showSearchResults ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              if (mounted) {
                setState(() {
                  _showSearchResults = !_showSearchResults;
                  if (!_showSearchResults) {
                    _searchController.clear();
                    _searchResults = [];
                  }
                });
              }
            },
          ),
          if (!_showSearchResults)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _searchResults = [];
                    _showSearchResults = false;
                  });
                }
              },
            ),
        ],
      ),
      body: FutureBuilder<bool>(
        future: _checkInternetConnection(),
        builder: (context, connectionSnapshot) {
          if (connectionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A148C)),
              ),
            );
          }

          if (!connectionSnapshot.hasData || !connectionSnapshot.data!) {
            return _buildNoInternetWidget();
          }

          return _showSearchResults
              ? _buildSearchResults()
              : _buildPharmaciesList();
        },
      ),
    );
  }

  Widget _buildNoInternetWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 60, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            'no_internet_connection'.tr(),
            style: const TextStyle(fontSize: 18, color: Colors.red),
          ),
          const SizedBox(height: 10),
          Text(
            'check_connection_and_try_again'.tr(),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A148C)),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 60,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isEmpty
                  ? 'enter_search_query'.tr()
                  : 'no_medications_found'.tr(),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final medication = _searchResults[index];

        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF4A148C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  FontAwesomeIcons.pills,
                  color: const Color(0xFF4A148C),
                  size: 20,
                ),
              ),
            ),
            title: Text(
              medication['name'] ?? 'Unknown Medication',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${'pharmacy'.tr()}: ${medication['pharmacyName']}'),
                Text('${'category'.tr()}: ${medication['category'] ?? 'N/A'}'),
                Text(
                    '${'price'.tr()}: ${medication['price'] ?? '0'} ${'egp'.tr()}'),
                Text('${'quantity'.tr()}: ${medication['quantity'] ?? '0'}'),
                Text('${'hotline'.tr()}: ${medication['pharmacyHotline']}'),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PharmacyMedicationsScreen(
                    pharmacyId: medication['pharmacyId'],
                    pharmacyName: medication['pharmacyName'],
                    adminCode: medication['pharmacyAdminCode'],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPharmaciesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pharmacy_inventory')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A148C)),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint("Firestore Error: ${snapshot.error}");
          return _buildErrorWidget(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyListWidget();
        }

        final pharmacies = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: pharmacies.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final pharmacy = pharmacies[index];
            final pharmacyData = pharmacy.data() as Map<String, dynamic>;

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PharmacyMedicationsScreen(
                        pharmacyId: pharmacy.id,
                        pharmacyName: pharmacyData['name'] ?? pharmacy.id,
                        adminCode: pharmacyData['adminCode'] ?? '',
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A148C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(
                            FontAwesomeIcons.store,
                            color: const Color(0xFF4A148C),
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pharmacyData['name'] ?? pharmacy.id,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A148C),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${'hotline'.tr()}: ${pharmacyData['hotline'] ?? 'N/A'}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF4A148C)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'error_loading_data'.tr(),
              style: const TextStyle(fontSize: 18, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            error,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (mounted) {
                setState(() {});
              }
            },
            child: Text('retry'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyListWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.storeSlash,
            size: 60,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'no_partner_pharmacies'.tr(),
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class PharmacyMedicationsScreen extends StatefulWidget {
  final String pharmacyId;
  final String pharmacyName;
  final String adminCode;

  const PharmacyMedicationsScreen({
    super.key,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.adminCode,
  });

  @override
  State<PharmacyMedicationsScreen> createState() =>
      _PharmacyMedicationsScreenState();
}

class _PharmacyMedicationsScreenState extends State<PharmacyMedicationsScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isPharmacyAdmin = false;
  late TextEditingController _searchController;
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _verifyAdminAccess();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _verifyAdminAccess() async {
    if (_currentUser == null) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .get();

      if (mounted) {
        setState(() {
          // ignore: unnecessary_cast
          final userData = userDoc.data() as Map<String, dynamic>?;
          _isPharmacyAdmin = userData?['enteredAdminCode'] == widget.adminCode;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint("Error verifying admin access: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pharmacyName),
        backgroundColor: const Color(0xFF4A148C),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _showSearchDialog(context),
          ),
        ],
      ),
      floatingActionButton: _isPharmacyAdmin
          ? FloatingActionButton(
              onPressed: () => _showAddMedicationDialog(context),
              child: const Icon(Icons.add),
              backgroundColor: const Color(0xFF4A148C),
            )
          : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A148C)),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'available_medications'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A148C),
                    ),
                  ),
                ),
                if (_isPharmacyAdmin)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'admin_mode'.tr(),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Expanded(
                  child: _buildMedicationsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildMedicationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pharmacy_inventory')
          .doc(widget.pharmacyId)
          .collection('medications')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 50),
                const SizedBox(height: 16),
                Text(
                  'error_loading_medications'.tr(),
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A148C)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FontAwesomeIcons.pills,
                  size: 60,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 20),
                Text(
                  'no_medications_available'.tr(),
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final medications = snapshot.data!.docs.where((doc) {
          final name = doc['name'].toString().toLowerCase();
          final category = doc['category']?.toString().toLowerCase() ?? '';
          return name.contains(_searchQuery.toLowerCase()) ||
              category.contains(_searchQuery.toLowerCase());
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: medications.length,
          itemBuilder: (context, index) {
            final medication = medications[index];
            final medData = medication.data() as Map<String, dynamic>;
            return _buildMedicationCard(context, medication, medData);
          },
        );
      },
    );
  }

  Widget _buildMedicationCard(BuildContext context, DocumentSnapshot medication,
      Map<String, dynamic> medData) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF4A148C).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              FontAwesomeIcons.pills,
              color: const Color(0xFF4A148C),
              size: 20,
            ),
          ),
        ),
        title: Text(
          medData['name'] ?? 'Unknown Medication',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${'category'.tr()}: ${medData['category'] ?? 'N/A'}'),
            Text('${'price'.tr()}: ${medData['price'] ?? '0'} ${'egp'.tr()}'),
            Text('${'quantity'.tr()}: ${medData['quantity'] ?? '0'}'),
          ],
        ),
        trailing: _isPharmacyAdmin
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editMedication(context, medication),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteMedication(context, medication.id),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Future<void> _editMedication(
      BuildContext context, DocumentSnapshot medication) async {
    if (!_isPharmacyAdmin) return;

    final medData = medication.data() as Map<String, dynamic>;
    final nameController = TextEditingController(text: medData['name']);
    final categoryController =
        TextEditingController(text: medData['category'] ?? '');
    final priceController = TextEditingController(text: medData['price'] ?? '');
    final quantityController =
        TextEditingController(text: medData['quantity']?.toString() ?? '0');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('edit_medication'.tr()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'medication_name'.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'category'.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: 'price'.tr(),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: 'quantity'.tr(),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  quantityController.text.isNotEmpty) {
                try {
                  await FirebaseFirestore.instance
                      .collection('pharmacy_inventory')
                      .doc(widget.pharmacyId)
                      .collection('medications')
                      .doc(medication.id)
                      .update({
                    'name': nameController.text,
                    'category': categoryController.text,
                    'price': priceController.text.isNotEmpty
                        ? priceController.text
                        : 'N/A',
                    'quantity': int.tryParse(quantityController.text) ?? 0,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  if (mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${'error'.tr()}: $e')),
                    );
                  }
                }
              }
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMedication(
      BuildContext context, String medicationId) async {
    if (!_isPharmacyAdmin) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('confirm_delete'.tr()),
        content: Text('delete_medication_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('pharmacy_inventory')
          .doc(widget.pharmacyId)
          .collection('medications')
          .doc(medicationId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('medication_deleted'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'error'.tr()}: $e')),
        );
      }
    }
  }

  Future<void> _showAddMedicationDialog(BuildContext context) async {
    if (!_isPharmacyAdmin) return;

    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('add_medication'.tr()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'medication_name'.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(
                  labelText: 'category'.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: 'price'.tr(),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: 'quantity'.tr(),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  quantityController.text.isNotEmpty) {
                try {
                  await FirebaseFirestore.instance
                      .collection('pharmacy_inventory')
                      .doc(widget.pharmacyId)
                      .collection('medications')
                      .add({
                    'name': nameController.text,
                    'category': categoryController.text,
                    'price': priceController.text.isNotEmpty
                        ? priceController.text
                        : 'N/A',
                    'quantity': int.tryParse(quantityController.text) ?? 0,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  if (mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${'error'.tr()}: $e')),
                    );
                  }
                }
              }
            },
            child: Text('add'.tr()),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('search_medications'.tr()),
        content: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'search_by_name_or_category'.tr(),
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: Text('clear'.tr()),
          ),
          TextButton(
            onPressed: () {
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: Text('close'.tr()),
          ),
        ],
      ),
    );
  }
}
