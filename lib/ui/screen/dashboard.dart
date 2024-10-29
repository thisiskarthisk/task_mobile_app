// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Map<DateTime, List<dynamic>> _events; // Store events for each date
  late List<dynamic> _selectedEvents; // Events for the currently selected date
  late DateTime _selectedDay; // The currently selected day
  late DateTime _focusedDay; // The currently focused day

  @override
  void initState() {
    super.initState();
    _events = {}; // Initialize events
    _selectedEvents = []; // Initialize selected events
    _selectedDay = DateTime.now(); // Set default selected day to today
    _focusedDay = DateTime.now(); // Set default focused day to today
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedEvents = _events[selectedDay] ?? []; // Get events for selected day
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dashboard")),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              // Use this to determine which day is currently selected
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: _onDaySelected,
            eventLoader: (day) {
              return _events[day] ?? []; // Load events for each day
            },
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            daysOfWeekVisible: true,
          ),
          const SizedBox(height: 8.0),
          Text(
            'Events',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          ..._selectedEvents.map((event) => ListTile(title: Text(event.toString()))).toList(),
        ],
      ),
    );
  }
}
