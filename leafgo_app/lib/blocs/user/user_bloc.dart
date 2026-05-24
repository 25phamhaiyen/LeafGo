import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/repositories/user_repository.dart';
import '../../models/auth_models.dart';
import '../../services/datasources/auth_local_datasource.dart';

// ── Events ──────────────────────────────────────────────────
abstract class UserEvent {}

class UserFetchProfile extends UserEvent {}
class UserUpdateProfile extends UserEvent {
  final String fullName;
  final String phoneNumber;
  UserUpdateProfile(this.fullName, this.phoneNumber);
}
class UserFetchHistory extends UserEvent {
  final int page;
  final String? status;
  UserFetchHistory({this.page = 1, this.status});
}

// ── State ───────────────────────────────────────────────────
class UserState {
  final UserModel? profile;
  final Map<String, dynamic>? historyData;
  final bool isLoading;
  final String? error;

  UserState({
    this.profile,
    this.historyData,
    this.isLoading = false,
    this.error,
  });

  UserState copyWith({
    UserModel? profile,
    Map<String, dynamic>? historyData,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      profile: profile ?? this.profile,
      historyData: historyData ?? this.historyData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ── BLoC ────────────────────────────────────────────────────
class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository repository;
  final AuthLocalDataSource authLocalDataSource;

  UserBloc({
    required this.repository,
    required this.authLocalDataSource,
  }) : super(UserState()) {
    on<UserFetchProfile>(_onFetchProfile);
    on<UserUpdateProfile>(_onUpdateProfile);
    on<UserFetchHistory>(_onFetchHistory);
  }

  Future<String?> _getToken() async {
    final user = await authLocalDataSource.getCachedUser();
    return user?.accessToken;
  }

  Future<void> _onFetchProfile(UserFetchProfile event, Emitter<UserState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');
      final profile = await repository.getProfile(token);
      emit(state.copyWith(profile: profile, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onUpdateProfile(UserUpdateProfile event, Emitter<UserState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');
      final profile = await repository.updateProfile(event.fullName, event.phoneNumber, token);
      emit(state.copyWith(profile: profile, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onFetchHistory(UserFetchHistory event, Emitter<UserState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');
      final history = await repository.getRideHistory(page: event.page, status: event.status, token: token);
      emit(state.copyWith(historyData: history, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }
}
