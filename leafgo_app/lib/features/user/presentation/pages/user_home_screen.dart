import 'package:flutter/material.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  String _selectedVehicle = '4-seater';

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF10B981);
    final secondaryColor = const Color(0xFFE6F7F0);

    return Scaffold(
      backgroundColor: secondaryColor,
      body: Stack(
        children: [
          // Map Background Placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 80, color: primaryColor.withOpacity(0.5)),
                const SizedBox(height: 8),
                Text(
                  'Bản đồ tương tác',
                  style: TextStyle(color: primaryColor.withOpacity(0.7), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // Top Badge
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco, color: primaryColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Leaf Go',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // GPS Button
          Positioned(
            right: 16,
            bottom: 340, // Above the card
            child: FloatingActionButton.small(
              onPressed: () {},
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              child: const Icon(Icons.near_me_outlined),
            ),
          ),

          // Booking Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5)),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Location Inputs
                  _locationInput(
                    hint: 'Điểm đón',
                    iconColor: Colors.green,
                    controller: TextEditingController(),
                  ),
                  const SizedBox(height: 16),
                  _locationInput(
                    hint: 'Điểm đến',
                    iconColor: Colors.red,
                    controller: TextEditingController(),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Chọn loại xe',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Vehicle Selection
                  Row(
                    children: [
                      Expanded(
                        child: _vehicleCard(
                          id: '4-seater',
                          label: 'Xe 4 chỗ',
                          price: '15.000đ/km',
                          icon: Icons.directions_car_outlined,
                          isSelected: _selectedVehicle == '4-seater',
                          onTap: () => setState(() => _selectedVehicle = '4-seater'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _vehicleCard(
                          id: '7-seater',
                          label: 'Xe 7 chỗ',
                          price: '20.000đ/km',
                          icon: Icons.airport_shuttle_outlined,
                          isSelected: _selectedVehicle == '7-seater',
                          onTap: () => setState(() => _selectedVehicle = '7-seater'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Book Button
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor.withOpacity(0.4), // Based on image's lighter green button
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Đặt xe ngay',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationInput({required String hint, required Color iconColor, required TextEditingController controller}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _vehicleCard({
    required String id,
    required String label,
    required String price,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primaryColor = const Color(0xFF10B981);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: isSelected ? primaryColor : Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? primaryColor : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
