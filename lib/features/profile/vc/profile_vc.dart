import 'dart:io';
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

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final d = await _api.getProfile();
      state = state.copyWith(loading: false, data: d);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> togglePrivate(bool v) async {
    state = state.copyWith(uploading: true, error: null);
    try {
      final d = await _api.updateProfile({'is_private': v});
      state = state.copyWith(uploading: false, data: d);
    } catch (e) {
      state = state.copyWith(uploading: false, error: e.toString());
    }
  }

  Future<void> uploadAvatar(File file) async {
    state = state.copyWith(uploading: true, error: null);
    try {
      final d = await _api.uploadAvatar(file);
      state = state.copyWith(uploading: false, data: d);
    } catch (e) {
      state = state.copyWith(uploading: false, error: e.toString());
    }
  }

  Future<void> uploadCover(File file) async {
    state = state.copyWith(uploading: true, error: null);
    try {
      final d = await _api.uploadCover(file);
      state = state.copyWith(uploading: false, data: d);
    } catch (e) {
      state = state.copyWith(uploading: false, error: e.toString());
    }
  }
}

final profileVCProvider = NotifierProvider<ProfileVC, ProfileState>(
  ProfileVC.new,
);
