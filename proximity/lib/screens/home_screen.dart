import 'package:flutter/material.dart';
import 'package:proximity/screens/add_reminder_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/reminder_model.dart';
import '../services/database_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
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
        // centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "My Reminders",
              style: TextStyle(
                // decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
                fontFamily: "Courier",
                fontSize: 24,
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
                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            checkColor: Colors.white,
                            fillColor: reminder.isActive
                                ? MaterialStateProperty.all(Colors.blue[800])
                                : null,
                            value: reminder.isActive,
                            onChanged: (bool? value) {
                              final updatedReminder = Reminder(
                                title: reminder.title,
                                latitude: reminder.latitude,
                                longitude: reminder.longitude,
                                radius: reminder.radius,
                                hour: reminder.hour,
                                minute: reminder.minute,
                                isActive: value ?? false,
                              );
                              box.putAt(index, updatedReminder);
                            },
                          ),
                          title: Text(
                            reminder.title,
                            style: TextStyle(
                              decoration: !reminder.isActive
                                  ? TextDecoration.lineThrough
                                  : null,
                              fontFamily: "Courier",
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 28,
                              fontFamily: "Courier",
                            ),
                            "${reminder.hour.toString().padLeft(2, '0')} : ${reminder.minute.toString().padLeft(2, '0')}",
                          ),
                          trailing: IconButton(
                            onPressed: () {
                              box.deleteAt(index);
                            },
                            icon: Icon(Icons.delete),
                            color: Colors.red,
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
        label: Text("Add Reminder"),
        icon: Icon(Icons.add),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
    );
  }
}
