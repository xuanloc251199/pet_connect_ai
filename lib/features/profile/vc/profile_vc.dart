import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/vc/auth_providers.dart';
import '../model/profile_api.dart';

class ProfileState {
  final bool loading;
  final bool uploading;
  final String? error;
  final Map<String, dynamic>? data;

  const ProfileState({
    this.loading = false,
    this.uploading = false,
    this.error,
    this.data,
  });

  ProfileState copyWith({
    bool? loading,
    bool? uploading,
    String? error,
    Map<String, dynamic>? data,
  }) {
    return ProfileState(
      loading: loading ?? this.loading,
      uploading: uploading ?? this.uploading,
      error: error,
      data: data ?? this.data,
    );
  }
}

class ProfileVC extends Notifier<ProfileState> {
  @override
  ProfileState build() => const ProfileState();

  ProfileApi get _api => ProfileApi(ref.read(apiClientProvider));

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
      final d = await _api.getProfile();
      state = state.copyWith(loading: false, data: d);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: _friendlyError(e as Object),
      );
    }
  }

  Future<bool> update(Map<String, dynamic> payload) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final d = await _api.updateProfile(payload);

      final patch = _extractProfilePatch(d);
      final merged = _merge(state.data, patch);

      state = state.copyWith(loading: false, data: merged);
      return true;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: _friendlyError(e as Object),
      );
      return false;
    }
  }

  Future<void> togglePrivate(bool v) async {
    await update({'is_private': v});
  }

  Future<void> uploadAvatar(File file) async {
    state = state.copyWith(uploading: true, error: null);
    try {
      final d = await _api.uploadAvatar(file);

      final patch = _extractProfilePatch(d);
      final merged = _merge(state.data, patch);

      state = state.copyWith(uploading: false, data: merged);
    } catch (e) {
      state = state.copyWith(
        uploading: false,
        error: _friendlyError(e as Object),
      );
    }
  }

  Future<void> uploadCover(File file) async {
    state = state.copyWith(uploading: true, error: null);
    try {
      final d = await _api.uploadCover(file);

      final patch = _extractProfilePatch(d);
      final merged = _merge(state.data, patch);

      state = state.copyWith(uploading: false, data: merged);
    } catch (e) {
      state = state.copyWith(
        uploading: false,
        error: _friendlyError(e as Object),
      );
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // ignore
    }
  }

  void clearError() => state = state.copyWith(error: null);

  Map<String, dynamic> _extractProfilePatch(Map<String, dynamic> apiData) {
    if (apiData['user'] is Map) {
      return Map<String, dynamic>.from(apiData['user'] as Map);
    }
    return apiData;
  }

  Map<String, dynamic> _merge(
    Map<String, dynamic>? current,
    Map<String, dynamic> patch,
  ) {
    final merged = <String, dynamic>{};
    if (current != null) merged.addAll(current);
    merged.addAll(patch); // patch override keys
    return merged;
  }
}

final profileVCProvider = NotifierProvider<ProfileVC, ProfileState>(
  ProfileVC.new,
);
