import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/service_ping.dart';

class ServiceCard extends StatelessWidget {
  final ServicePing service;

  const ServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    bool isAlert = service.jitter > 10;
    bool isDown = service.currentPing == 0;

    Color statusColor = isDown
        ? Colors.redAccent
        : (isAlert ? Colors.amberAccent : const Color(0xFF00E676));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  service.name.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                isDown
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_rounded,
                color: statusColor.withOpacity(0.5),
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                isDown ? 'OFF' : '${service.currentPing.toInt()}',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                ),
              ),
              if (!isDown)
                Text(
                  ' ms',
                  style: GoogleFonts.outfit(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Jitter: ${service.jitter.toInt()}ms',
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildBadge(
                isDown ? 'OFFLINE' : (isAlert ? 'INSTÁVEL' : 'ESTÁVEL'),
                statusColor,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Expanded(
            child: service.history.isEmpty || isDown
                ? _buildEmptyChart()
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: service.history
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(), e.value))
                              .toList(),
                          isCurved: true,
                          color: statusColor,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                statusColor.withOpacity(0.3),
                                statusColor.withOpacity(0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            service.target,
            style: const TextStyle(
              color: Colors.white10,
              fontSize: 9,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time_rounded, color: Colors.white10, size: 10),
              const SizedBox(width: 4),
              Text(
                DateFormat('HH:mm:ss').format(DateTime.now()),
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Center(
      child: Container(
        height: 2,
        width: double.infinity,
        color: Colors.white.withOpacity(0.05),
      ),
    );
  }
}
