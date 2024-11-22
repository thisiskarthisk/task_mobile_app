import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_tms/data/tasks_data.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Map<DateTime, List<Map<String, dynamic>>> _events; // Store events for each date
  late List<Map<String, dynamic>> _selectedEvents; // Events for the currently selected date
  late DateTime _selectedDay; // The currently selected day
  late DateTime _focusedDay; // The currently focused day

  @override
  void initState() {
    super.initState();
    _events = {}; // Initialize events
    _selectedEvents = []; // Initialize selected events
    _selectedDay = DateTime.now(); // Set default selected day to today
    _focusedDay = DateTime.now(); // Set default focused day to today

    // Initialize the events map based on the task data
    _populateEvents();
  }

  // Populate the events map with tasks based on the startDate
  void _populateEvents() {
    for (var task in tasks) {
      DateTime startDate = DateTime.parse(task['startDate']);
      if (_events[startDate] == null) {
        _events[startDate] = [];
      }
      _events[startDate]!.add(task);
    }
  }

  // On day selected, update the selected events based on the selected date
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedEvents = _getTasksForSelectedDate(selectedDay); // Get tasks for the selected day
    });
  }

  // Get tasks based on the selected date's startDate
  List<Map<String, dynamic>> _getTasksForSelectedDate(DateTime selectedDay) {
    return tasks.where((task) {
      // Convert task startDate to DateTime object for comparison
      DateTime taskStartDate = DateTime.parse(task['startDate']);
      return taskStartDate.year == selectedDay.year &&
          taskStartDate.month == selectedDay.month &&
          taskStartDate.day == selectedDay.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size for responsive layout
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          // TableCalendar widget to select a date
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day); // Highlight selected day
            },
            onDaySelected: _onDaySelected,
            eventLoader: (day) {
              return _events[day] ?? []; // Load events for each day
            },
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            daysOfWeekVisible: true,
          ),
          const SizedBox(height: 10.0),

          Text(
            'Tasks',
            style: TextStyle(
              fontSize: screenWidth < 600 ? 20 : 24, // Responsive text size
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10.0),
          // Display task details if there are any selected events

          // Display horizontal cards for each task
          if (_selectedEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No tasks available for this date.',
                style: TextStyle(
                  fontSize: screenWidth < 600 ? 16 : 18, // Responsive text size
                ),
              ),
            ),
          ..._selectedEvents.map((task) => GestureDetector(
            child: TaskCard(task: task),
          )),
        ],
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;

  TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    // Get the screen size for responsive layout
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth < 600 ? screenWidth * 0.85 : 450, // Responsive card width
      margin: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task['name'] ?? 'Task Name',
            style: TextStyle(
              fontSize: screenWidth < 600 ? 14 : 16, // Responsive text size
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),

          Text(
            'Job Type: ${task['jobType'] ?? 'Unknown'}',
            style: TextStyle(
              fontSize: screenWidth < 600 ? 12 : 14, // Responsive text size
              color: Colors.black54,
            ),
          ),

          Text(
            'Assignee: ${task['assignee'] ?? 'Unknown'}',
            style: TextStyle(
              fontSize: screenWidth < 600 ? 12 : 14, // Responsive text size
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 8),
          // Info icon to navigate to TaskDetailsScreen
        ],
      ),
    );
  }
}
