import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/auth_api.dart';
import 'auth_providers.dart';

class InterestsState {
  final bool loading;
  final bool hasPet;
  final String? error;
  final List<dynamic> categories;
  final Set<int> selectedIds;

  const InterestsState({
    this.loading = false,
    this.hasPet = true,
    this.error,
    this.categories = const [],
    this.selectedIds = const {},
  });

  InterestsState copyWith({
    bool? loading,
    bool? hasPet,
    String? error,
    List<dynamic>? categories,
    Set<int>? selectedIds,
  }) {
    return InterestsState(
      loading: loading ?? this.loading,
      hasPet: hasPet ?? this.hasPet,
      error: error,
      categories: categories ?? this.categories,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

class InterestsVC extends Notifier<InterestsState> {
  @override
  InterestsState build() => const InterestsState();

  AuthApi get _api => ref.read(authApiProvider);

  String _friendlyError(Object e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return 'Kết nối quá lâu. Vui lòng thử lại.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Không thể kết nối mạng. Kiểm tra Wi-Fi/4G rồi thử lại.';
      }

      final status = e.response?.statusCode;
      final data = e.response?.data;

      if (data is Map) {
        final body = Map<String, dynamic>.from(data);
        final msg = body['message']?.toString();
        if (msg != null && msg.trim().isNotEmpty) return msg;

        final errors = body['errors'];
        if (errors is Map) {
          for (final entry in errors.entries) {
            final v = entry.value;
            if (v is List && v.isNotEmpty) return v.first.toString();
            if (v != null) return v.toString();
          }
        }
      }

      if (status == 401)
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      if (status == 422) return 'Thông tin chưa hợp lệ. Vui lòng kiểm tra lại.';
      if (status != null && status >= 500)
        return 'Hệ thống đang bận. Vui lòng thử lại sau.';
      return 'Có lỗi xảy ra. Vui lòng thử lại.';
    }

    final s = e.toString();
    return s.startsWith('Exception: ')
        ? s.replaceFirst('Exception: ', '')
        : 'Có lỗi xảy ra. Vui lòng thử lại.';
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await _api.fetchCategories();

      final data = res['data'];
      final cats = (data is Map) ? data['categories'] : null;

      if (cats is! List) {
        throw Exception('Không đọc được danh sách sở thích.');
      }

      state = state.copyWith(
        loading: false,
        categories: List<dynamic>.from(cats),
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: _friendlyError(e as Object),
      );
    }
  }

  void toggleHasPet(bool v) => state = state.copyWith(hasPet: v);

  void toggleInterestId(int id) {
    final next = Set<int>.from(state.selectedIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = state.copyWith(selectedIds: next);
  }

  Future<bool> submit() async {
    if (state.selectedIds.isEmpty) {
      state = state.copyWith(error: 'Bạn hãy chọn ít nhất 1 sở thích nhé.');
      return false;
    }

    state = state.copyWith(loading: true, error: null);
    try {
      await _api.saveInterests(
        hasPet: state.hasPet,
        interestIds: state.selectedIds.toList(),
      );
      state = state.copyWith(loading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: _friendlyError(e as Object),
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final interestsVCProvider = NotifierProvider<InterestsVC, InterestsState>(
  InterestsVC.new,
);
