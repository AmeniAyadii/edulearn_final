import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/result_service.dart';
import '../theme/app_theme.dart';

class StatsWidget extends StatefulWidget {
  final String childId;
  
  const StatsWidget({super.key, required this.childId});

  @override
  State<StatsWidget> createState() => _StatsWidgetState();
}

class _StatsWidgetState extends State<StatsWidget> {
  final ResultService _resultService = ResultService.instance;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    _stats = await _resultService.getStatistics(widget.childId);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalActivities = _stats['totalActivities'] ?? 0;
    final totalPoints = _stats['totalPoints'] ?? 0;
    final averageScore = _stats['averageScore'] ?? 0.0;
    final bestScore = _stats['bestScore'] ?? 0;
    final totalTimeSpent = _stats['totalTimeSpent'] ?? 0;

    return Column(
      children: [
        // Statistiques globales
        Row(
          children: [
            _buildStatCard(
              icon: Icons.analytics,
              value: totalActivities.toString(),
              label: 'Activités',
              color: Colors.blue,
            ),
            _buildStatCard(
              icon: Icons.stars,
              value: totalPoints.toString(),
              label: 'Points',
              color: Colors.amber,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(
              icon: Icons.trending_up,
              value: '${averageScore.toStringAsFixed(1)}%',
              label: 'Moyenne',
              color: Colors.green,
            ),
            _buildStatCard(
              icon: Icons.emoji_events,
              value: bestScore.toString(),
              label: 'Meilleur score',
              color: Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTimeCard(Duration(seconds: totalTimeSpent)),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Temps total',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                '$hours h ${minutes} min',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}