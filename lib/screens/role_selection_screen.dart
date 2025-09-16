import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import 'dashboards/citizen_dashboard.dart';
import 'dashboards/farmer_dashboard.dart';
import 'dashboards/industry_dashboard.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Select Your Role'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose the role that best describes you to access relevant information and features.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Role selection cards
            Expanded(
              child: Column(
                children: [
                  _buildRoleCard(
                    role: UserRole.citizen,
                    title: 'Citizen',
                    icon: Icons.person_search,
                    description: 'Access water quality data, source information, and treatment details for your community.',
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildRoleCard(
                    role: UserRole.farmer,
                    title: 'Farmer',
                    icon: Icons.eco,
                    description: 'View groundwater levels, irrigation schedules, and water usage reports for your farm.',
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildRoleCard(
                    role: UserRole.industry,
                    title: 'Industry',
                    icon: Icons.factory,
                    description: 'Monitor water consumption, treatment processes, and compliance reports for your facility.',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Continue button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedRole != null ? _continueToDashboard : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedRole != null 
                      ? const Color(0xFF2196F3) 
                      : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required IconData icon,
    required String description,
  }) {
    final isSelected = _selectedRole == role;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2196F3),
                size: 30,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _continueToDashboard() {
    if (_selectedRole == null) return;
    
    final appState = Provider.of<AppState>(context, listen: false);
    appState.selectRole(_selectedRole!);
    appState.completeOnboarding();
    
    Widget destination;
    switch (_selectedRole!) {
      case UserRole.citizen:
        destination = const CitizenDashboard();
        break;
      case UserRole.farmer:
        destination = const FarmerDashboard();
        break;
      case UserRole.industry:
        destination = const IndustryDashboard();
        break;
    }
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }
}

