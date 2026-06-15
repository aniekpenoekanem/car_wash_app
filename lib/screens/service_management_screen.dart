import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';

class ServiceManagementScreen extends StatefulWidget {
  final String token;

  const ServiceManagementScreen({
    super.key,
    required this.token,
  });

  @override
  State<ServiceManagementScreen> createState() =>
      _ServiceManagementScreenState();
}

class _ServiceManagementScreenState
    extends State<ServiceManagementScreen> {
  List services = [];

  bool isLoading = true;

  final nameController = TextEditingController();
  final priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> fetchServices() async {
    try {
      final response = await http.get(
        Uri.parse(
          "${ApiService.baseUrl}/services",
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          services = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        isLoading = false;
      });

      showMessage("Failed to load services");
    }
  }

  Future<void> addService() async {
    if (nameController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty) {
      showMessage("Fill all fields");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
          "${ApiService.baseUrl}/services",
        ),
        headers: {
          "Content-Type": "application/json",
        },
        body: json.encode({
          "name": nameController.text.trim(),
          "price": double.parse(
            priceController.text.trim(),
          ),
        }),
      );

      if (response.statusCode == 200) {
        nameController.clear();
        priceController.clear();

        fetchServices();

        showMessage("Service added");
      }
    } catch (_) {
      showMessage("Failed to add service");
    }
  }

  Future<void> deleteService(int id) async {
    try {
      await http.delete(
        Uri.parse(
          "${ApiService.baseUrl}/services/$id",
        ),
      );

      fetchServices();

      showMessage("Service deleted");
    } catch (_) {
      showMessage("Failed to delete service");
    }
  }

  Future<void> editService(
    int id,
    String currentName,
    double currentPrice,
  ) async {
    final editNameController =
        TextEditingController(text: currentName);

    final editPriceController =
        TextEditingController(
      text: currentPrice.toString(),
    );

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Service"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editNameController,
              decoration: const InputDecoration(
                labelText: "Service Name",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: editPriceController,
              keyboardType:
                  TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Price",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final response = await http.put(
                  Uri.parse(
                    "${ApiService.baseUrl}/services/$id",
                  ),
                  headers: {
                    "Content-Type":
                        "application/json",
                  },
                  body: json.encode({
                    "name":
                        editNameController.text
                            .trim(),
                    "price": double.parse(
                      editPriceController.text
                          .trim(),
                    ),
                  }),
                );

                if (response.statusCode == 200) {
                  if (!mounted) return;

                  Navigator.pop(context);

                  fetchServices();

                  showMessage(
                    "Service updated",
                  );
                }
              } catch (_) {
                showMessage(
                  "Failed to update service",
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );

    editNameController.dispose();
    editPriceController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Manage Services"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(
                labelText: "Service Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration:
                  const InputDecoration(
                labelText: "Price",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: addService,
                child: const Text(
                  "Add Service",
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      itemCount:
                          services.length,
                      itemBuilder:
                          (context, index) {
                        final service =
                            services[index];

                        return Card(
                          child: ListTile(
                            title: Text(
                              service["name"],
                            ),
                            subtitle: Text(
                              "₦${service["price"]}",
                            ),
                            trailing: Row(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color:
                                        Colors.blue,
                                  ),
                                  onPressed: () =>
                                      editService(
                                    service["id"],
                                    service["name"],
                                    (service[
                                                "price"]
                                            as num)
                                        .toDouble(),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color:
                                        Colors.red,
                                  ),
                                  onPressed: () =>
                                      deleteService(
                                    service["id"],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}