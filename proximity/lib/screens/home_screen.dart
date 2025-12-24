import 'package:flutter/material.dart';
import 'package:proximity/screens/add_reminder_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/reminder_model.dart';
import '../services/database_service.dart';
import 'package:google_fonts/google_fonts.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey[400]),
        ),
        backgroundColor: Colors.blueGrey[50],
        elevation: 0,
        title: Text(
          "PROXIMITY",
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            fontSize: 28,
            letterSpacing: 1.5,
          ),
        ),
        // centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text(
              "My Reminders",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 24,
                color: Colors.blueGrey[800],
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: DatabaseService.getBox().listenable(),
                builder: (context, box, child) {
                  final reminders = box.values.toList().cast<Reminder>();

                  if (reminders.isEmpty) {
                    return const Center(child: Text("No reminders yet!"));
                  }

                  return ListView.builder(
                    itemCount: reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = reminders[index];
                      final isActive = reminder.isActive;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: isActive
                                        ? Colors.green[400]
                                        : Colors.grey[300],
                                  ),
                                  width: 6,
                                ),

                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      8,
                                      12,
                                      12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        //row for title and switch
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                reminder.title,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w400,
                                                  color: isActive
                                                      ? Colors.black
                                                      : Colors.grey,
                                                  decoration: isActive
                                                      ? null
                                                      : TextDecoration
                                                            .lineThrough,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Transform.scale(
                                              scale: 0.8,
                                              child: Switch(
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                activeColor: Colors.white,
                                                activeTrackColor:
                                                    Colors.blue[600],
                                                value: isActive,
                                                onChanged: (bool value) {
                                                  final updatedReminder = Reminder(
                                                    title: reminder.title,
                                                    latitude: reminder.latitude,
                                                    longitude:
                                                        reminder.longitude,
                                                    radius: reminder.radius,
                                                    hour: reminder.hour,
                                                    minute: reminder.minute,
                                                    isActive: value,
                                                    lastTriggeredDate: reminder
                                                        .lastTriggeredDate,
                                                    isMonday: reminder.isMonday,
                                                    isTuesday:
                                                        reminder.isTuesday,
                                                    isWednesday:
                                                        reminder.isWednesday,
                                                    isThursday:
                                                        reminder.isThursday,
                                                    isFriday: reminder.isFriday,
                                                    isSaturday:
                                                        reminder.isSaturday,
                                                    isSunday: reminder.isSunday,
                                                  );
                                                  box.putAt(
                                                    index,
                                                    updatedReminder,
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),

                                        //row for time and radius
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time_rounded,
                                              size: 16,
                                              color: Colors.blueGrey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${reminder.hour.toString().padLeft(2, '0')}:${reminder.minute.toString().padLeft(2, '0')}",
                                              style: TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: "Courier",
                                                color: Colors.blueGrey[800],
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              margin: EdgeInsets.only(right: 6),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blueGrey[50],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                "${reminder.radius.toInt()}m radius",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 12),

                                        Row(
                                          children: [
                                            _buildDayDot(
                                              'M',
                                              reminder.isMonday,
                                              isActive,
                                            ),
                                            _buildDayDot(
                                              'T',
                                              reminder.isTuesday,
                                              isActive,
                                            ),
                                            _buildDayDot(
                                              'W',
                                              reminder.isWednesday,
                                              isActive,
                                            ),
                                            _buildDayDot(
                                              'T',
                                              reminder.isThursday,
                                              isActive,
                                            ),
                                            _buildDayDot(
                                              'F',
                                              reminder.isFriday,
                                              isActive,
                                            ),
                                            _buildDayDot(
                                              'S',
                                              reminder.isSaturday,
                                              isActive,
                                            ),
                                            _buildDayDot(
                                              'S',
                                              reminder.isSunday,
                                              isActive,
                                            ),
                                            const Spacer(),
                                            InkWell(
                                              onTap: () => box.deleteAt(index),
                                              child: Icon(
                                                Icons.delete_outline,
                                                color: Colors.red[300],
                                                size: 20,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddReminderScreen()),
          );
        },
        label: Text(
          "Add Reminder",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        icon: Icon(Icons.add),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildDayDot(String day, bool? isEnabled, bool isCardActive) {
    final bool active = isEnabled == true;
    return Container(
      margin: const EdgeInsets.only(right: 4),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active && isCardActive ? Colors.blue[600] : Colors.transparent,
        border: Border.all(
          color: active && isCardActive ? Colors.blue[600]! : Colors.grey[300]!,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        day,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: active && isCardActive ? Colors.white : Colors.grey[400],
        ),
      ),
    );
  }
}
