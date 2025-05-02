// import 'package:flutter/material.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'medications_screen.dart';
// import 'pharmacies_screen.dart';
// import 'hotlines_screen.dart';
// import 'search_screen.dart';

// class HomeScreen extends StatelessWidget {
//   final bool isAdmin;
//   final List<String> pharmacies;
//   final List<String> medications;

//   const HomeScreen({
//     super.key,
//     required this.isAdmin,
//     required this.pharmacies,
//     required this.medications,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDarkMode = theme.brightness == Brightness.dark;

//     // Color scheme
//     const primaryPurple = Color(0xFF7E57C2);
//     const backgroundGray = Color(0xFFF5F5F5);

//     return Scaffold(
//       backgroundColor: isDarkMode ? Colors.grey[900] : backgroundGray,
//       body: CustomScrollView(
//         physics: const BouncingScrollPhysics(),
//         slivers: [
//           SliverAppBar(
//             expandedHeight: 220,
//             pinned: true,
//             flexibleSpace: FlexibleSpaceBar(
//               title: Column(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Text(
//                     tr('app_name'),
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 26,
//                       shadows: [
//                         Shadow(
//                           blurRadius: 8.0,
//                           color: Colors.black.withOpacity(0.5),
//                           offset: Offset(2.0, 2.0),
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(height: 6),
//                   Text(
//                     tr('app_subtitle'),
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.95),
//                       fontSize: 14,
//                       shadows: [
//                         Shadow(
//                           blurRadius: 4.0,
//                           color: Colors.black.withOpacity(0.3),
//                           offset: Offset(1.0, 1.0),
//                         ),
//                       ],
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//               centerTitle: true,
//               background: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [primaryPurple, Color(0xFF42A5F5)],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                 ),
//                 child: Stack(
//                   children: [
//                     Positioned(
//                       right: 30,
//                       bottom: 30,
//                       child: Opacity(
//                         opacity: 0.15,
//                         child: Icon(
//                           FontAwesomeIcons.heartPulse,
//                           size: 100,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             tr('welcome'),
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.w600,
//                               fontSize: 20,
//                             ),
//                           ),
//                           SizedBox(height: 8),
//                           Container(
//                             padding: EdgeInsets.symmetric(
//                                 horizontal: 12, vertical: 6),
//                             decoration: BoxDecoration(
//                               color: primaryPurple.withOpacity(0.7),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Text(
//                               tr('home_description'),
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             backgroundColor: primaryPurple,
//           ),
//           SliverPadding(
//             padding: const EdgeInsets.all(16.0),
//             sliver: SliverList(
//               delegate: SliverChildListDelegate([
//                 // Search Card - Available for all users
//                 _buildActionCard(
//                   context,
//                   leadingIcon: Icons.search,
//                   title: tr('search_medication_or_pharmacy'),
//                   color: primaryPurple,
//                   onTap: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => SearchScreen()),
//                   ),
//                 ),
//                 SizedBox(height: 24),

//                 // Medications Card - Available for all users
//                 _buildFeatureCard(
//                   context,
//                   icon: FontAwesomeIcons.pills,
//                   title: tr('medications'),
//                   subtitle: tr('browse_all_medications'),
//                   color: primaryPurple,
//                   onTap: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => MedicationsScreen(
//                         medications: medications,
//                         isAdmin: isAdmin,
//                       ),
//                     ),
//                   ),
//                 ),

//                 // Only show these cards for regular users (non-admin)
//                 if (!isAdmin) ...[
//                   SizedBox(height: 16),
//                   _buildFeatureCard(
//                     context,
//                     icon: FontAwesomeIcons.store,
//                     title: tr('pharmacies'),
//                     subtitle: tr('find_nearby_pharmacies'),
//                     color: Color(0xFF42A5F5),
//                     onTap: () => Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => PharmaciesScreen(),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 16),
//                   _buildFeatureCard(
//                     context,
//                     icon: FontAwesomeIcons.phoneAlt,
//                     title: tr('hotlines'),
//                     subtitle: tr('emergency_contacts'),
//                     color: Color(0xFF66BB6A),
//                     onTap: () => Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => HotlinesScreen(),
//                       ),
//                     ),
//                   ),
//                 ],
//               ]),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionCard(
//     BuildContext context, {
//     required IconData leadingIcon,
//     required String title,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(12),
//         onTap: onTap,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Row(
//             children: [
//               Icon(leadingIcon, color: color, size: 28),
//               SizedBox(width: 16),
//               Expanded(
//                 child: Text(
//                   title,
//                   style: TextStyle(
//                     color: Theme.of(context).textTheme.bodyLarge?.color,
//                     fontSize: 16,
//                   ),
//                 ),
//               ),
//               Icon(Icons.chevron_right, color: color, size: 24),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildFeatureCard(
//     BuildContext context, {
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(12),
//         onTap: onTap,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Row(
//             children: [
//               Container(
//                 width: 48,
//                 height: 48,
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.15),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(icon, color: color, size: 24),
//               ),
//               SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 16,
//                         color: Theme.of(context).textTheme.bodyLarge?.color,
//                       ),
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                       subtitle,
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Theme.of(context)
//                             .textTheme
//                             .bodyMedium
//                             ?.color
//                             ?.withOpacity(0.7),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Icon(Icons.chevron_right, color: color, size: 24),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'medications_screen.dart';
import 'pharmacies_screen.dart';
import 'hotlines_screen.dart';
import 'search_screen.dart';
import 'pharmacy_inventory_screen.dart';

class HomeScreen extends StatelessWidget {
  final bool isAdmin;
  final List<String> pharmacies;
  final List<String> medications;

  const HomeScreen({
    super.key,
    required this.isAdmin,
    required this.pharmacies,
    required this.medications,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Color scheme
    const primaryPurple = Color(0xFF7E57C2);
    const backgroundGray = Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : backgroundGray,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    tr('app_name'),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                      shadows: [
                        Shadow(
                          blurRadius: 8.0,
                          color: Colors.black.withOpacity(0.5),
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    tr('app_subtitle'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 14,
                      shadows: [
                        Shadow(
                          blurRadius: 4.0,
                          color: Colors.black.withOpacity(0.3),
                          offset: Offset(1.0, 1.0),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryPurple, Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 30,
                      bottom: 30,
                      child: Opacity(
                        opacity: 0.15,
                        child: Icon(
                          FontAwesomeIcons.heartPulse,
                          size: 100,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('welcome'),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryPurple.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tr('home_description'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            backgroundColor: primaryPurple,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Search Card - Available for all users
                _buildActionCard(
                  context,
                  leadingIcon: Icons.search,
                  title: tr('search_medication_or_pharmacy'),
                  color: primaryPurple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SearchScreen()),
                  ),
                ),
                SizedBox(height: 24),

                // Medications Card - Available for all users
                _buildFeatureCard(
                  context,
                  icon: FontAwesomeIcons.pills,
                  title: tr('medications'),
                  subtitle: tr('browse_all_medications'),
                  color: primaryPurple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MedicationsScreen(
                        medications: medications,
                        isAdmin: isAdmin,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Partner Pharmacies Card - Available for all users
                _buildFeatureCard(
                  context,
                  icon: FontAwesomeIcons.handshake,
                  title: tr('partner_pharmacies'),
                  subtitle: tr('view_medication_availability'),
                  color: Color(0xFFAB47BC), // Light purple color
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PharmacyInventoryScreen()),
                  ),
                ),

                // Only show these cards for regular users (non-admin)
                if (!isAdmin) ...[
                  SizedBox(height: 16),
                  _buildFeatureCard(
                    context,
                    icon: FontAwesomeIcons.store,
                    title: tr('pharmacies'),
                    subtitle: tr('find_nearby_pharmacies'),
                    color: Color(0xFF42A5F5),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PharmaciesScreen()),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildFeatureCard(
                    context,
                    icon: FontAwesomeIcons.phoneAlt,
                    title: tr('hotlines'),
                    subtitle: tr('emergency_contacts'),
                    color: Color(0xFF66BB6A),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HotlinesScreen()),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData leadingIcon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(leadingIcon, color: color, size: 28),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
