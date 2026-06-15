import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import 'service_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String token;

  const AdminDashboardScreen({
    super.key,
    required this.token,
  });

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  List bookings = [];

  int totalBookings = 0;
  int todayBookings = 0;
  int totalRevenue = 0;

  Map<String, dynamic> carData = {};

  String? selectedBrand;
  String? selectedType;

  bool isLoading = true;

  Timer? refreshTimer;

  final searchController = TextEditingController();

  List get filteredBookings {
    if (searchController.text.isEmpty) {
      return bookings;
    }

    final query = searchController.text.toLowerCase();

    return bookings.where((booking) {
      return booking["name"]
              .toString()
              .toLowerCase()
              .contains(query) ||
          booking["phone_number"]
              .toString()
              .toLowerCase()
              .contains(query) ||
          booking["car_brand"]
              .toString()
              .toLowerCase()
              .contains(query) ||
          booking["car_model"]
              .toString()
              .toLowerCase()
              .contains(query);
    }).toList();
  }
  @override
  void initState() {
    super.initState();

    loadCars();
    fetchBookings();

    refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => fetchBookings(),
    );
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadCars() async {
    try {
      final response = await http.get(
        Uri.parse(
          "${ApiService.baseUrl}/cars",
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          carData = json.decode(response.body);
        });
      }
    } catch (_) {}
  }

  Future<void> fetchBookings() async {
    setState(() {
      isLoading = true;
    });

    try {
      String url =
          "${ApiService.baseUrl}/admin/bookings?token=${widget.token}";

      if (selectedBrand != null) {
        url += "&brand=$selectedBrand";
      }

      if (selectedType != null) {
        url += "&car_type=$selectedType";
      }

      final response = await http.get(
        Uri.parse(url),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          bookings = data["bookings"];
          totalBookings = data["total_bookings"];
          todayBookings = data["today_bookings"];
          totalRevenue = data["total_revenue"];
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateStatus(int bookingId) async {
    try {
      await http.put(
        Uri.parse(
          "${ApiService.baseUrl}/admin/update_status/$bookingId?token=${widget.token}",
        ),
      );

      fetchBookings();
    } catch (_) {}
  }

  Widget statCard(
    String title,
    String value,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.miscellaneous_services,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ServiceManagementScreen(
                    token: widget.token,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child:
                      DropdownButtonFormField<
                          String>(
                    value: selectedBrand,
                    decoration:
                        const InputDecoration(
                      labelText: "Brand",
                      border:
                          OutlineInputBorder(),
                    ),
                    items: carData.keys
                        .map<
                            DropdownMenuItem<
                                String>>(
                      (brand) =>
                          DropdownMenuItem(
                        value: brand,
                        child: Text(
                          brand,
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedBrand =
                            value;
                      });

                      fetchBookings();
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child:
                      DropdownButtonFormField<
                          String>(
                    value: selectedType,
                    decoration:
                        const InputDecoration(
                      labelText: "Car Type",
                      border:
                          OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "SUV",
                        child: Text("SUV"),
                      ),
                      DropdownMenuItem(
                        value: "Sedan",
                        child: Text("Sedan"),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedType =
                            value;
                      });

                      fetchBookings();
                    },
                  ),
                ),
              ],
            ),
          ),

          Row(
            children: [
              statCard(
                "Total",
                totalBookings.toString(),
              ),
              statCard(
                "Today",
                todayBookings.toString(),
              ),
              statCard(
                "Revenue",
                "₦$totalRevenue",
              ),
            ],
          ),

          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : filteredBookings.isEmpty
                    ? const Center(
                        child: Text(
                          "No matching bookings found",
                        ),
                      )
                    : ListView.builder(
                    itemCount:
                        filteredBookings.length,
                    itemBuilder:
                        (context, index) {
                      final booking =
                          filteredBookings[index];

                      return Card(
                        margin:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(
                            booking["name"],
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                "Phone: ${booking["phone_number"]}",
                              ),
                              Text(
                                booking[
                                    "service"],
                              ),
                              Text(
                                "₦${booking["amount"]}",
                              ),
                              Text(
                                "${booking["car_brand"]} - ${booking["car_model"]}",
                              ),
                              Text(
                                "Type: ${booking["car_type"]}",
                              ),
                              Text(
                                booking[
                                    "booking_time"],
                              ),
                              Text(
                                "Status: ${booking["status"]}",
                              ),
                            ],
                          ),
                          trailing: booking[
                                      "status"] ==
                                  "service_pending"
                              ? ElevatedButton(
                                  onPressed:
                                      () =>
                                          updateStatus(
                                    booking[
                                        "id"],
                                  ),
                                  child:
                                      const Text(
                                    "Complete",
                                  ),
                                )
                              : const Icon(
                                  Icons.check,
                                  color:
                                      Colors.green,
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}