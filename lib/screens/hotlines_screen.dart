import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class HotlinesScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  HotlinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('hotlines')),
        backgroundColor: const Color(0xFF6A1B9A),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3E5F5),
              Colors.white,
            ],
          ),
        ),
        child: _buildPharmaciesList(),
      ),
    );
  }

  Widget _buildPharmaciesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('pharmacies').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                tr('error_loading_data'),
                style: TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A1B9A)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              tr('no_pharmacies_found'),
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        final pharmacies = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: pharmacies.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildPharmacyCard(pharmacies[index]);
          },
        );
      },
    );
  }

  Widget _buildPharmacyCard(QueryDocumentSnapshot pharmacy) {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('pharmacies')
          .doc(pharmacy.id)
          .collection('branches')
          .get(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final hasError = snapshot.hasError;
        final branches = snapshot.data?.docs ?? [];

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Color(0xFF6A1B9A).withOpacity(0.2),
              child: Icon(
                FontAwesomeIcons.store,
                color: Color(0xFF6A1B9A),
                size: 20,
              ),
            ),
            title: Text(
              pharmacy['name'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A1B9A),
                fontSize: 16,
              ),
            ),
            subtitle: isLoading
                ? null
                : Text(
                    '${branches.length} ${tr('branches')}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
            children: [
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF6A1B9A)),
                    ),
                  ),
                )
              else if (hasError)
                ListTile(
                  title: Text(
                    tr('error_loading_branches'),
                    style: TextStyle(color: Colors.red),
                  ),
                )
              else if (branches.isEmpty)
                ListTile(
                  title: Text(
                    tr('no_branches_found'),
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...branches.map((branch) {
                  return _buildBranchTile(branch);
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBranchTile(QueryDocumentSnapshot branch) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(0xFF6A1B9A).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          FontAwesomeIcons.mapMarkerAlt,
          color: Color(0xFF6A1B9A),
          size: 18,
        ),
      ),
      title: Text(
        branch['name'],
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (branch['address'] != null && branch['address'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      branch['address'],
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          if (branch['phone'] != null && branch['phone'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    branch['phone'],
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
      trailing: branch['phone'] != null && branch['phone'].isNotEmpty
          ? IconButton(
              icon: Icon(Icons.call, color: Color(0xFF6A1B9A)),
              onPressed: () => _makePhoneCall(branch['phone']),
            )
          : null,
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

// import 'package:flutter/material.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// class HotlinesScreen extends StatelessWidget {
//   final List<Map<String, dynamic>> pharmacies = [
//     // 19011 Pharmacy Chain with branches
//     {
//       "name": "19011 Pharmacy",
//       "branches": [
//         {
//           "name": "Fifth Settlement",
//           "phone": "19011",
//           "address": "Cairo - Fifth Settlement"
//         },
//         {
//           "name": "Heliopolis",
//           "phone": "19011",
//           "address": "Cairo - Heliopolis"
//         },
//         {
//           "name": "Mohandessin",
//           "phone": "19011",
//           "address": "Cairo - Mohandessin"
//         },
//         {"name": "Maadi", "phone": "19011", "address": "Cairo - Maadi"},
//         {"name": "Nasr City", "phone": "19011", "address": "Cairo - Nasr City"},
//         {"name": "Haram", "phone": "19011", "address": "Giza - Haram"},
//         {"name": "Dokki", "phone": "19011", "address": "Giza - Dokki"},
//         {
//           "name": "6th of October",
//           "phone": "19011",
//           "address": "Giza - 6th of October"
//         },
//         {
//           "name": "First Settlement",
//           "phone": "19011",
//           "address": "Cairo - First Settlement"
//         },
//         {
//           "name": "Sheikh Zayed",
//           "phone": "19011",
//           "address": "Giza - Sheikh Zayed"
//         },
//       ]
//     },
//     // El-Dawaa Pharmacy Chain
//     {
//       "name": "El-Dawaa Pharmacy",
//       "branches": [
//         {"name": "Maadi", "phone": "16168", "address": "Cairo - Maadi"},
//         {"name": "Nasr City", "phone": "16168", "address": "Cairo - Nasr City"},
//         {
//           "name": "Heliopolis",
//           "phone": "16168",
//           "address": "Cairo - Heliopolis"
//         },
//         {
//           "name": "Mohandessin",
//           "phone": "16168",
//           "address": "Cairo - Mohandessin"
//         },
//         {"name": "Giza", "phone": "16168", "address": "Giza - Dokki"},
//         {
//           "name": "Alexandria",
//           "phone": "16168",
//           "address": "Alexandria - Smouha"
//         },
//         {"name": "Mahalla", "phone": "16168", "address": "Gharbia - Mahalla"},
//         {
//           "name": "Beni Suef",
//           "phone": "16168",
//           "address": "Beni Suef - Post Street"
//         },
//         {
//           "name": "Mansoura",
//           "phone": "16168",
//           "address": "Dakahlia - Mansoura"
//         },
//       ]
//     },
//     // Al Azbey Pharmacy Chain
//     {
//       "name": "Al Azbey Pharmacy",
//       "branches": [
//         {"name": "Shubra", "phone": "19011", "address": "Cairo - Shubra"},
//         {"name": "Maadi", "phone": "19011", "address": "Cairo - Maadi"},
//         {
//           "name": "Heliopolis",
//           "phone": "19011",
//           "address": "Cairo - Heliopolis"
//         },
//         {
//           "name": "Mohandessin",
//           "phone": "19011",
//           "address": "Cairo - Mohandessin"
//         },
//         {"name": "Dokki", "phone": "19011", "address": "Giza - Dokki"},
//         {
//           "name": "6th of October",
//           "phone": "19011",
//           "address": "Giza - 6th of October"
//         },
//         {"name": "Nasr City", "phone": "19011", "address": "Cairo - Nasr City"},
//         {
//           "name": "Fifth Settlement",
//           "phone": "19011",
//           "address": "Cairo - Fifth Settlement"
//         },
//         {
//           "name": "Sheikh Zayed",
//           "phone": "19011",
//           "address": "Giza - Sheikh Zayed"
//         },
//       ]
//     },
//     // Sehaty Pharmacy Chain
//     {
//       "name": "Sehaty Pharmacy",
//       "branches": [
//         {
//           "name": "Mohandessin",
//           "phone": "16168",
//           "address": "Cairo - Mohandessin"
//         },
//         {"name": "Maadi", "phone": "16168", "address": "Cairo - Maadi"},
//         {"name": "Nasr City", "phone": "16168", "address": "Cairo - Nasr City"},
//         {
//           "name": "Heliopolis",
//           "phone": "16168",
//           "address": "Cairo - Heliopolis"
//         },
//         {"name": "Haram", "phone": "16168", "address": "Giza - Haram"},
//         {
//           "name": "6th of October",
//           "phone": "16168",
//           "address": "Giza - 6th of October"
//         },
//         {
//           "name": "First Settlement",
//           "phone": "16168",
//           "address": "Cairo - First Settlement"
//         },
//       ]
//     },
//     // United Pharmacy Chain
//     {
//       "name": "United Pharmacy",
//       "branches": [
//         {
//           "name": "Mohandessin",
//           "phone": "19011",
//           "address": "Cairo - Mohandessin"
//         },
//         {"name": "Maadi", "phone": "19011", "address": "Cairo - Maadi"},
//         {"name": "Nasr City", "phone": "19011", "address": "Cairo - Nasr City"},
//         {
//           "name": "Heliopolis",
//           "phone": "19011",
//           "address": "Cairo - Heliopolis"
//         },
//         {"name": "Giza", "phone": "19011", "address": "Giza - Dokki"},
//         {
//           "name": "Alexandria",
//           "phone": "19011",
//           "address": "Alexandria - Smouha"
//         },
//         {
//           "name": "Mansoura",
//           "phone": "19011",
//           "address": "Dakahlia - Mansoura"
//         },
//       ]
//     },
//     // Misr Pharmacies
//     {
//       "name": "Misr Pharmacy",
//       "branches": [
//         {
//           "name": "Mohandessin",
//           "phone": "16250",
//           "address": "Cairo - Mohandessin"
//         },
//         {"name": "Shubra", "phone": "16250", "address": "Cairo - Shubra"},
//         {"name": "Dokki", "phone": "16250", "address": "Giza - Dokki"},
//         {"name": "Nasr City", "phone": "16250", "address": "Cairo - Nasr City"},
//         {"name": "Maadi", "phone": "16250", "address": "Cairo - Maadi"},
//         {
//           "name": "Alexandria",
//           "phone": "16250",
//           "address": "Alexandria - Smouha"
//         },
//         {"name": "Tanta", "phone": "16250", "address": "Gharbia - Tanta"},
//         {
//           "name": "Assiut",
//           "phone": "16250",
//           "address": "Assiut - Republic Street"
//         },
//       ]
//     },
//     // Rashdy Pharmacy (Alexandria)
//     {
//       "name": "Rashdy Pharmacy",
//       "branches": [
//         {"name": "Rashdy", "phone": "16610", "address": "Alexandria - Rashdy"},
//         {"name": "Smouha", "phone": "16610", "address": "Alexandria - Smouha"},
//         {
//           "name": "San Stefano",
//           "phone": "16610",
//           "address": "Alexandria - San Stefano"
//         },
//         {
//           "name": "Moharram Bek",
//           "phone": "16610",
//           "address": "Alexandria - Moharram Bek"
//         },
//       ]
//     },
//     // Farma Food Pharmacy (Alexandria)
//     {
//       "name": "Farma Food Pharmacy",
//       "branches": [
//         {"name": "Smouha", "phone": "16003", "address": "Alexandria - Smouha"},
//         {
//           "name": "Burg Al Arab",
//           "phone": "16003",
//           "address": "Alexandria - Burg Al Arab"
//         },
//         {"name": "Miami", "phone": "16003", "address": "Alexandria - Miami"},
//       ]
//     },
//     // Pfizer Pharmacy (Cairo)
//     {
//       "name": "Pfizer Pharmacy",
//       "branches": [
//         {
//           "name": "Mohandessin",
//           "phone": "16250",
//           "address": "Cairo - Mohandessin"
//         },
//         {"name": "Nasr City", "phone": "16250", "address": "Cairo - Nasr City"},
//         {
//           "name": "Heliopolis",
//           "phone": "16250",
//           "address": "Cairo - Heliopolis"
//         },
//         {
//           "name": "Fifth Settlement",
//           "phone": "16250",
//           "address": "Cairo - Fifth Settlement"
//         },
//       ]
//     },
//     // Dr. Wael Pharmacy (Alexandria)
//     {
//       "name": "Dr. Wael Pharmacy",
//       "branches": [
//         {
//           "name": "Corniche Beach",
//           "phone": "16677",
//           "address": "Alexandria - Corniche Beach"
//         },
//         {"name": "Zamalek", "phone": "16677", "address": "Cairo - Zamalek"},
//       ]
//     },
//     // Cetro Pharmacy (Cairo)
//     {
//       "name": "Cetro Pharmacy",
//       "branches": [
//         {
//           "name": "Heliopolis",
//           "phone": "16168",
//           "address": "Cairo - Heliopolis"
//         },
//         {"name": "Nasr City", "phone": "16168", "address": "Cairo - Nasr City"},
//         {"name": "Haram", "phone": "16168", "address": "Giza - Haram"},
//       ]
//     },
//     // El-Saedy Pharmacy
//     {
//       "name": "El-Saedy Pharmacy",
//       "branches": [
//         {
//           "name": "Tahrir Street",
//           "phone": "19191",
//           "address": "Cairo - Tahrir"
//         },
//         {"name": "Nasr City", "phone": "19191", "address": "Cairo - Nasr City"},
//         {"name": "Zamalek", "phone": "19191", "address": "Cairo - Zamalek"},
//       ]
//     },
//     // Misr International Pharmacy
//     {
//       "name": "Misr International Pharmacy",
//       "branches": [
//         {
//           "name": "Mohandessin",
//           "phone": "16350",
//           "address": "Cairo - Mohandessin"
//         },
//         {"name": "Maadi", "phone": "16350", "address": "Cairo - Maadi"},
//         {
//           "name": "Heliopolis",
//           "phone": "16350",
//           "address": "Cairo - Heliopolis"
//         },
//       ]
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           tr('hotlines'), // Using translation key for 'Hotlines'
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: Color(0xFF6A1B9A), // Elegant Purple for AppBar
//         elevation: 4,
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: ListView.builder(
//           itemCount: pharmacies.length,
//           itemBuilder: (context, index) {
//             final pharmacy = pharmacies[index];
//             return Card(
//               shape: RoundedRectangleBorder(
//                 borderRadius:
//                     BorderRadius.circular(20), // Rounded edges for cards
//               ),
//               color: Colors.white,
//               shadowColor: Colors.black.withOpacity(0.2),
//               margin: EdgeInsets.only(bottom: 15),
//               elevation: 5,
//               child: ExpansionTile(
//                 tilePadding: EdgeInsets.symmetric(horizontal: 20),
//                 title: Text(
//                   pharmacy['name'],
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF6A1B9A), // Elegant purple color
//                   ),
//                 ),
//                 leading: Icon(
//                   FontAwesomeIcons.store,
//                   color: Color(0xFF6A1B9A),
//                 ),
//                 children: pharmacy['branches'].map<Widget>((branch) {
//                   return ListTile(
//                     contentPadding: EdgeInsets.symmetric(horizontal: 25),
//                     leading: Icon(
//                       FontAwesomeIcons.mapMarkerAlt,
//                       color: Color(0xFF6A1B9A),
//                     ),
//                     title: Text(
//                       branch['name'],
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     subtitle: Text(
//                       branch['address'],
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                     trailing: Text(
//                       branch['phone'],
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Color(0xFF6A1B9A), // Matching text color
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
