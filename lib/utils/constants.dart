class AppConstants {
  // List of available majors (jurusan)
  static const List<String> majors = [
    'Computer Science',
    'Information Systems',
    'Information Technology',
    'Software Engineering',
    'Data Science',
    'Cyber Security',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Business Administration',
    'Accounting',
    'Management',
  ];

  // Map of classes by major - DIPERBAIKI: Sekarang menggunakan Map
  static const Map<String, List<String>> classesByMajor = {
    'Computer Science': ['A', 'B', 'C', 'D', 'E'],
    'Information Systems': ['A', 'B', 'C', 'D'],
    'Information Technology': ['A', 'B', 'C'],
    'Software Engineering': ['A', 'B', 'C', 'D'],
    'Data Science': ['A', 'B', 'C'],
    'Cyber Security': ['A', 'B'],
    'Electrical Engineering': ['A', 'B', 'C', 'D'],
    'Mechanical Engineering': ['A', 'B', 'C'],
    'Civil Engineering': ['A', 'B', 'C', 'D'],
    'Business Administration': ['A', 'B', 'C', 'D', 'E'],
    'Accounting': ['A', 'B', 'C'],
    'Management': ['A', 'B', 'C', 'D'],
  };

  // List of available classes (kelas) - untuk backward compatibility
  static const List<String> classes = [
    'A',
    'B',
    'C',
    'D',
    'E',
  ];

  // Days of week
  static const List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // Time slots (jam kuliah)
  static const List<String> timeSlots = [
    '07:00 - 08:40',
    '08:40 - 10:20',
    '10:20 - 12:00',
    '13:00 - 14:40',
    '14:40 - 16:20',
    '16:20 - 18:00',
    '18:00 - 19:40',
  ];

  // Get classes for a specific major
  static List<String> getClassesForMajor(String major) {
    return classesByMajor[major] ?? classes;
  }
}
