import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  Timer? _debounce;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text.trim());
      } else {
        setState(() {
          _results = [];
          _hasSearched = false;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final medications = await _searchMedications(query);
      final pharmacies = await _searchPharmacies(query);
      final branches = await _searchBranches(query);

      setState(() {
        _results = [...medications, ...pharmacies, ...branches];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Search error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _searchMedications(String query) async {
    final results = <Map<String, dynamic>>[];
    final queryLower = query.toLowerCase();

    final categories = await _firestore.collection('categories').get();

    for (var category in categories.docs) {
      final medications = await _firestore
          .collection('categories')
          .doc(category.id)
          .collection('medications')
          .get();

      for (var doc in medications.docs) {
        final data = doc.data();
        final name = data['name']?.toString().toLowerCase() ?? '';
        final description = data['description']?.toString().toLowerCase() ?? '';
        final brands = data['brands']?.toString().toLowerCase() ?? '';

        if (name.contains(queryLower) ||
            description.contains(queryLower) ||
            brands.contains(queryLower)) {
          results.add({
            'id': doc.id,
            'name': data['name'] ?? tr('unknown_medication'),
            'type': 'medication',
            'categoryId': category.id,
            'categoryName': category['name'] ?? tr('unknown_category'),
            'description': data['description'] ?? '',
            'brands': data['brands'] ?? '',
            'imageUrl': data['imageUrl'],
          });
        }
      }
    }

    return results;
  }

  Future<List<Map<String, dynamic>>> _searchPharmacies(String query) async {
    final results = <Map<String, dynamic>>[];
    final queryLower = query.toLowerCase();

    final snapshot = await _firestore.collection('pharmacies').get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final name = data['name']?.toString().toLowerCase() ?? '';

      if (name.contains(queryLower)) {
        results.add({
          'id': doc.id,
          'name': data['name'] ?? tr('unknown_pharmacy'),
          'type': 'pharmacy',
          'isMain': true,
        });
      }
    }

    return results;
  }

  Future<List<Map<String, dynamic>>> _searchBranches(String query) async {
    final results = <Map<String, dynamic>>[];
    final queryLower = query.toLowerCase();

    final pharmacies = await _firestore.collection('pharmacies').get();

    for (var pharmacy in pharmacies.docs) {
      final branches = await _firestore
          .collection('pharmacies')
          .doc(pharmacy.id)
          .collection('branches')
          .get();

      for (var branch in branches.docs) {
        final data = branch.data();
        final name = data['name']?.toString().toLowerCase() ?? '';
        final address = data['address']?.toString().toLowerCase() ?? '';

        if (name.contains(queryLower) || address.contains(queryLower)) {
          results.add({
            'id': branch.id,
            'name': data['name'] ?? tr('unknown_branch'),
            'type': 'branch',
            'pharmacyId': pharmacy.id,
            'pharmacyName': pharmacy['name'] ?? tr('unknown_pharmacy'),
            'address': data['address'] ?? tr('no_address'),
            'phone': data['phone'] ?? tr('no_phone'),
            'isMain': false,
          });
        }
      }
    }

    return results;
  }

  Future<List<Map<String, dynamic>>> _getPharmacyBranches(
      String pharmacyId) async {
    final results = <Map<String, dynamic>>[];

    final pharmacyDoc =
        await _firestore.collection('pharmacies').doc(pharmacyId).get();
    final pharmacyName = pharmacyDoc.data()?['name'] ?? tr('unknown_pharmacy');

    final branches = await _firestore
        .collection('pharmacies')
        .doc(pharmacyId)
        .collection('branches')
        .get();

    for (var branch in branches.docs) {
      final data = branch.data();
      results.add({
        'id': branch.id,
        'name': data['name'] ?? tr('unknown_branch'),
        'type': 'branch',
        'pharmacyId': pharmacyId,
        'pharmacyName': pharmacyName,
        'address': data['address'] ?? tr('no_address'),
        'phone': data['phone'] ?? tr('no_phone'),
        'isMain': false,
      });
    }

    return results;
  }

  Widget _buildMedicationImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.medical_services, color: Colors.blue.shade700),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade200,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade200,
          child: Icon(Icons.error_outline, color: Colors.red),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'medication':
        return Icons.medical_services_outlined;
      case 'pharmacy':
        return Icons.local_pharmacy_outlined;
      case 'branch':
        return Icons.location_on_outlined;
      default:
        return Icons.search;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'medication':
        return Colors.blue.shade700;
      case 'pharmacy':
        return Colors.green.shade700;
      case 'branch':
        return Colors.orange.shade700;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSubtitle(Map<String, dynamic> item) {
    switch (item['type']) {
      case 'medication':
        return Text(
          '${item['categoryName']} • ${item['brands']}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        );
      case 'pharmacy':
        return Text(
          tr('main_pharmacy'),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        );
      case 'branch':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['pharmacyName'],
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            Text(
              item['address'],
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        );
      default:
        return SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: tr('search_hint'),
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
            prefixIcon: Icon(Icons.search, color: Colors.white),
          ),
          style: TextStyle(color: Colors.white),
          autofocus: true,
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (_isLoading)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading) LinearProgressIndicator(),
          Expanded(
            child: _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isLoading && _results.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.deepPurple.shade200),
            SizedBox(height: 20),
            Text(
              tr('search_prompt'),
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.deepPurple.shade200),
            SizedBox(height: 20),
            Text(
              tr('no_results_found'),
              style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
            ),
            SizedBox(height: 10),
            Text(
              tr('try_different_keywords'),
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          child: ListTile(
            leading: item['type'] == 'medication'
                ? _buildMedicationImage(item['imageUrl'])
                : Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getColorForType(item['type']).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconForType(item['type']),
                      color: _getColorForType(item['type']),
                      size: 24,
                    ),
                  ),
            title: Text(
              item['name'],
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            subtitle: _buildSubtitle(item),
            trailing: item['type'] == 'branch'
                ? IconButton(
                    icon: Icon(Icons.phone_outlined,
                        color: Colors.green.shade700),
                    onPressed: () => _callPhone(item['phone']),
                  )
                : null,
            onTap: () => _showItemDetails(item),
            contentPadding: EdgeInsets.symmetric(horizontal: 12),
          ),
        );
      },
    );
  }

  void _callPhone(String phone) {
    // Implement phone calling functionality
  }

  void _showItemDetails(Map<String, dynamic> item) async {
    switch (item['type']) {
      case 'medication':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(item['name']),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item['imageUrl'] != null && item['imageUrl'].isNotEmpty)
                    Center(
                      child: Container(
                        height: 150,
                        margin: EdgeInsets.only(bottom: 16),
                        child: CachedNetworkImage(
                          imageUrl: item['imageUrl'],
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade200,
                            child: Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            child: Icon(Icons.error_outline, color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ListTile(
                    leading: Icon(Icons.category_outlined,
                        color: Colors.blue.shade700),
                    title: Text(tr('category')),
                    subtitle: Text(item['categoryName']),
                  ),
                  if (item['brands'].toString().isNotEmpty)
                    ListTile(
                      leading: Icon(Icons.branding_watermark_outlined,
                          color: Colors.blue.shade700),
                      title: Text(tr('brands')),
                      subtitle: Text(item['brands']),
                    ),
                  if (item['description'].toString().isNotEmpty)
                    ListTile(
                      leading: Icon(Icons.description_outlined,
                          color: Colors.blue.shade700),
                      title: Text(tr('description')),
                      subtitle: Text(item['description']),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text(tr('close')),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
        break;
      case 'pharmacy':
        final branches = await _getPharmacyBranches(item['id']);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(item['name']),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading:
                        Icon(Icons.info_outline, color: Colors.green.shade700),
                    title: Text(tr('main_pharmacy_details')),
                  ),
                  Divider(height: 20),
                  Text(
                    tr('branches_list'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 10),
                  if (branches.isEmpty)
                    Text(
                      tr('no_branches_found'),
                      style: TextStyle(color: Colors.grey.shade600),
                    )
                  else
                    ...branches.map((branch) => ListTile(
                          leading: Icon(
                            Icons.location_on_outlined,
                            color: Colors.orange.shade700,
                          ),
                          title: Text(branch['name']),
                          subtitle: Text(branch['address']),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.phone_outlined,
                              color: Colors.green.shade700,
                            ),
                            onPressed: () => _callPhone(branch['phone']),
                          ),
                          onTap: () => _showBranchDetails(branch),
                        )),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text(tr('close')),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
        break;
      case 'branch':
        _showBranchDetails(item);
        break;
    }
  }

  void _showBranchDetails(Map<String, dynamic> branch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(branch['name']),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(Icons.local_pharmacy_outlined,
                    color: Colors.green.shade700),
                title: Text(tr('pharmacy')),
                subtitle: Text(branch['pharmacyName']),
              ),
              ListTile(
                leading: Icon(Icons.location_on_outlined,
                    color: Colors.orange.shade700),
                title: Text(tr('address')),
                subtitle: Text(branch['address']),
              ),
              ListTile(
                leading:
                    Icon(Icons.phone_outlined, color: Colors.blue.shade700),
                title: Text(tr('phone')),
                subtitle: Text(branch['phone']),
                onTap: () => _callPhone(branch['phone']),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text(tr('close')),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
