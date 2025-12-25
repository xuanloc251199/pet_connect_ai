import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/core/api_client.dart';
import '../../../app/core/token_storage.dart';
import '../model/category_interest_model.dart';

class InterestsState {
  final bool loading;
  final bool hasPet;
  final List<InterestCategory> categories;
  final Set<int> selectedIds;

  const InterestsState({
    this.loading = false,
    this.hasPet = true,
    this.categories = const [],
    this.selectedIds = const {},
  });

  InterestsState copyWith({
    bool? loading,
    bool? hasPet,
    List<InterestCategory>? categories,
    Set<int>? selectedIds,
  }) {
    return InterestsState(
      loading: loading ?? this.loading,
      hasPet: hasPet ?? this.hasPet,
      categories: categories ?? this.categories,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

class InterestsVC extends Notifier<InterestsState> {
  late final Dio _dio;
  late final TokenStorage _tokenStorage;

  @override
  InterestsState build() {
    _dio = ApiClient().dio;
    _tokenStorage = TokenStorage();
    return const InterestsState();
  }

  // GET /categories
  Future<void> load() async {
    state = state.copyWith(loading: true);
    try {
      final res = await _dio.get('/categories');
      final data =
          (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final cats = (data['categories'] as List?) ?? [];

      final parsed = cats
          .map((e) => InterestCategory.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(loading: false, categories: parsed);
    } catch (e) {
      state = state.copyWith(loading: false);
      rethrow;
    }
  }

  void toggleHasPet(bool v) {
    state = state.copyWith(hasPet: v);
  }

  void toggleInterestId(int id) {
    final next = Set<int>.from(state.selectedIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = state.copyWith(selectedIds: next);
  }

  // PUT /user/interests
  Future<void> submit() async {
    if (state.selectedIds.isEmpty) {
      throw Exception('Please select at least 1 interest');
    }

    final token = await _tokenStorage.readToken();
    if (token == null) {
      throw Exception('Missing token. Please login again.');
    }

    state = state.copyWith(loading: true);
    try {
      await _dio.put(
        '/user/interests',
        data: {
          'has_pet': state.hasPet,
          'interest_ids': state.selectedIds.toList(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(loading: false);
      rethrow;
    }
  }
}

final interestsVCProvider = NotifierProvider<InterestsVC, InterestsState>(
  InterestsVC.new,
);
