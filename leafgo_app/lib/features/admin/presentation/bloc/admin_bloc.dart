// lib/features/admin/presentation/bloc/admin_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository repository;

  AdminBloc({required this.repository}) : super(AdminInitial()) {
    on<AdminFetchDashboardData>((event, emit) async {
      emit(AdminLoading());
      try {
        final stats = await repository.getStatistics(event.accessToken);
        emit(AdminDashboardLoaded(stats));
      } catch (e) {
        emit(AdminFailure(e.toString()));
      }
    });

    on<AdminFetchUsers>((event, emit) async {
      emit(AdminLoading());
      try {
        final users = await repository.getUsers(
          accessToken: event.accessToken,
          page: event.page,
          role: event.role,
          search: event.search,
        );
        emit(AdminUsersLoaded(users));
      } catch (e) {
        emit(AdminFailure(e.toString()));
      }
    });

    on<AdminFetchRides>((event, emit) async {
      emit(AdminLoading());
      try {
        final rides = await repository.getRides(
          accessToken: event.accessToken,
          page: event.page,
        );
        emit(AdminRidesLoaded(rides));
      } catch (e) {
        emit(AdminFailure(e.toString()));
      }
    });

    on<AdminFetchVehicleTypes>((event, emit) async {
      emit(AdminLoading());
      try {
        final vehicleTypes = await repository.getVehicleTypes(event.accessToken);
        emit(AdminVehicleTypesLoaded(vehicleTypes));
      } catch (e) {
        emit(AdminFailure(e.toString()));
      }
    });
  }
}
