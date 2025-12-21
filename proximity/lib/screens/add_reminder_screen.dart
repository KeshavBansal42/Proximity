import 'package:flutter/material.dart';
import 'package:weekday_selector/weekday_selector.dart';
import '../models/reminder_model.dart';
import '../services/database_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final values = List.filled(7, false);
  TimeOfDay _selectedTime = TimeOfDay.now();
  final now = DateTime.now();
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController(
    text: "150",
  );
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    final todayIndex = now.weekday % 7;
    values[todayIndex] = true;
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      _selectedLocation = LatLng(position.latitude, position.longitude);
    });

    _mapController.move(_selectedLocation!, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "PROXIMITY",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontFamily: "Courier",
            fontSize: 28,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsetsGeometry.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            //inputs
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Title:",
                  style: TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "e.g. MAI-101 lecture",
                    ),
                  ),
                ),
              ),

              SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Radius (m):",
                  style: TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: TextField(
                    controller: _radiusController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Recommended: 150",
                    ),
                  ),
                ),
              ),

              SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Time (in 24 hr format):",
                  style: TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time),
                    const SizedBox(width: 12),

                    Text(
                      _selectedTime.format(context),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Spacer(),

                    TextButton(
                      onPressed: _pickTime,
                      child: Text(
                        "Change Time",
                        style: TextStyle(color: Colors.blue[800]),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Select days of the week:",
                  style: TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
                ),
              ),

              WeekdaySelector(
                color: Colors.blue,
                splashColor: Colors.blue,
                selectedFillColor: Colors.blue,
                onChanged: (int day) {
                  setState(() {
                    final index = day % 7;
                    values[index] = !values[index];
                  });
                },
                values: values,
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "Location:",
                  style: TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
                ),
              ),

              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(16),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(29.866, 77.899),
                      initialZoom: 13,
                      onTap: (tapPosition, point) {
                        setState(() {
                          _selectedLocation = point;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.proximity',
                      ),
                      MarkerLayer(
                        markers: [
                          if (_selectedLocation != null)
                            Marker(
                              point: _selectedLocation!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        height: 40,
        width: MediaQuery.of(context).size.width * 0.9,
        child: FloatingActionButton(
          onPressed: () async {
            //save logic

            if (_inputController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please enter a title!")),
              );
              return;
            }

            if (_selectedLocation == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Please tap the map to pick a location!"),
                ),
              );
              return;
            }

            double radius = double.tryParse(_radiusController.text) ?? 150.0;

            final newReminder = Reminder(
              title: _inputController.text,
              latitude: _selectedLocation!.latitude,
              longitude: _selectedLocation!.longitude,
              radius: radius,
              hour: _selectedTime.hour,
              minute: _selectedTime.minute,
              isActive: true,
              isSunday: values[0],
              isMonday: values[1],
              isTuesday: values[2],
              isWednesday: values[3],
              isThursday: values[4],
              isFriday: values[5],
              isSaturday: values[6],
            );

            await DatabaseService.addReminder(newReminder);

            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          backgroundColor: Colors.blue[800],
          child: Text("Save Reminder", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
