import 'package:flutter/material.dart';
import '../models/schedule_model.dart';

class ScheduleCard extends StatelessWidget {
  final ScheduleModel schedule;
  final bool isCurrentClass;
  final bool isUpcoming;

  const ScheduleCard({
    Key? key,
    required this.schedule,
    this.isCurrentClass = false,
    this.isUpcoming = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color cardColor = Colors.white;
    Color accentColor = Theme.of(context).primaryColor;
    IconData statusIcon = Icons.schedule;
    String statusText = 'Scheduled';

    if (isCurrentClass) {
      cardColor = Colors.green.shade50;
      accentColor = Colors.green;
      statusIcon = Icons.play_circle;
      statusText = 'Ongoing';
    } else if (isUpcoming) {
      cardColor = Colors.orange.shade50;
      accentColor = Colors.orange;
      statusIcon = Icons.upcoming;
      statusText = 'Coming Soon';
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentClass || isUpcoming
              ? accentColor
              : Colors.grey.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time and Status Row
            Row(
              children: [
                // Time Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        schedule.timeSlot,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                
                // Status Badge
                if (isCurrentClass || isUpcoming)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 14,
                          color: accentColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Subject
            Text(
              schedule.subject,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isCurrentClass || isUpcoming
                    ? accentColor
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Details
            _buildDetailRow(
              Icons.person_outline,
              schedule.lecturer,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.location_on_outlined,
              schedule.room,
              Colors.red,
            ),
            if (schedule.concentration != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.build_outlined,
                schedule.concentration!,
                Colors.purple,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
