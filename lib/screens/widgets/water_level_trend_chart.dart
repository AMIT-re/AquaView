import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WaterLevelTrendChart extends StatelessWidget {
  final List<double> historicalData;
  final double? droughtThreshold;

  const WaterLevelTrendChart({
    Key? key,
    required this.historicalData,
    this.droughtThreshold,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (int i = 0; i < historicalData.length; i++) {
      spots.add(FlSpot(i.toDouble(), historicalData[i]));
    }
    return AspectRatio(
      aspectRatio: 1.7,
      child: Card(
        color: const Color(0xFF1E1E1E),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              minX: 0,
              maxX: (historicalData.length - 1).toDouble(),
              minY: historicalData.reduce((a, b) => a < b ? a : b) - 1,
              maxY: historicalData.reduce((a, b) => a > b ? a : b) + 1,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.blueAccent,
                  barWidth: 3,
                  belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withOpacity(0.2)),
                  dotData: FlDotData(show: true),
                ),
                if (droughtThreshold != null)
                  LineChartBarData(
                    spots: [
                      FlSpot(0, droughtThreshold!),
                      FlSpot((historicalData.length - 1).toDouble(), droughtThreshold!),
                    ],
                    isCurved: false,
                    color: Colors.redAccent,
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    dashArray: [6, 4],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
