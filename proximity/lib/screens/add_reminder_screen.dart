import 'package:flutter/material.dart';
import 'package:weekday_selector/weekday_selector.dart';
import '../models/reminder_model.dart';
import '../services/database_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

class AddReminderScreen extends StatefulWidget {
  final int? itemKey;

  const AddReminderScreen({super.key, this.itemKey});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final values = List.filled(7, false);
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController(
    text: "150",
  );

  LatLng? _selectedLocation;
  LatLng? _myInitialLocation;
  final MapController _mapController = MapController();
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();

    if (widget.itemKey != null) {
      final box = DatabaseService.getBox();

      final data = box.get(widget.itemKey);

      if (data != null) {
        _inputController.text = data.title;
        _radiusController.text = data.radius.toInt().toString();
        _selectedLocation = LatLng(data.latitude, data.longitude);
        _selectedTime = TimeOfDay(hour: data.hour, minute: data.minute);

        if (data.isMonday == true) values[1] = true;
        if (data.isTuesday == true) values[2] = true;
        if (data.isWednesday == true) values[3] = true;
        if (data.isThursday == true) values[4] = true;
        if (data.isFriday == true) values[5] = true;
        if (data.isSaturday == true) values[6] = true;
        if (data.isSunday == true) values[0] = true;
      }
    }

    final todayIndex = DateTime.now().weekday % 7;
    values[todayIndex] = true;
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.whileInUse) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Click Permissions -> Location -> Allow all the time",
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
      await Future.delayed(const Duration(seconds: 2));
      await Geolocator.openAppSettings();
    }

    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      _myInitialLocation = LatLng(position.latitude, position.longitude);
      _selectedLocation = LatLng(position.latitude, position.longitude);
    });

    if (_isMapReady) {
      _mapController.move(_selectedLocation!, 15.0);
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[800]!,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blue[600]),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 400,
              width: double.infinity,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(29.866, 77.899),
                  initialZoom: 13,
                  onMapReady: () {
                    _isMapReady = true;
                    if (_selectedLocation != null) {
                      _mapController.move(_selectedLocation!, 15.0);
                    }
                  },
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
                  if (_selectedLocation != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _selectedLocation!,
                          radius:
                              double.tryParse(_radiusController.text) ?? 150,
                          useRadiusInMeter: true,
                          color: Colors.blue.withOpacity(0.2),
                          borderColor: Colors.blue.shade600,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      if (_myInitialLocation != null)
                        Marker(
                          point: _myInitialLocation!,
                          height: 25,
                          width: 25,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
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

            Transform.translate(
              offset: const Offset(0, -10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Title",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                      TextField(
                        maxLength: 20,
                        controller: _inputController,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: "e.g. MAI-101",
                          hintStyle: TextStyle(
                            color: Colors.black.withOpacity(0.3),
                          ),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue[600]!),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      Text(
                        "Time",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                      InkWell(
                        onTap: _pickTime,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_filled,
                                color: Colors.blue[600],
                              ),
                              SizedBox(width: 10),
                              Text(
                                _selectedTime.format(context),
                                style: GoogleFonts.quantico(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w400,
                                  // fontFamily: 'Courier',
                                ),
                              ),
                              Spacer(),
                              Text(
                                "Change",
                                style: GoogleFonts.poppins(
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      Text(
                        "Radius: ${_radiusController.text}m ${_radiusController.text == "150" ? "(Recommended)" : ""}",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value:
                                  double.tryParse(_radiusController.text) ??
                                  150,
                              min: 100,
                              max: 1000,
                              divisions: 18,
                              activeColor: Colors.blue[600],
                              onChanged: (value) {
                                setState(() {
                                  _radiusController.text = value
                                      .toInt()
                                      .toString();
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 10),

                      Text(
                        "Active Days",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 10),
                      WeekdaySelector(
                        onChanged: (int day) {
                          setState(() {
                            final index = day % 7;
                            values[index] = !values[index];
                          });
                        },
                        values: values,
                        fillColor: Colors.white,
                        selectedFillColor: Colors.blue[600],
                        color: Colors.blue[600],
                        selectedColor: Colors.white,
                      ),
                      SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        height: 40,
        margin: EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        child: FloatingActionButton.extended(
          backgroundColor: Colors.blue[600],
          elevation: 5,
          onPressed: () async {
            if (_inputController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Enter a title!", style: GoogleFonts.poppins()),
                ),
              );
              return;
            }
            if (_selectedLocation == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Pick a location!",
                    style: GoogleFonts.poppins(),
                  ),
                ),
              );
              return;
            }

            double radius = double.tryParse(_radiusController.text) ?? 150.0;

            final box = DatabaseService.getBox();
            List<String> clashingDays = [];

            for (var key in box.keys) {
              if (widget.itemKey != null && widget.itemKey == key) continue;

              final existing = box.get(key) as Reminder;

              if (existing.hour == _selectedTime.hour &&
                  existing.minute == _selectedTime.minute) {
                if (values[0] && existing.isSunday) clashingDays.add("Sunday");
                if (values[1] && existing.isMonday) clashingDays.add("Monday");
                if (values[2] && existing.isTuesday)
                  clashingDays.add("Tuesday");
                if (values[3] && existing.isWednesday)
                  clashingDays.add("Wednesday");
                if (values[4] && existing.isThursday)
                  clashingDays.add("Thursday");
                if (values[5] && existing.isFriday) clashingDays.add("Friday");
                if (values[6] && existing.isSaturday)
                  clashingDays.add("Saturday");
              }
            }

            if (clashingDays.isNotEmpty) {
              String daysString = clashingDays.toSet().join(", ");

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.red[400],
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    "You already have a reminder at ${_selectedTime.format(context)} on: $daysString",
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              );
              return;
            }

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
              lastTriggeredDate: null,
            );

            if (widget.itemKey != null) {
              final box = DatabaseService.getBox();
              await box.put(widget.itemKey, newReminder);
            } else
              await DatabaseService.addReminder(newReminder);

            if (context.mounted) Navigator.pop(context);
          },
          label: Text(
            "Save Reminder",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          icon: Icon(Icons.check, color: Colors.white),
        ),
      ),
    );
  }
}
