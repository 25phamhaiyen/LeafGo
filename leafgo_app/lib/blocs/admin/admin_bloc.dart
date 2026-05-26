// lib/features/admin/presentation/bloc/admin_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/auth_models.dart';
import '../../services/repositories/admin_repository.dart';
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
          pageSize: event.pageSize,
          role: event.role,
          search: event.search,
          isActive: event.isActive,
          isOnline: event.isOnline,
        );
        emit(AdminUsersLoaded(users));
      } catch (e) {
        emit(AdminFailure(e.toString()));
      }
    });

    on<AdminCreateUser>((event, emit) async {
      emit(AdminLoading());
      try {
        await repository.createUser(
          event.accessToken,
          RegisterRequest(
            email: event.email,
            password: event.password,
            fullName: event.fullName,
            phoneNumber: event.phoneNumber,
            role: event.role,
          ),
        );
        emit(AdminActionSuccess('Đã tạo người dùng'));
      } catch (e) {
        emit(AdminFailure(e.toString()));
      }
    });

    on<AdminUpdateUser>((event, emit) async {
      emit(AdminLoading());
      try {
        await repository.updateUser(event.accessToken, event.id, {
          'fullName': event.fullName,
          'phoneNumber': event.phoneNumber,
          'isActive': event.isActive,
        });
        emit(AdminActionSuccess('Đã cập nhật người dùng'));
      } catch (e) {
        emit(AdminFailure(e.toString()));
      }
    });

    on<AdminDeleteUser>((event, emit) async {
      emit(AdminLoading());
      try {
        await repository.deleteUser(event.accessToken, event.id);
        emit(AdminActionSuccess('Đã xóa người dùng'));
      } catch (e) {
        emit(AdminFailure(e.toString()));
      }
    });

    on<AdminToggleUserStatus>((event, emit) async {
      emit(AdminLoading());
      try {
        await repository.toggleUserStatus(
          event.accessToken,
          event.id,
          event.isActive,
        );
        emit(AdminActionSuccess('Đã cập nhật trạng thái'));
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
          pageSize: event.pageSize,
          status: event.status,
          fromDate: event.fromDate,
          toDate: event.toDate,
          userId: event.userId,
          driverId: event.driverId,
        );
        emit(AdminRidesLoaded(rides));
      } catch (e) {
        emit(AdminFailure(e.toString()));
      }
    });

    on<AdminFetchVehicleTypes>((event, emit) async {
      emit(AdminLoading());
      try {
        final vehicleTypes = await repository.getVehicleTypes(
          event.accessToken,
        );
        emit(AdminVehicleTypesLoaded(vehicleTypes));
      } catch (e) {
        emit(AdminFailure(e.toString()));
      }
    });

    on<AdminCreateVehicleType>((event, emit) async {
      emit(AdminLoading());
      try {
        await repository.createVehicleType(event.accessToken, {
          'name': event.name,
          'basePrice': event.basePrice,
          'pricePerKm': event.pricePerKm,
          'description': event.description,
        });
        emit(AdminActionSuccess('Đã tạo loại xe'));
      } catch (e) {
        emit(AdminFailure(e.toString()));
      }
    });

    on<AdminUpdateVehicleType>((event, emit) async {
      emit(AdminLoading());
      try {
        await repository.updateVehicleType(event.accessToken, event.id, {
          'name': event.name,
          'basePrice': event.basePrice,
          'pricePerKm': event.pricePerKm,
          'description': event.description,
          'isActive': event.isActive,
        });
        emit(AdminActionSuccess('Đã cập nhật loại xe'));
      } catch (e) {
        emit(AdminFailure(e.toString()));
      }
    });

    on<AdminDeleteVehicleType>((event, emit) async {
      emit(AdminLoading());
      try {
        await repository.deleteVehicleType(event.accessToken, event.id);
        emit(AdminActionSuccess('Đã xóa loại xe'));
      } catch (e) {
        emit(AdminFailure(e.toString()));
      }
    });
  }
}
