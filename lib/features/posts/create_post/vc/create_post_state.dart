class CreatePostState {
  final bool loading;
  final String? error;
  final bool success;

  const CreatePostState({
    this.loading = false,
    this.error,
    this.success = false,
  });

  CreatePostState copyWith({bool? loading, String? error, bool? success}) {
    return CreatePostState(
      loading: loading ?? this.loading,
      error: error,
      success: success ?? this.success,
    );
  }
}
