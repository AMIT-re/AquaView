import 'package:flutter/material.dart';
import '../../services/mock_data.dart';
import '../welcome_screen.dart';

class FarmerDashboard extends StatelessWidget {
  const FarmerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final soilCompatibility = MockDataService.getSoilCompatibility();
    final seasonalForecast = MockDataService.getSeasonalForecast();

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF2196F3)),
              child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Farmer Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Water Quality Reports
            _buildSectionTitle('Water Quality Reports'),
            const SizedBox(height: 16),
            _buildReportsCard(),
            const SizedBox(height: 24),
            // Soil-Silt Compatibility
            _buildSectionTitle('Soil-Silt Compatibility'),
            const SizedBox(height: 16),
            _buildSoilCompatibilityCard(soilCompatibility),
            const SizedBox(height: 24),
            // Seasonal Forecast
            _buildSectionTitle('Seasonal Forecast'),
            const SizedBox(height: 16),
            _buildSeasonalForecastCard(seasonalForecast),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildReportsCard() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildReportItem(
              icon: Icons.calendar_today,
              title: 'Daily Report',
              onTap: () {},
            ),
            const Divider(color: Colors.white24),
            _buildReportItem(
              icon: Icons.calendar_view_week,
              title: 'Weekly Report',
              onTap: () {},
            ),
            const Divider(color: Colors.white24),
            _buildReportItem(
              icon: Icons.picture_as_pdf,
              title: 'Download PDF',
              onTap: () {},
            ),
            const Divider(color: Colors.white24),
            _buildReportItem(
              icon: Icons.table_chart,
              title: 'Download CSV',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2196F3),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilCompatibilityCard(String description) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.settings,
                color: Color(0xFF2196F3),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonalForecastCard(String description) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.cloud,
                color: Color(0xFF2196F3),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF1E1E1E),
      selectedItemColor: const Color(0xFF2196F3),
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.agriculture),
          label: 'Farmer',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.info_outline),
          label: 'Info',
        ),
      ],
      currentIndex: 1,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (route) => false,
            );
            break;
          case 1:
            // Stay on dashboard
            break;
          case 2:
            // Info (not implemented)
            break;
        }
      },
    );
  }
}

