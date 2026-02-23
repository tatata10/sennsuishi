import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../data/formula_data.dart';

class FormulaScreen extends ConsumerStatefulWidget {
  const FormulaScreen({super.key});

  @override
  ConsumerState<FormulaScreen> createState() => _FormulaScreenState();
}

class _FormulaScreenState extends ConsumerState<FormulaScreen> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Filter formulas based on search query
    final filteredFormulas = importantFormulas
        .where((f) =>
            f.title.contains(searchQuery) ||
            f.formula.contains(searchQuery) ||
            f.description.contains(searchQuery) ||
            f.category.contains(searchQuery))
        .toList();

    // Group formulas by category
    final Map<String, List<Formula>> groupedFormulas = {};
    for (final formula in filteredFormulas) {
      groupedFormulas.putIfAbsent(formula.category, () => []).add(formula);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('重要公式集'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: '式、名称、キーワードで検索...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: groupedFormulas.isEmpty && searchQuery.isNotEmpty
          ? _buildNoResults()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedFormulas.length,
              itemBuilder: (context, categoryIndex) {
                final category = groupedFormulas.keys.elementAt(categoryIndex);
                final formulas = groupedFormulas[category]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (categoryIndex > 0) const SizedBox(height: 24),
                    // Category Header
                    _buildCategoryHeader(category),
                    const SizedBox(height: 12),
                    // Formula Cards
                    ...formulas
                        .map((formula) => _FormulaCard(formula: formula)),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildCategoryHeader(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.navy, Color(0xFF34495E)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.science_outlined,
              color: AppTheme.mintGreen, size: 20),
          const SizedBox(width: 8),
          Text(
            category,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            '一致する公式が見つかりませんでした',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _FormulaCard extends StatelessWidget {
  final Formula formula;

  const _FormulaCard({required this.formula});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.mintGreen,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formula.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.navy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Formula Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.mintGreen.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Text(
                formula.formula,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              formula.description,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
