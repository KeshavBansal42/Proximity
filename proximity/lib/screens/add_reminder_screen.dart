import 'package:flutter/material.dart';
import 'package:weekday_selector/weekday_selector.dart';
import '../models/reminder_model.dart';
import '../services/database_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../services/background_services.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import '../models/saved_location_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  TimeOfDay? _originalTime;
  String? _selectedAudioPath;

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
        _originalTime = TimeOfDay(hour: data.hour, minute: data.minute);
        _selectedAudioPath = data.audioPath;

        _unpackIntToDays(data.activeDays);
      }
    } else {
      final todayIndex = DateTime.now().weekday % 7;
      values[todayIndex] = true;
    }

    _getCurrentLocation();
  }

  int _packDaysToInt(List<bool> values) {
    int packed = 0;
    for (int i = 0; i < 7; i++) {
      if (values[i]) {
        packed |= (1 << i);
      }
    }
    return packed;
  }

  void _unpackIntToDays(int packed) {
    for (int i = 0; i < 7; i++) {
      if ((packed >> i) & 1 == 1) {
        values[i] = true;
      } else {
        values[i] = false;
      }
    }
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
      if (widget.itemKey == null) {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      }
    });

    if (_isMapReady) {
      _mapController.move(_selectedLocation!, 15.0);
    }
  }

  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,

      // allowedExtensions: ['mp3'],
    );

    if (result != null) {
      String path = result.files.single.path!;
      String extension = path.split('.').last.toLowerCase();

      if (extension != "mp3") {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Invalid file format, please select a .mp3 file.",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.red[400],
            ),
          );
        }
        await Future.delayed(Duration(seconds: 3));
        _pickAudio();
        return;
      }

      setState(() {
        _selectedAudioPath = result.files.single.path;
      });
    }
  }

  Future<void> _saveCurrentLocation() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please pick a location on the map first!")),
      );
      return;
    }

    TextEditingController nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          "Save this Spot",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: "Name (e.g. LHC, Gym, Hostel)",
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.blue, width: 2.0),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final loc = SavedLocation(
                  name: nameController.text,
                  latitude: _selectedLocation!.latitude,
                  longitude: _selectedLocation!.longitude,
                );
                DatabaseService.addLocation(loc);
                Navigator.pop(context);

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Location saved!")));
              }
            },
            child: Text(
              "Save",
              style: GoogleFonts.poppins(
                color: Colors.blue[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
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
              child: Stack(
                children: [
                  FlutterMap(
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
                                  double.tryParse(_radiusController.text) ??
                                  150,
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
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
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

                  Positioned(
                    bottom: 20,
                    left: 10,
                    right: 64,
                    child: ValueListenableBuilder(
                      valueListenable: DatabaseService.getLocationBox()
                          .listenable(),
                      builder: (context, Box<SavedLocation> box, _) {
                        final locations = box.values.toList();
                        if (locations.isEmpty) return SizedBox.shrink();

                        double estimatedHeight = locations.length * 50.0;
                        if (estimatedHeight > 200) estimatedHeight = 200;
                        double finalOffset = -(estimatedHeight + 20);

                        return Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: PopupMenuButton<SavedLocation>(
                            color: Colors.white,
                            constraints: BoxConstraints(
                              maxHeight: 210,
                              minWidth: 160,
                            ),
                            offset: Offset(0, finalOffset),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            onSelected: (SavedLocation loc) {
                              setState(() {
                                _selectedLocation = LatLng(
                                  loc.latitude,
                                  loc.longitude,
                                );
                              });
                              _mapController.move(_selectedLocation!, 15.0);
                            },
                            itemBuilder: (context) {
                              return locations.asMap().entries.map((entry) {
                                int index = entry.key;
                                SavedLocation loc = entry.value;
                                return PopupMenuItem(
                                  value: loc,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.orange,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          loc.name,
                                          style: GoogleFonts.poppins(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      InkWell(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                backgroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadiusGeometry.circular(
                                                        16,
                                                      ),
                                                ),
                                                title: Text(
                                                  "Delete Saved Location?",
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                content: Text(
                                                  "Are you sure you want to delete ${loc.name}?",
                                                  style: GoogleFonts.poppins(),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    child: Text(
                                                      "Cancel",
                                                      style:
                                                          GoogleFonts.poppins(
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
                                                    },
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      Navigator.pop(context);
                                                      await box.deleteAt(index);
                                                      Navigator.pop(context);
                                                    },
                                                    child: Text(
                                                      "Delete",
                                                      style:
                                                          GoogleFonts.poppins(
                                                            color:
                                                                Colors.red[400],
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        child: Icon(
                                          Icons.delete_outline,
                                          color: Colors.red[300],
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      "Saved Locations",
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_up,
                                    color: Colors.blue[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  Positioned(
                    bottom: 20,
                    right: 10,
                    child: FloatingActionButton(
                      heroTag: "save_btn",
                      backgroundColor: Colors.white,
                      mini: true,
                      onPressed: _saveCurrentLocation,
                      child: Icon(
                        Icons.bookmark_add,
                        color: Colors.blue[600],
                        size: 28,
                      ),
                    ),
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
                      SizedBox(height: 10),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CupertinoTheme(
                          data: CupertinoThemeData(
                            textTheme: CupertinoTextThemeData(
                              dateTimePickerTextStyle: GoogleFonts.poppins(
                                color: Colors.blue[600],
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.time,
                            initialDateTime: DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                              DateTime.now().day,
                              _selectedTime.hour,
                              _selectedTime.minute,
                            ),
                            use24hFormat: false,
                            itemExtent: 45,
                            onDateTimeChanged: (DateTime newDate) {
                              setState(() {
                                _selectedTime = TimeOfDay(
                                  hour: newDate.hour,
                                  minute: newDate.minute,
                                );
                              });
                            },
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
                      SizedBox(height: 10),
                      ListTile(
                        title: Text(
                          _selectedAudioPath == null
                              ? "Select Alarm Sound(.mp3 only)"
                              : "Sound Selected",
                        ),
                        subtitle: Text(
                          _selectedAudioPath != null
                              ? _selectedAudioPath!.split('/').last
                              : "Default: Alarm.mp3",
                        ),
                        trailing: Icon(Icons.music_note, color: Colors.blue),
                        onTap: _pickAudio,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
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
                if (values[0] && (existing.activeDays & 1 == 1))
                  clashingDays.add("Sunday");
                if (values[1] && (existing.activeDays & 2 == 1))
                  clashingDays.add("Monday");
                if (values[2] && (existing.activeDays & 4 == 1))
                  clashingDays.add("Tuesday");
                if (values[3] && (existing.activeDays & 8 == 1))
                  clashingDays.add("Wednesday");
                if (values[4] && (existing.activeDays & 16 == 1))
                  clashingDays.add("Thursday");
                if (values[5] && (existing.activeDays & 32 == 1))
                  clashingDays.add("Friday");
                if (values[6] && (existing.activeDays & 64 == 1))
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

            DateTime? triggeredDateToSave;

            if (widget.itemKey != null && _originalTime != null) {
              final existing = box.get(widget.itemKey) as Reminder;
              bool timeChanged =
                  (_originalTime!.hour != _selectedTime.hour) ||
                  (_originalTime!.minute != _selectedTime.minute);

              if (timeChanged) {
                triggeredDateToSave = null;
              } else {
                triggeredDateToSave = existing.lastTriggeredDate;
              }
            } else {
              triggeredDateToSave = null;
            }

            final newReminder = Reminder(
              title: _inputController.text,
              latitude: _selectedLocation!.latitude,
              longitude: _selectedLocation!.longitude,
              radius: radius,
              hour: _selectedTime.hour,
              minute: _selectedTime.minute,
              isActive: true,
              activeDays: _packDaysToInt(values),
              lastTriggeredDate: triggeredDateToSave,
              audioPath: _selectedAudioPath,
            );

            if (widget.itemKey != null) {
              await box.put(widget.itemKey, newReminder);
            } else {
              await DatabaseService.addReminder(newReminder);
            }

            await box.flush();

            await AndroidAlarmManager.oneShot(
              const Duration(seconds: 5),
              0,
              callback,
              wakeup: true,
              exact: true,
              rescheduleOnReboot: true,
            );

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
