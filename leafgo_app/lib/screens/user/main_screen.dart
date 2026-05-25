import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../injection_container.dart';
import 'package:leafgo_app/blocs/booking/booking_bloc.dart';
import '../../blocs/user/user_bloc.dart';
import 'user_home_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';

// Driver Features
import 'package:leafgo_app/screens/driver/driver_home_screen.dart';
import 'package:leafgo_app/screens/driver/driver_stats_screen.dart';
import 'package:leafgo_app/blocs/driver/driver_bloc.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF10B981);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<UserBloc>()..add(UserFetchProfile())),
        BlocProvider(create: (context) => sl<BookingBloc>()..add(BookingLoadVehicleTypes())),
        BlocProvider(create: (context) => sl<DriverBloc>()),
      ],
      child: BlocBuilder<UserBloc, UserState>(
        builder: (context, userState) {
          final user = userState.profile;
          final isDriver = user?.role == 'Driver';

          final List<Widget> pages = isDriver
              ? [
                  const DriverHomeScreen(),
                  const DriverStatsScreen(),
                  const ProfileScreen(),
                ]
              : [
                  const UserHomeScreen(),
                  const HistoryScreen(),
                  const ProfileScreen(),
                ];

          final activeIndex = _selectedIndex.clamp(0, pages.length - 1);

          final List<BottomNavigationBarItem> navItems = isDriver
              ? const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.radar_outlined),
                    activeIcon: Icon(Icons.radar),
                    label: 'Đón khách',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.analytics_outlined),
                    activeIcon: Icon(Icons.analytics),
                    label: 'Doanh thu',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Tài khoản',
                  ),
                ]
              : const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.directions_car_outlined),
                    activeIcon: Icon(Icons.directions_car),
                    label: 'Đặt xe',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.history_outlined),
                    activeIcon: Icon(Icons.history),
                    label: 'Lịch sử',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Tài khoản',
                  ),
                ];

          return Scaffold(
            body: pages[activeIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: activeIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              selectedItemColor: primaryColor,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              items: navItems,
            ),
          );
        },
      ),
    );
  }
}
