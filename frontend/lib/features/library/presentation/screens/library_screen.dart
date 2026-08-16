// frontend/lib/features/library/presentation/screens/library_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';
import '../../widgets/book_card.dart';
import '../../widgets/book_detail_screen.dart';
import '../../widgets/create_book_dialog.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/book.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryProvider>().loadBooks();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<LibraryProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, provider, child) {
        final isMobile = MediaQuery.of(context).size.width < 600;

        return Scaffold(
          backgroundColor: AppColors.background,
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateBookDialog(context, provider),
            child: const Icon(Icons.add),
            backgroundColor: AppColors.primary,
          ),
          body: Column(
            children: [
              _buildHeader(isMobile),
              _buildFilters(isMobile, provider),
              Expanded(
                child: _buildBookList(provider, isMobile),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Text(
            '📚 Bibliothèque',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (!isMobile)
            Container(
              width: 300,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                onChanged: (value) {
                  context.read<LibraryProvider>().setSearchQuery(value);
                },
                decoration: const InputDecoration(
                  hintText: '🔍 Rechercher un livre...',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isMobile, LibraryProvider provider) {
    if (isMobile) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          if (provider.selectedLevel != null)
            _FilterChip(
              label: 'Niveau: ${provider.selectedLevel}',
              onRemove: () => provider.setLevelFilter(null),
            ),
          if (provider.selectedSubjectId != null)
            _FilterChip(
              label: 'Matière',
              onRemove: () => provider.setSubjectFilter(null),
            ),
          if ((provider.selectedLevel != null || provider.selectedSubjectId != null))
            TextButton(
              onPressed: provider.clearFilters,
              child: const Text('Effacer les filtres'),
            ),
          const Spacer(),
          Text(
            '${provider.books.length} livres',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookList(LibraryProvider provider, bool isMobile) {
    if (provider.isLoading && provider.books.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadBooks(refresh: true),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (provider.books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 64,
              color: AppColors.textTertiary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun livre disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Soyez le premier à publier un livre !',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: provider.books.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.books.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final book = provider.books[index];
        return BookCard(
          book: book,
          onTap: () => _navigateToBookDetail(context, book, provider),
        );
      },
    );
  }

  // ✅ Passer le provider à BookDetailScreen
  void _navigateToBookDetail(BuildContext context, Book book, LibraryProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailScreen(
          book: book,
          provider: provider,  // ✅ Passer le provider
        ),
      ),
    );
  }

  void _showCreateBookDialog(BuildContext context, LibraryProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateBookDialog(provider: provider),
    );
  }

  void _showFilterDialog(BuildContext context) {
    // TODO: Implémenter le dialogue de filtres
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14),
          ),
        ],
      ),
    );
  }
}