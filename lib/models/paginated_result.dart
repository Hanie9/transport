class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.count,
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
  });

  final List<T> items;
  final int count;
  final int currentPage;
  final int totalPages;
  final bool hasNext;
}
