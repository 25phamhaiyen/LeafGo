import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leafgo_app/models/auth/userEntity/user_models.dart';
import '../../services/repositories/user_repository.dart';
import '../../services/datasources/auth_local_datasource.dart';
import 'package:image_picker/image_picker.dart';

// ── Events ──────────────────────────────────────────────────
abstract class UserEvent {}

class UserFetchProfile extends UserEvent {}

class UserUpdateProfile extends UserEvent {
  final String fullName;
  final String phoneNumber;
  UserUpdateProfile(this.fullName, this.phoneNumber);
}

class UserUploadAvatar extends UserEvent {
  final XFile imageFile;
  UserUploadAvatar(this.imageFile);
}

class UserFetchHistory extends UserEvent {
  final int page;
  final int pageSize;
  final String? status;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool refreshSummary;

  UserFetchHistory({
    this.page = 1,
    this.pageSize = 10,
    this.status,
    this.fromDate,
    this.toDate,
    this.refreshSummary = true,
  });
}

// ── State ───────────────────────────────────────────────────
class UserState {
  final UserModel? profile;
  final Map<String, dynamic>? historyData;
  final Map<String, dynamic>? historyStats;
  final bool isLoading;
  final String? error;

  UserState({
    this.profile,
    this.historyData,
    this.historyStats,
    this.isLoading = false,
    this.error,
  });

  UserState copyWith({
    UserModel? profile,
    Map<String, dynamic>? historyData,
    Map<String, dynamic>? historyStats,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      profile: profile ?? this.profile,
      historyData: historyData ?? this.historyData,
      historyStats: historyStats ?? this.historyStats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ── BLoC ────────────────────────────────────────────────────
class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository repository;
  final AuthLocalDataSource authLocalDataSource;

  UserBloc({required this.repository, required this.authLocalDataSource})
    : super(UserState()) {
    on<UserFetchProfile>(_onFetchProfile);
    on<UserUpdateProfile>(_onUpdateProfile);
    on<UserUploadAvatar>(_onUploadAvatar);
    on<UserFetchHistory>(_onFetchHistory);
  }

  Future<String?> _getToken() async {
    final user = await authLocalDataSource.getCachedUser();
    return user?.accessToken;
  }

  Future<void> _onFetchProfile(
    UserFetchProfile event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');
      final profile = await repository.getProfile(token);
      UserModel updatedProfile = profile;
      final cachedUser = await authLocalDataSource.getCachedUser();
      if (cachedUser != null) {
        updatedProfile = profile.copyWith(
          accessToken: cachedUser.accessToken,
          refreshToken: cachedUser.refreshToken,
          expiresAt: cachedUser.expiresAt,
        );
        await authLocalDataSource.saveUser(updatedProfile);
      }
      emit(state.copyWith(profile: updatedProfile, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onUpdateProfile(
    UserUpdateProfile event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');
      final profile = await repository.updateProfile(
        event.fullName,
        event.phoneNumber,
        token,
      );
      UserModel updatedProfile = profile;
      final cachedUser = await authLocalDataSource.getCachedUser();
      if (cachedUser != null) {
        updatedProfile = profile.copyWith(
          accessToken: cachedUser.accessToken,
          refreshToken: cachedUser.refreshToken,
          expiresAt: cachedUser.expiresAt,
        );
        await authLocalDataSource.saveUser(updatedProfile);
      }
      emit(state.copyWith(profile: updatedProfile, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onUploadAvatar(
    UserUploadAvatar event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');
      final avatarUrl = await repository.uploadAvatar(event.imageFile, token);
      final updatedProfile = state.profile?.copyWith(avatar: avatarUrl);
      if (updatedProfile != null) {
        UserModel updatedWithTokens = updatedProfile;
        final cachedUser = await authLocalDataSource.getCachedUser();
        if (cachedUser != null) {
          updatedWithTokens = updatedProfile.copyWith(
            accessToken: cachedUser.accessToken,
            refreshToken: cachedUser.refreshToken,
            expiresAt: cachedUser.expiresAt,
          );
          await authLocalDataSource.saveUser(updatedWithTokens);
        }
        emit(state.copyWith(profile: updatedWithTokens, isLoading: false));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onFetchHistory(
    UserFetchHistory event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      Map<String, dynamic>? summaryStats = state.historyStats;
      if (event.refreshSummary) {
        // Use a reasonable upper bound for pageSize to avoid triggering server-side validation errors
        const int summaryPageSize = 100;
        final summaryHistory = await repository.getRideHistory(
          page: 1,
          pageSize: summaryPageSize,
          status: event.status,
          fromDate: event.fromDate,
          toDate: event.toDate,
          token: token,
        );
        final summaryItems = summaryHistory['items'] as List? ?? [];
        summaryStats = _computeHistoryStats(summaryItems);
      }

      final history = await repository.getRideHistory(
        page: event.page,
        pageSize: event.pageSize,
        status: event.status,
        fromDate: event.fromDate,
        toDate: event.toDate,
        token: token,
      );

      emit(
        state.copyWith(
          historyData: history,
          historyStats: summaryStats,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Map<String, dynamic> _computeHistoryStats(List items) {
    int completed = 0;
    double totalSpent = 0;
    double totalRating = 0;
    int ratingCount = 0;

    for (final ride in items) {
      if (ride['status'] == 'Completed') {
        completed++;
        totalSpent +=
            (ride['finalPrice'] ?? ride['estimatedPrice'] ?? 0) as num;
        if (ride['rating'] != null) {
          totalRating += (ride['rating']['rating'] as num).toDouble();
          ratingCount++;
        }
      }
    }

    return {
      'completed': completed,
      'totalSpent': totalSpent,
      'avgRating': ratingCount > 0 ? totalRating / ratingCount : 0.0,
      'ratingCount': ratingCount,
    };
  }
}
