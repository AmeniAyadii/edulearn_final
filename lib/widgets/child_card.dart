import 'package:flutter/material.dart';
import '../models/child_model.dart';
import '../theme/app_theme.dart';

class ChildCard extends StatelessWidget {
  final ChildModel child;
  final VoidCallback onTap;
  final VoidCallback onReportTap;

  const ChildCard({
    super.key,
    required this.child,
    required this.onTap,
    required this.onReportTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.child_care,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.pseudo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text('${child.points} pts'),
                        const SizedBox(width: 12),
                        const Icon(Icons.local_fire_department, size: 14),
                        const SizedBox(width: 4),
                        Text('Série ${child.daysStreak}'),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart),
                onPressed: onReportTap,
                tooltip: 'Voir les rapports',
              ),
            ],
          ),
        ),
      ),
    );
  }
}