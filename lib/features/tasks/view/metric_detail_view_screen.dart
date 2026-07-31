import 'package:flutter/material.dart';
import 'package:forja/core/theme.dart';
import 'package:forja/domain/entities/progress_area_entity.dart';
import 'package:forja/shared/widgets/formatted_text.dart';

class MetricDetailViewScreen extends StatelessWidget {
  const MetricDetailViewScreen({
    super.key,
    required this.metricTitle,
    required this.details,
  });

  final String metricTitle;
  final List<MetricDetailEntity> details;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(metricTitle), elevation: 0),
      body: details.isEmpty
          ? const Center(child: Text('Nenhum detalhe cadastrado.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: details.length,
              itemBuilder: (context, index) {
                final detail = details[index];
                return _TopicCard(detail: detail);
              },
            ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.detail});
  final MetricDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: ForjaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ForjaColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bookmark_rounded,
                      color: ForjaColors.ember,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        detail.title,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ForjaColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (detail.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  FormattedText(
                    data: detail.description,
                    style: text.bodyMedium?.copyWith(
                      color: ForjaColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (detail.items.isNotEmpty) ...[
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: detail.items.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
              itemBuilder: (context, index) {
                final item = detail.items[index];
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: text.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ForjaColors.ember,
                          fontSize: 15,
                        ),
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        FormattedText(
                          data: item.description,
                          style: text.bodyMedium?.copyWith(
                            height: 1.5,
                            color: ForjaColors.textPrimary.withValues(
                              alpha: 0.9,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
