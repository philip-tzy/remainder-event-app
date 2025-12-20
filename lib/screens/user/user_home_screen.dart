import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../../services/rsvp_service.dart';
import '../../models/event_model.dart';
import '../../models/rsvp_model.dart';
import '../../widgets/event_list_item.dart';
import 'event_detail_screen.dart';
import 'my_rsvp_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({Key? key}) : super(key: key);

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final _searchController = TextEditingController();
  final _eventService = EventService();
  final _rsvpService = RsvpService();
  String _searchQuery = '';
  String? _selectedCategory;

  // Available categories (same as admin)
  final List<String> _categories = [
    'All',
    'Seminar',
    'Competition',
    'UKM',
    'Workshop',
    'Sports',
    'Cultural',
    'Other',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Events'),
        actions: [
          // My RSVPs button
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'My RSVPs',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyRsvpScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search events...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Category filter
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category ||
                          (_selectedCategory == null && category == 'All');

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (category == 'All') {
                                _selectedCategory = null;
                              } else {
                                _selectedCategory = selected ? category : null;
                              }
                            });
                          },
                          selectedColor: Theme.of(context).primaryColor,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Events list
          Expanded(
            child: StreamBuilder<List<EventModel>>(
              stream: _selectedCategory == null
                  ? _eventService.getUpcomingEvents()
                  : _eventService.getEventsByCategory(_selectedCategory!),
              builder: (context, snapshot) {
                // Debug prints
                print('Connection state: ${snapshot.connectionState}');
                print('Has data: ${snapshot.hasData}');
                print('Data length: ${snapshot.data?.length}');
                if (snapshot.hasError) {
                  print('Error: ${snapshot.error}');
                }

                // Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // Error state
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Refresh
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // Get events
                var events = snapshot.data ?? [];

                // REMOVED: Filter out past events - hanya tampilkan upcoming events
                final now = DateTime.now();
                events = events.where((e) => e.endAt.isAfter(now)).toList();

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  events = events.where((event) {
                    return event.title.toLowerCase().contains(_searchQuery) ||
                        event.description.toLowerCase().contains(_searchQuery) ||
                        event.location.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                // Sort by start date (soonest first)
                events.sort((a, b) => a.startAt.compareTo(b.startAt));

                // Empty state
                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No events found'
                              : 'No upcoming events',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try a different search term'
                              : 'Check back later for new events',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Display only upcoming events (no section headers needed)
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {}); // Refresh the stream
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];

                      // Check if user has RSVP'd
                      return FutureBuilder<RsvpModel?>(
                        future: userId != null
                            ? _rsvpService.getUserRsvpForEvent(userId, event.id!)
                            : Future.value(null),
                        builder: (context, rsvpSnapshot) {
                          final hasRsvpd = rsvpSnapshot.data != null;

                          // Get RSVP count
                          return FutureBuilder<int>(
                            future: _rsvpService.getEventRsvpCount(event.id!),
                            builder: (context, countSnapshot) {
                              final rsvpCount = countSnapshot.data ?? 0;

                              return EventListItem(
                                event: event,
                                showRsvpBadge: hasRsvpd,
                                rsvpCount: rsvpCount,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EventDetailScreen(
                                        event: event,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
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
