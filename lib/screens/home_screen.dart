import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import 'admin_login_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List services = [];
  Map<String, dynamic> carData = {};

  bool loading = true;
  bool isBooking = false;

  int? selectedServiceId;
  String? selectedBrand;
  String? selectedModel;

  DateTime? selectedDateTime;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

@override
void initState() {
  super.initState();

  debugPrint(
    'Using API base URL: ${ApiService.baseUrl}',
  );

  loadServices();
  loadCars();
}

Future<void> launchPayment(int bookingId) async {
  try {
    final response = await http.post(
      Uri.parse(
        '${ApiService.baseUrl}/payments/initialize/$bookingId',
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final paymentUrl = data['payment_url'];

      await launchUrl(
        Uri.parse(paymentUrl),
        mode: LaunchMode.externalApplication,
      );
    } else {
      debugPrint(
        'Payment initialization failed: ${response.body}',
      );
    }
  } catch (e) {
    debugPrint('Payment error: $e');
  }
}

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

Future<void> loadServices() async {
  try {
    debugPrint(
      'Loading services from: ${ApiService.baseUrl}/services',
    );

    final res = await http.get(
      Uri.parse(
        '${ApiService.baseUrl}/services',
      ),
    );

    debugPrint(
      'Services status: ${res.statusCode}',
    );

    debugPrint(
      'Services body: ${res.body}',
    );

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);

      debugPrint(
        'Services count: ${decoded.length}',
      );

      setState(() {
        services = decoded;
        loading = false;
      });
    } else {
      debugPrint(
        'Failed to load services',
      );

      setState(() {
        loading = false;
      });
    }
  } catch (e) {
    debugPrint(
      'loadServices error: $e',
    );

    setState(() {
      loading = false;
    });
  }
}

Future<void> loadCars() async {
  try {
    debugPrint(
      'Loading cars from: ${ApiService.baseUrl}/cars',
    );

    final res = await http.get(
      Uri.parse(
        '${ApiService.baseUrl}/cars',
      ),
    );

    debugPrint(
      'Cars status: ${res.statusCode}',
    );

    debugPrint(
      'Cars body: ${res.body}',
    );

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);

      debugPrint(
        'Car brands: ${decoded.keys.toList()}',
      );

      setState(() {
        carData = decoded;
      });
    } else {
      debugPrint(
        'Failed to load cars',
      );
    }
  } catch (e) {
    debugPrint(
      'loadCars error: $e',
    );
  }
}

  Future<void> pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
      ),
    );
  }

Future<void> bookService() async {
  if (nameController.text.isEmpty ||
      emailController.text.isEmpty ||
      phoneController.text.isEmpty ||
      selectedBrand == null ||
      selectedModel == null ||
      selectedServiceId == null ||
      selectedDateTime == null) {
    showMessage("Please complete all fields");
    return;
  }

  final res = await http.post(
    Uri.parse("${ApiService.baseUrl}/book"),
    headers: {
      "Content-Type": "application/json",
    },
    body: json.encode({
      "customer_name": nameController.text,
      "email": emailController.text.trim(),
      "phone_number": phoneController.text,
      "service_id": selectedServiceId,
      "booking_time": selectedDateTime!.toIso8601String(),
      "car_brand": selectedBrand,
      "car_model": selectedModel,
    }),
  );

  print("STATUS: ${res.statusCode}");
  print("BODY: ${res.body}");

  if (res.statusCode == 200) {
    final data = json.decode(res.body);

    final bookingId = data["booking_id"];

    if (bookingId == null) {
      showMessage(
        "Booking created, but payment could not start.",
      );
      return;
    }

    showMessage(
      "Booking created successfully. Redirecting to Paystack for payment...",
    );

    await Future.delayed(
      const Duration(seconds: 2),
    );

    await launchPayment(bookingId);

    setState(() {
      selectedServiceId = null;
      selectedBrand = null;
      selectedModel = null;
      selectedDateTime = null;
    });

    nameController.clear();
    emailController.clear();
    phoneController.clear();
  } else {
    showMessage("Booking failed: ${res.body}");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Car Wash Booking"),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.admin_panel_settings,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AdminLoginScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.brightness_6,
            ),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Customer Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(),
              ),
            ),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email Address",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: selectedBrand,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              hint: const Text(
                "Select Car Brand",
              ),
              items: carData.keys
                  .map<DropdownMenuItem<String>>(
                    (brand) =>
                        DropdownMenuItem(
                      value: brand,
                      child: Text(brand),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedBrand = value;
                  selectedModel = null;
                });
              },
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: selectedModel,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              hint: const Text(
                "Select Car Model",
              ),
              items: selectedBrand != null
                  ? (carData[selectedBrand]
                          as List)
                      .map<
                          DropdownMenuItem<
                              String>>(
                        (model) =>
                            DropdownMenuItem(
                          value: model,
                          child: Text(model),
                        ),
                      )
                      .toList()
                  : [],
              onChanged: (value) {
                setState(() {
                  selectedModel = value;
                });
              },
            ),

            const SizedBox(height: 15),

            loading
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<int>(
                    value: selectedServiceId,
                    decoration:
                        const InputDecoration(
                      border:
                          OutlineInputBorder(),
                    ),
                    hint: const Text(
                      "Select Service",
                    ),
                    items: services.map(
                      (service) {
                        return DropdownMenuItem<
                            int>(
                          value:
                              service["id"],
                          child: Text(
                            "${service["name"]} - ₦${service["price"]}",
                          ),
                        );
                      },
                    ).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedServiceId =
                            value;
                      });
                    },
                  ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: pickDateTime,
              child: Text(
                selectedDateTime == null
                    ? "Select Date & Time"
                    : selectedDateTime
                        .toString(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: bookService,
                child:
                    const Text("Book Service"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}