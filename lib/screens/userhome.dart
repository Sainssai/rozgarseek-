import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:razgorsek/screens/authentication.dart';
import 'package:razgorsek/screens/chatscreen.dart';
import 'package:razgorsek/screens/helpdeskscreen.dart';
import 'dart:math';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class UserHomePage extends StatefulWidget {
  final String userName;
  const UserHomePage({super.key, required this.userName});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _currentIndex = 0;

  final List<String> services = [
    'Plumber',
    'Electrician',
    'AC Repair',
    'Carpenter',
    'Painter',
    'Cleaner',
    'Mechanic',
    'Gardener',
    'Cook',
    'Tutor',
  ];

  final Map<String, IconData> serviceIcons = {
    'Plumber': Icons.plumbing,
    'Electrician': Icons.electrical_services,
    'AC Repair': Icons.ac_unit,
    'Carpenter': Icons.chair_alt,
    'Painter': Icons.format_paint,
    'Cleaner': Icons.cleaning_services,
    'Mechanic': Icons.build,
    'Gardener': Icons.grass,
    'Cook': Icons.restaurant_menu,
    'Tutor': Icons.school,
  };

  final Map<String, double> basePrices = {
    'Plumber': 450,
    'Electrician': 500,
    'AC Repair': 600,
    'Carpenter': 400,
    'Painter': 350,
    'Cleaner': 300,
    'Mechanic': 450,
    'Gardener': 250,
    'Cook': 400,
    'Tutor': 500,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_getTitle().tr)),
      drawer: _buildDrawer(),
      body: _getSelectedPage(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.black87],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          iconSize: 28,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'home'.tr),
            BottomNavigationBarItem(
              icon: Icon(Icons.miscellaneous_services),
              label: 'services'.tr,
            ),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'chat'.tr),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'profile'.tr),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return "RozgarSeek - Home".tr;
      case 1:
        return "Our Services".tr;
      case 2:
        return "Your Chats".tr;
      case 3:
        return "Your Profile".tr;
      default:
        return "";
    }
  }

  Widget _getSelectedPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHome();
      case 1:
        return _buildServices(context);
      case 2:
        return _buildChats();
      case 3:
        return _buildProfileBody();
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildHome() {
    return Center(
      child: Card(
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.handshake, size: 60, color: Colors.deepPurple),
              const SizedBox(height: 20),
              Text(
                "Hi, ${widget.userName}!".trParams({'name': widget.userName}),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "Welcome to RozgarSeek 👋".tr,
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "Need help at home? Tap 'Services' below to find trusted professionals for any task.".tr,
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.miscellaneous_services),
                label: Text("Explore Services".tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  setState(() => _currentIndex = 1);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServices(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        String service = services[index];
        IconData icon = serviceIcons[service] ?? Icons.miscellaneous_services;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => Get.to(() => LocationSearchScreen(service: service)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: Colors.deepPurple),
                SizedBox(height: 10),
                Text(
                  service.tr,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChats() {
    final currentUserEmail = FirebaseAuth.instance.currentUser!.email!
        .toLowerCase();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUserEmail)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'.trParams({'error': snapshot.error.toString()})));
        }
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final chats = snapshot.data!.docs;

        if (chats.isEmpty) {
          return Center(child: Text('No chats with providers yet.'.tr));
        }

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final participants = chat['participants'] as List<dynamic>;
            final peerEmail = participants.firstWhere(
              (email) => email != currentUserEmail,
              orElse: () => '',
            );

            if (peerEmail.isEmpty) {
              return SizedBox.shrink();
            }

            return FutureBuilder<DocumentSnapshot?>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: peerEmail)
                  .where('role', isEqualTo: 'provider')
                  .get()
                  .then(
                    (snapshot) =>
                        snapshot.docs.isNotEmpty ? snapshot.docs.first : null,
                  )
                  .catchError((error) => null),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(
                    title: Text(peerEmail),
                    subtitle: Text('Loading...'.tr),
                    trailing: CircularProgressIndicator(),
                  );
                }
                if (!userSnapshot.hasData || userSnapshot.data == null) {
                  return SizedBox.shrink();
                }

                final peerData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final peerName = peerData['name'] ?? 'Provider'.tr;
                final lastMessage = chat['lastMessage'] ?? 'No messages'.tr;

                return ListTile(
                  leading: Icon(Icons.person, color: Colors.deepPurple),
                  title: Text(peerName),
                  subtitle: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(Icons.chat),
                  onTap: () {
                    Get.to(
                      () =>
                          ChatScreen(peerEmail: peerEmail, peerName: peerName),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildProfileBody() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        var data = snapshot.data!.data() as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Icon(Icons.person, size: 100, color: Colors.deepPurple)),
              SizedBox(height: 20),
              Text("Name: ${data['name']}".trParams({'name': data['name']}), style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              Text("Email: ${data['email']}".trParams({'email': data['email']}), style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              Text("Phone: ${data['phone']}".trParams({'phone': data['phone']}), style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.headset_mic, color: Colors.green),
                    label: Text('Help Desk'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightGreen[100],
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: () {
                      Get.to(() => HelpDeskScreen());
                    },
                  ),
                  Spacer(),
                  ElevatedButton.icon(
                    icon: Icon(Icons.receipt_long, color: Colors.deepPurple),
                    label: Text('My Orders'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple[50],
                      foregroundColor: Colors.deepPurple,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => DraggableScrollableSheet(
                          expand: false,
                          initialChildSize: 0.7,
                          minChildSize: 0.4,
                          maxChildSize: 0.95,
                          builder: (context, scrollController) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text('My Orders'.tr, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 12),
                                  Expanded(
                                    child: StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('bookings')
                                          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                                          .where('status', isEqualTo: 'success')
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return Center(child: CircularProgressIndicator());
                                        }
                                        final bookings = snapshot.data!.docs;
                                        if (bookings.isEmpty) {
                                          return Center(child: Text('No orders found.'.tr));
                                        }
                                        return ListView.builder(
                                          controller: scrollController,
                                          itemCount: bookings.length,
                                          itemBuilder: (context, index) {
                                            final booking = bookings[index];
                                            return FutureBuilder<DocumentSnapshot>(
                                              future: FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(booking['providerId'])
                                                  .get(),
                                              builder: (context, providerSnapshot) {
                                                if (!providerSnapshot.hasData) return SizedBox.shrink();
                                                var providerData = providerSnapshot.data!.data() as Map<String, dynamic>;
                                                return Card(
                                                  elevation: 4,
                                                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(16),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            CircleAvatar(
                                                              backgroundColor: Colors.deepPurple[100],
                                                              child: Icon(Icons.person, color: Colors.deepPurple),
                                                            ),
                                                            SizedBox(width: 12),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text(
                                                                    providerData['name'] ?? 'Provider'.tr,
                                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                                                  ),
                                                                  SizedBox(height: 2),
                                                                  Text(
                                                                    providerData['email'] ?? '',
                                                                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(height: 10),
                                                        Divider(),
                                                        SizedBox(height: 6),
                                                        Row(
                                                          children: [
                                                            Icon(Icons.miscellaneous_services, size: 18, color: Colors.deepPurple),
                                                            SizedBox(width: 6),
                                                            Text('Service: '.tr, style: TextStyle(fontWeight: FontWeight.bold)),
                                                            Text(booking['service'].toString().tr),
                                                          ],
                                                        ),
                                                        SizedBox(height: 6),
                                                        Row(
                                                          children: [
                                                            Icon(Icons.category, size: 18, color: Colors.deepPurple),
                                                            SizedBox(width: 6),
                                                            Text('Category: '.tr, style: TextStyle(fontWeight: FontWeight.bold)),
                                                            Text(providerData['category']?.toString().tr ?? ''),
                                                          ],
                                                        ),
                                                        SizedBox(height: 6),
                                                        Row(
                                                          children: [
                                                            Icon(Icons.attach_money, size: 18, color: Colors.deepPurple),
                                                            SizedBox(width: 6),
                                                            Text('Price: '.tr, style: TextStyle(fontWeight: FontWeight.bold)),
                                                            Text('₹${booking['price']}'),
                                                          ],
                                                        ),
                                                        SizedBox(height: 6),
                                                        Row(
                                                          children: [
                                                            Icon(Icons.receipt, size: 18, color: Colors.deepPurple),
                                                            SizedBox(width: 6),
                                                            Text('Transaction ID: '.tr, style: TextStyle(fontWeight: FontWeight.bold)),
                                                            Expanded(
                                                              child: Text(
                                                                booking['transactionId'],
                                                                overflow: TextOverflow.ellipsis,
                                                                style: TextStyle(fontSize: 13),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(height: 14),
                                                        SizedBox(
                                                          width: double.infinity,
                                                          child: ElevatedButton.icon(
                                                            icon: Icon(Icons.replay, color: Colors.red),
                                                            label: Text('Request Refund'.tr),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.red[50],
                                                              foregroundColor: Colors.red[900],
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                            ),
                                                            onPressed: () async {
                                                              Get.back();
                                                              await FirebaseFirestore.instance
                                                                  .collection('refundrequests')
                                                                  .add({
                                                                    'userId': FirebaseAuth.instance.currentUser!.uid,
                                                                    'bookingId': booking.id,
                                                                    'providerId': booking['providerId'],
                                                                    'service': booking['service'],
                                                                    'price': booking['price'],
                                                                    'transactionId': booking['transactionId'],
                                                                    'status': 'pending',
                                                                    'timestamp': FieldValue.serverTimestamp(),
                                                                  });
                                                              Get.snackbar('Success'.tr, 'Refund request submitted.'.tr);
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
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
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 8),
                ],
              ),
              Spacer(),
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.logout),
                  label: Text("Logout".tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Get.offAll(() => AuthScreen());
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurple),
            child: Text(
              "RozgarSeek".tr,
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text("Home".tr),
            onTap: () {
              setState(() => _currentIndex = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.miscellaneous_services),
            title: Text("Services".tr),
            onTap: () {
              setState(() => _currentIndex = 1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.chat),
            title: Text("Chats".tr),
            onTap: () {
              setState(() => _currentIndex = 2);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text("Profile".tr),
            onTap: () {
              setState(() => _currentIndex = 3);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text("Logout".tr),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Get.offAll(() => AuthScreen());
            },
          ),
        ],
      ),
    );
  }
}

class LocationSearchScreen extends StatefulWidget {
  final String service;
  const LocationSearchScreen({super.key, required this.service});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  String? selectedLocation;
  final List<String> cities = [
    'Hyderabad'.tr,
    'Bangalore'.tr,
    'Chennai'.tr,
    'Mumbai'.tr,
    'Kolkata'.tr,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Search ${widget.service} Providers".trParams({'service': widget.service}))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select City'.tr,
                border: OutlineInputBorder(),
              ),
              value: selectedLocation,
              items: cities
                  .map(
                    (city) => DropdownMenuItem(value: city, child: Text(city.tr)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => selectedLocation = value);
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedLocation == null
                  ? null
                  : () => Get.to(
                      () => ProviderListScreen(
                        service: widget.service,
                        location: selectedLocation!,
                      ),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Search Providers'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class ProviderListScreen extends StatelessWidget {
  final String service;
  final String location;

  const ProviderListScreen({
    super.key,
    required this.service,
    required this.location,
  });

  double getProviderPrice(String providerId, double basePrice) {
    final random = Random(providerId.hashCode);
    final variations = [-20, -10, 10, 20];
    final variation = variations[random.nextInt(variations.length)];
    return basePrice + variation;
  }

  double getProviderRating(String providerId, double price, double basePrice) {
    final random = Random(providerId.hashCode);
    final priceFactor = (price / basePrice).clamp(0.8, 1.2);
    final baseRating = 3.0 + (random.nextDouble() * 2.0);
    final rating = (baseRating * priceFactor).clamp(0.0, 5.5);
    return (rating * 10).round() / 10;
  }

  @override
  Widget build(BuildContext context) {
    final basePrice =
        {
          'Plumber': 450.0,
          'Electrician': 500.0,
          'AC Repair': 600.0,
          'Carpenter': 400.0,
          'Painter': 350.0,
          'Cleaner': 300.0,
          'Mechanic': 450.0,
          'Gardener': 250.0,
          'Cook': 400.0,
          'Tutor': 500.0,
        }[service] ??
        300.0;

    return Scaffold(
      appBar: AppBar(title: Text("$service Providers in $location".trParams({'service': service, 'location': location}))),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'provider')
            .where('category', isEqualTo: service)
            .where('location', isEqualTo: location)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'.trParams({'error': snapshot.error.toString()})));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final providers = snapshot.data!.docs;

          if (providers.isEmpty) {
            return Center(
              child: Text('No $service providers found in $location'.trParams({'service': service, 'location': location})),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              final providerId = provider.id;
              final providerData = provider.data() as Map<String, dynamic>;
              final providerName = providerData['name'] ?? 'Provider'.tr;
              final providerEmail = providerData['email'] ?? '';
              final isBooked = providerData['isBooked'] as bool? ?? false;
              final price = getProviderPrice(providerId, basePrice);
              final rating = getProviderRating(providerId, price, basePrice);

              return Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: Icon(Icons.person, color: Colors.deepPurple),
                  title: Text(providerName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(providerEmail, style: TextStyle(fontSize: 12)),
                      SizedBox(height: 2),
                      Text('Price: ₹${price.toStringAsFixed(0)}'.trParams({'price': price.toStringAsFixed(0)})),
                      SizedBox(height: 2),
                      Row(
                        children:
                            List.generate(
                              5,
                              (i) => Icon(
                                i < rating.floor()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              ),
                            )..add(
                              Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Text(
                                  '($rating)',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        isBooked ? 'Not Available'.tr : 'Available'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: isBooked ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chat, color: Colors.deepPurple),
                        onPressed: () {
                          Get.to(
                            () => ChatScreen(
                              peerEmail: providerEmail,
                              peerName: providerName,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.shopping_cart,
                          color: isBooked ? Colors.grey : Colors.green,
                        ),
                        onPressed: isBooked
                            ? null
                            : () {
                                Get.to(
                                  () => BookingConfirmationScreen(
                                    service: service,
                                    providerName: providerName,
                                    providerEmail: providerEmail,
                                    providerId: providerId,
                                    price: price,
                                  ),
                                );
                              },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class BookingConfirmationScreen extends StatefulWidget {
  final String service;
  final String providerName;
  final String providerEmail;
  final String providerId;
  final double price;

  const BookingConfirmationScreen({
    super.key,
    required this.service,
    required this.providerName,
    required this.providerEmail,
    required this.providerId,
    required this.price,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  late Razorpay _razorpay;
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadUserEmail();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _loadUserEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserEmail = user.email;
      });
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'providerId': widget.providerId,
        'service': widget.service,
        'price': widget.price,
        'transactionId': response.paymentId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'success',
      });
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.providerId)
          .update({'isBooked': true});
      Get.snackbar('Success'.tr, 'Payment successful! Booking confirmed.'.tr);
      Get.back();
    } catch (e) {
      Get.snackbar('Error'.tr, 'Failed to save booking: $e'.trParams({'error': e.toString()}));
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Get.snackbar('Error'.tr, 'Payment failed: ${response.message}'.trParams({'error': response.message ?? ''}));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Get.snackbar('Info'.tr, 'External wallet selected: ${response.walletName}'.trParams({'wallet': response.walletName ?? ''}));
  }

  Future<String?> _createRazorpayOrder() async {
    final String keyId = 'rzp_test_52dp1Z8qV4bxDM';
    final String keySecret = '5fbghfhOvpq1gur8mgQS1Sbk';
    final String authString = '$keyId:$keySecret';
    final String basicAuth = 'Basic ${base64.encode(utf8.encode(authString))}';

    final Map<String, dynamic> body = {
      'amount': (widget.price * 100).toInt(),
      'currency': 'INR',
      'receipt': 'receipt_${DateTime.now().millisecondsSinceEpoch}',
    };

    try {
      final response = await http.post(
        Uri.parse('https://api.razorpay.com/v1/orders'),
        headers: {
          'Authorization': basicAuth,
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final orderData = json.decode(response.body);
        return orderData['id'];
      } else {
        final errorData = json.decode(response.body);
        if (errorData['error']['code'] == 'BAD_REQUEST_ERROR' &&
            errorData['error']['description'] == 'Authentication failed') {
          Get.snackbar(
            'Error'.tr,
            'Authentication failed with key: $keyId. Verify network or contact Razorpay support.'.tr,
          );
        } else {
          Get.snackbar('Error'.tr, 'Failed to create order: ${response.body}'.trParams({'error': response.body}));
        }
        return null;
      }
    } catch (e) {
      Get.snackbar('Error'.tr, 'Network error: $e'.trParams({'error': e.toString()}));
      return null;
    }
  }

  void _openRazorpayCheckout(String orderId) {
    final options = {
      'key': 'rzp_test_52dp1Z8qV4bxDM',
      'amount': (widget.price * 100).toInt(),
      'currency': 'INR',
      'name': 'RozgarSeek',
      'description': 'Booking for ${widget.service}'.trParams({'service': widget.service}),
      'order_id': orderId,
      'prefill': {'email': _currentUserEmail ?? '', 'contact': ''},
      'theme': {'color': '#673AB7'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      Get.snackbar('Error'.tr, 'Failed to open Razorpay: $e'.trParams({'error': e.toString()}));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Confirm Booking".tr)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Details'.tr,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text('Service: ${widget.service}'.trParams({'service': widget.service}), style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text(
              'Provider: ${widget.providerName}'.trParams({'provider': widget.providerName}),
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Email: ${widget.providerEmail}'.trParams({'email': widget.providerEmail}),
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Price: ₹${widget.price.toStringAsFixed(0)}'.trParams({'price': widget.price.toStringAsFixed(0)}),
              style: TextStyle(fontSize: 18),
            ),
            Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final orderId = await _createRazorpayOrder();
                  if (orderId != null) {
                    _openRazorpayCheckout(orderId);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('Confirm Booking'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}