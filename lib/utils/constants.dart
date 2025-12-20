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

  // List of batches (angkatan)
  static const List<String> batches = [
    '2020',
    '2021',
    '2022',
    '2023',
    '2024',
    '2025',
  ];

  // Map of concentrations by major (peminatan)
  static const Map<String, List<String>> concentrationsByMajor = {
    'Computer Science': [
      'Artificial Intelligence',
      'Data Science',
      'Software Engineering',
      'Cyber Security',
      'Game Development',
    ],
    'Information Systems': [
      'Business Intelligence',
      'Enterprise Systems',
      'E-Business',
      'IT Audit',
    ],
    'Information Technology': [
      'Network Engineering',
      'Cloud Computing',
      'IoT',
      'Mobile Computing',
    ],
    'Software Engineering': [
      'Web Development',
      'Mobile Development',
      'DevOps',
      'Quality Assurance',
    ],
    'Data Science': [
      'Machine Learning',
      'Big Data Analytics',
      'Data Engineering',
      'Business Analytics',
    ],
    'Cyber Security': [
      'Network Security',
      'Application Security',
      'Digital Forensics',
      'Penetration Testing',
    ],
    'Electrical Engineering': [
      'Power Systems',
      'Electronics',
      'Telecommunications',
      'Control Systems',
    ],
    'Mechanical Engineering': [
      'Manufacturing',
      'Automotive',
      'Robotics',
      'Energy Systems',
    ],
    'Civil Engineering': [
      'Structural Engineering',
      'Transportation',
      'Water Resources',
      'Construction Management',
    ],
    'Business Administration': [
      'Marketing',
      'Human Resources',
      'Operations Management',
      'Entrepreneurship',
    ],
    'Accounting': [
      'Financial Accounting',
      'Management Accounting',
      'Taxation',
      'Auditing',
    ],
    'Management': [
      'Strategic Management',
      'Project Management',
      'Supply Chain Management',
      'International Business',
    ],
  };

  // Classes (angka 1-5 untuk menampung kelas besar)
  static const List<String> classes = [
    '1',
    '2',
    '3',
    '4',
    '5',
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

  // Get concentrations for a specific major
  static List<String> getConcentrationsForMajor(String major) {
    return concentrationsByMajor[major] ?? [];
  }

  // Get full class name (for backward compatibility)
  static String getFullClassName(String classNumber) {
    return 'Class $classNumber';
  }
}
