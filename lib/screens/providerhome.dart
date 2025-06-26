import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razgorsek/screens/authentication.dart';
import 'package:razgorsek/screens/providerchart.dart';

// Provider Profile Screen with simple terms
class ProviderProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text("You are not signed in".tr));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text("Provider info not found.".tr));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        if (data['role'] != 'provider') {
          return Center(child: Text("This is not a provider account.".tr));
        }

        final name = data['name'] ?? 'Your Name'.tr;
        final email = data['email'] ?? 'your@email.com';
        final phone = data['phone'] ?? 'No phone number'.tr;

        return Center(
          child: Card(
            margin: EdgeInsets.all(24),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.person, size: 48, color: Colors.blue),
                  ),
                  SizedBox(height: 16),
                  Text(
                    name,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(email, style: TextStyle(color: Colors.grey[700])),
                  SizedBox(height: 8),
                  Text(phone, style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Provider Services Screen with simple terms
class ProviderServicesScreen extends StatelessWidget {
  const ProviderServicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text("You are not signed in".tr));
    }

    final bookingsRef = FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: user.email);

    return StreamBuilder<QuerySnapshot>(
      stream: bookingsRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No bookings yet.".tr));
        }

        final bookings = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Your Bookings (${bookings.length})".trParams({
                  "count": bookings.length.toString(),
                }),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: bookings.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final userId = booking['userId'] ?? '';

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData ||
                            userSnapshot.data == null) {
                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Icon(Icons.person, color: Colors.blue),
                              ),
                              title: Text('Loading...'.tr),
                            ),
                          );
                        }
                        final userData =
                            userSnapshot.data!.data()
                                as Map<String, dynamic>? ??
                            {};
                        final userName = userData['name'] ?? 'Unknown User'.tr;
                        final userEmail = userData['email'] ?? '';
                        final service = userData['category'] ?? 'Service'.tr;

                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Icon(Icons.person, color: Colors.blue),
                            ),
                            title: Text(
                              userName,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Email: $userEmail".trParams({
                                    "email": userEmail,
                                  }),
                                ),
                                Text(
                                  "Service: $service".trParams({
                                    "service": service,
                                  }),
                                ),
                              ],
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                              color: Colors.blue,
                            ),
                            onTap: () {
                              // Show more details if needed
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProviderHomePage extends StatefulWidget {
  const ProviderHomePage({super.key});

  @override
  State<ProviderHomePage> createState() => _ProviderHomePageState();
}

class _ProviderHomePageState extends State<ProviderHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    ProviderChatList(),
    ProviderProfileScreen(),
    ProviderServicesScreen(),
  ];

  final List<String> _titles = [
    "Messages".tr,
    "My Profile".tr,
    "My Bookings".tr,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Sign Out'.tr,
            onPressed: () async {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'Are you sure you want to logout?'.tr,
                    style: TextStyle(fontSize: 16),
                  ),
                  actions: [
                    TextButton(
                      child: Text(
                        'Cancel'.tr,
                        style: TextStyle(color: Colors.grey),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: Text(
                        'Logout'.tr,
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await FirebaseAuth.instance.signOut();
                        Get.offAll(() => AuthScreen());
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: Icon(Icons.help_outline, color: Colors.blue),
                  label: Text(
                    "Contact Support".tr,
                    style: TextStyle(color: Colors.blue),
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: Size(0, 48),
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: () {
                    Get.to(() => ProviderToAdminChatScreen());
                  },
                ),
              ),
            ),
          ),
          BottomNavigationBar(
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            elevation: 12,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                label: 'Messages'.tr,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Profile'.tr,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.miscellaneous_services_outlined),
                label: 'Bookings'.tr,
              ),
            ],
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ],
      ),
    );
  }
}
