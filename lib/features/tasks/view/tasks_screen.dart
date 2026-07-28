import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:forja/core/theme.dart';
import 'package:forja/domain/entities/progress_area_entity.dart';
import 'package:forja/features/tasks/view/metric_detail_view_screen.dart';
import 'package:forja/features/tasks/bloc/progress_bloc.dart';
import 'package:forja/features/tasks/bloc/progress_event.dart';
import 'package:forja/features/tasks/router/tasks_router.dart';
import 'package:forja/features/tasks/view/metric_detail_form_screen.dart';

enum _AreaAction { edit, delete }

enum _MetricAction { edit, delete }

class ProgressAreasScreen extends StatelessWidget {
  const ProgressAreasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final areas = context.watch<ProgressBloc>().state.areas;
    final metrics = areas.expand((area) => area.metrics).toList();
    final average = metrics.isEmpty
        ? 0
        : (metrics.fold<int>(0, (sum, metric) => sum + metric.percent) /
                  metrics.length)
              .round();
    final strongestArea = areas
        .where((area) => area.metrics.isNotEmpty)
        .fold<ProgressAreaEntity?>(null, (best, area) {
          if (best == null) return area;
          return area.averagePercent >= best.averagePercent ? area : best;
        });

    return Scaffold(
      appBar: AppBar(title: const Text('Evolução')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(TasksRouter.newArea),
        backgroundColor: ForjaColors.ember,
        foregroundColor: ForjaColors.onEmber,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Área'),
      ),
      body: SafeArea(
        child: areas.isEmpty
            ? _EmptyAreasState(
                onCreate: () => context.push(TasksRouter.newArea),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: areas.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _AreasOverview(
                      average: average,
                      areasCount: areas.length,
                      metricsCount: metrics.length,
                      strongestArea: strongestArea?.title,
                    );
                  }

                  final area = areas[index - 1];
                  return _AreaCard(
                    area: area,
                    onOpen: () =>
                        context.push(TasksRouter.detailLocation(area.id)),
                    onEdit: () =>
                        context.push(TasksRouter.editAreaLocation(area.id)),
                    onDelete: () => _confirmDeleteArea(context, area),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _confirmDeleteArea(
    BuildContext context,
    ProgressAreaEntity area,
  ) async {
    final progressBloc = context.read<ProgressBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ForjaColors.surface,
        title: const Text('Apagar área?'),
        content: Text(
          'Isso remove "${area.title}" e todos os indicadores registrados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: ForjaColors.error),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      progressBloc.add(ProgressAreaDeleted(area.id));
    }
  }
}

class ProgressAreaDetailScreen extends StatelessWidget {
  const ProgressAreaDetailScreen({super.key, required this.areaId});

  final String areaId;

  @override
  Widget build(BuildContext context) {
    final areas = context.watch<ProgressBloc>().state.areas;
    final area = _findArea(areas, areaId);

    return Scaffold(
      appBar: AppBar(
        title: Text(area?.title ?? 'Área'),
        actions: [
          if (area != null)
            IconButton(
              tooltip: 'Editar área',
              onPressed: () =>
                  context.push(TasksRouter.editAreaLocation(area.id)),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      floatingActionButton: area == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () =>
                  context.push(TasksRouter.newMetricLocation(area.id)),
              backgroundColor: ForjaColors.ember,
              foregroundColor: ForjaColors.onEmber,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Indicador'),
            ),
      body: SafeArea(
        child: area == null
            ? const _MissingAreaState()
            : area.metrics.isEmpty
            ? _EmptyMetricsState(
                areaTitle: area.title,
                onCreate: () =>
                    context.push(TasksRouter.newMetricLocation(area.id)),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: area.metrics.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) return _AreaDetailHeader(area: area);

                  final metric = area.metrics[index - 1];
                  return _MetricCard(
                    metric: metric,
                    onEdit: () => context.push(
                      TasksRouter.editMetricLocation(area.id, metric.id),
                    ),
                    onDelete: () => _confirmDeleteMetric(context, area, metric),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _confirmDeleteMetric(
    BuildContext context,
    ProgressAreaEntity area,
    ProgressMetricEntity metric,
  ) async {
    final progressBloc = context.read<ProgressBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ForjaColors.surface,
        title: const Text('Apagar indicador?'),
        content: Text('Isso remove "${metric.title}" e o histórico dele.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: ForjaColors.error),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      progressBloc.add(
        ProgressMetricDeleted(areaId: area.id, metricId: metric.id),
      );
    }
  }
}

class _AreasOverview extends StatelessWidget {
  const _AreasOverview({
    required this.average,
    required this.areasCount,
    required this.metricsCount,
    required this.strongestArea,
  });

  final int average;
  final int areasCount;
  final int metricsCount;
  final String? strongestArea;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(
                icon: Icons.auto_graph_rounded,
                color: Colors.lightBlueAccent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mapa de áreas',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '$average%',
                style: text.headlineSmall?.copyWith(
                  color: ForjaColors.ember,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ProgressBar(value: average / 100),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _OverviewMetric(label: 'Áreas', value: '$areasCount'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OverviewMetric(
                  label: 'Indicadores',
                  value: '$metricsCount',
                ),
              ),
            ],
          ),
          if (strongestArea != null) ...[
            const SizedBox(height: 8),
            _OverviewMetric(label: 'Maior média', value: strongestArea!),
          ],
        ],
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({
    required this.area,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final ProgressAreaEntity area;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final updated = DateFormat('dd/MM/yyyy').format(area.updatedAt);

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _IconBadge(icon: Icons.track_changes_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        area.title,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${area.metrics.length} indicadores',
                        style: text.bodySmall?.copyWith(
                          color: ForjaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${area.averagePercent}%',
                  style: text.headlineSmall?.copyWith(
                    color: ForjaColors.ember,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton<_AreaAction>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (action) {
                    switch (action) {
                      case _AreaAction.edit:
                        onEdit();
                        break;
                      case _AreaAction.delete:
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _AreaAction.edit,
                      child: Text('Editar'),
                    ),
                    PopupMenuItem(
                      value: _AreaAction.delete,
                      child: Text('Apagar'),
                    ),
                  ],
                ),
              ],
            ),
            if (area.description.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                area.description,
                style: text.bodyMedium?.copyWith(height: 1.35),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            _ProgressBar(value: area.progress),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Atualizado em $updated',
                    style: text.bodySmall?.copyWith(
                      color: ForjaColors.textSecondary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: ForjaColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaDetailHeader extends StatelessWidget {
  const _AreaDetailHeader({required this.area});

  final ProgressAreaEntity area;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final strongest = area.strongestMetric?.title ?? '--';
    final weakest = area.weakestMetric?.title ?? '--';

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBadge(icon: Icons.insights_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Evolução da área',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${area.averagePercent}%',
                style: text.headlineSmall?.copyWith(
                  color: ForjaColors.ember,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (area.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              area.description,
              style: text.bodyMedium?.copyWith(height: 1.35),
            ),
          ],
          const SizedBox(height: 14),
          _ProgressBar(value: area.progress),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _OverviewMetric(label: 'Maior nível', value: strongest),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OverviewMetric(label: 'Menor nível', value: weakest),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.metric,
    required this.onEdit,
    required this.onDelete,
  });

  final ProgressMetricEntity metric;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final updated = DateFormat('dd/MM/yyyy').format(metric.updatedAt);
    final evolution = metric.evolution;

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(16),
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _IconBadge(icon: Icons.speed_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metric.title,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metric.statusLabel,
                        style: text.bodySmall?.copyWith(
                          color: ForjaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${metric.percent}%',
                  style: text.headlineSmall?.copyWith(
                    color: ForjaColors.ember,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton<_MetricAction>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (action) {
                    switch (action) {
                      case _MetricAction.edit:
                        onEdit();
                        break;
                      case _MetricAction.delete:
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _MetricAction.edit,
                      child: Text('Editar'),
                    ),
                    PopupMenuItem(
                      value: _MetricAction.delete,
                      child: Text('Apagar'),
                    ),
                  ],
                ),
              ],
            ),
            if (metric.description.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                metric.description,
                style: text.bodyMedium?.copyWith(height: 1.35),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            _ProgressBar(value: metric.progress),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Atualizado em $updated',
                    style: text.bodySmall?.copyWith(
                      color: ForjaColors.textSecondary,
                    ),
                  ),
                ),
                if (evolution != 0)
                  _EvolutionPill(value: evolution, isPositive: evolution > 0),
              ],
            ),
            if (metric.history.length > 1) ...[
              const SizedBox(height: 12),
              _HistoryPreview(history: metric.history),
            ],
            if (metric.details.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _MetricDetailsList(
                metricTitle: metric.title,
                details: metric.details,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricDetailsList extends StatelessWidget {
  const _MetricDetailsList({required this.metricTitle, required this.details});

  final String metricTitle;
  final List<MetricDetailEntity> details;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final totalItems = details.fold<int>(0, (sum, d) => sum + d.items.length);

    return Material(
      color: ForjaColors.ember.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MetricDetailViewScreen(
                metricTitle: metricTitle,
                details: details,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ForjaColors.ember.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  size: 16,
                  color: ForjaColors.ember,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONTEÚDO DE ESTUDO',
                      style: text.labelSmall?.copyWith(
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                        color: ForjaColors.ember,
                      ),
                    ),
                    Text(
                      '${details.length} tópicos • $totalItems itens detalhados',
                      style: text.bodySmall?.copyWith(
                        color: ForjaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: ForjaColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ForjaColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ForjaColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: text.titleLarge?.copyWith(
              color: ForjaColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: text.bodySmall?.copyWith(color: ForjaColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EvolutionPill extends StatelessWidget {
  const _EvolutionPill({required this.value, required this.isPositive});

  final int value;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? Colors.green : ForjaColors.error;
    final sign = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$sign$value pts',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HistoryPreview extends StatelessWidget {
  const _HistoryPreview({required this.history});

  final List<SkillCheckpointEntity> history;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final recent = history.reversed.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Histórico',
          style: text.labelSmall?.copyWith(color: ForjaColors.textSecondary),
        ),
        const SizedBox(height: 6),
        for (final entry in recent)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    '${entry.percent}%',
                    style: const TextStyle(
                      color: ForjaColors.ember,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.note.trim().isEmpty
                        ? DateFormat('dd/MM').format(entry.createdAt)
                        : entry.note,
                    style: text.bodySmall?.copyWith(
                      color: ForjaColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EmptyAreasState extends StatelessWidget {
  const _EmptyAreasState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _IconBadge(
              icon: Icons.auto_graph_rounded,
              size: 56,
              iconSize: 30,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma área registrada',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Crie uma área como estudo, academia, alimentação, sono ou trabalho.',
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('CRIAR ÁREA'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMetricsState extends StatelessWidget {
  const _EmptyMetricsState({required this.areaTitle, required this.onCreate});

  final String areaTitle;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _IconBadge(icon: Icons.speed_rounded, size: 56, iconSize: 30),
            const SizedBox(height: 16),
            Text(
              'Nenhum indicador',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione indicadores de $areaTitle e marque seu nível.',
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('CRIAR INDICADOR'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingAreaState extends StatelessWidget {
  const _MissingAreaState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Área não encontrada.'));
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ForjaColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ForjaColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value,
        backgroundColor: ForjaColors.divider,
        valueColor: const AlwaysStoppedAnimation(ForjaColors.ember),
        minHeight: 8,
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    this.color = ForjaColors.ember,
    this.size = 40,
    this.iconSize = 20,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

class ProgressAreaFormScreen extends StatefulWidget {
  const ProgressAreaFormScreen({super.key, this.areaId});

  final String? areaId;

  @override
  State<ProgressAreaFormScreen> createState() => _ProgressAreaFormScreenState();
}

class _ProgressAreaFormScreenState extends State<ProgressAreaFormScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  bool _saving = false;

  bool get _isEditing => widget.areaId != null;

  @override
  void initState() {
    super.initState();
    final area = _initialArea();
    _titleController = TextEditingController(text: area?.title ?? '');
    _descriptionController = TextEditingController(
      text: area?.description ?? '',
    );
    _titleController.addListener(() => setState(() {}));
  }

  ProgressAreaEntity? _initialArea() {
    final areaId = widget.areaId;
    if (areaId == null) return null;
    return _findArea(context.read<ProgressBloc>().state.areas, areaId);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit({bool popOnSuccess = true}) async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _saving) return;

    setState(() => _saving = true);
    final description = _descriptionController.text.trim();
    final areaId = widget.areaId;

    if (areaId == null) {
      context.read<ProgressBloc>().add(
        ProgressAreaCreated(title: title, description: description),
      );
    } else {
      context.read<ProgressBloc>().add(
        ProgressAreaUpdated(id: areaId, title: title, description: description),
      );
    }

    if (popOnSuccess && mounted) {
      context.pop();
    } else {
      setState(() => _saving = false);
    }
  }

  bool _hasChanges() {
    final area = _initialArea();
    final initialTitle = area?.title ?? '';
    final initialDescription = area?.description ?? '';
    return _titleController.text.trim() != initialTitle ||
        _descriptionController.text.trim() != initialDescription;
  }

  Future<bool?> _showDiscardDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ForjaColors.surface,
        title: const Text('Descartar alterações?'),
        content: const Text(
          'Você tem alterações não salvas nesta área. Deseja realmente sair?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: ForjaColors.error),
            child: const Text('Sair sem salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final areas = context.watch<ProgressBloc>().state.areas;
    final area = widget.areaId == null
        ? null
        : _findArea(areas, widget.areaId!);
    final canSave = _titleController.text.trim().isNotEmpty && !_saving;

    if (_isEditing && area == null) {
      return const Scaffold(
        appBar: _SimpleFormAppBar(title: 'Editar área'),
        body: _MissingAreaState(),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (!_hasChanges()) {
          Navigator.of(context).pop();
          return;
        }

        final bool shouldPop = await _showDiscardDialog() ?? false;
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: _SimpleFormAppBar(
          title: _isEditing ? 'Editar área' : 'Nova área',
        ),
        body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FormHeader(
                    icon: Icons.track_changes_rounded,
                    title: 'Área',
                    subtitle:
                        'Exemplo: Curso PC/PA, academia, sono, alimentação.',
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nome da área',
                      hintText: 'Curso PC/PA, Academia, Sono',
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _descriptionController,
                    minLines: 4,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Objetivo, rotina, prazo ou contexto',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: canSave ? _submit : null,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'SALVANDO...' : 'SALVAR ÁREA'),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class ProgressMetricFormScreen extends StatefulWidget {
  const ProgressMetricFormScreen({
    super.key,
    required this.areaId,
    this.metricId,
  });

  final String areaId;
  final String? metricId;

  @override
  State<ProgressMetricFormScreen> createState() =>
      _ProgressMetricFormScreenState();
}


class _ProgressMetricFormScreenState extends State<ProgressMetricFormScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _noteController;
  late double _percent;
  final List<MetricDetailEntity> _details = [];
  bool _saving = false;

  bool get _isEditing => widget.metricId != null;

  @override
  void initState() {
    super.initState();
    final metric = _initialMetric();
    _titleController = TextEditingController(text: metric?.title ?? '');
    _descriptionController = TextEditingController(
      text: metric?.description ?? '',
    );
    _noteController = TextEditingController();
    _percent = (metric?.percent ?? 50).toDouble();

    if (metric != null) {
      _details.addAll(metric.details);
    }

    _titleController.addListener(() => setState(() {}));
  }

  ProgressMetricEntity? _initialMetric() {
    final metricId = widget.metricId;
    if (metricId == null) return null;

    final area = _findArea(
      context.read<ProgressBloc>().state.areas,
      widget.areaId,
    );
    return _findMetric(area?.metrics ?? const [], metricId);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit({bool popOnSuccess = true}) async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _saving) return;

    setState(() => _saving = true);
    final description = _descriptionController.text.trim();
    final note = _noteController.text.trim();
    final percent = _percent.round();
    final metricId = widget.metricId;

    if (metricId == null) {
      context.read<ProgressBloc>().add(
        ProgressMetricCreated(
          areaId: widget.areaId,
          title: title,
          percent: percent,
          description: description,
          note: note,
          details: List.from(_details),
        ),
      );
    } else {
      context.read<ProgressBloc>().add(
        ProgressMetricUpdated(
          areaId: widget.areaId,
          metricId: metricId,
          title: title,
          percent: percent,
          description: description,
          note: note,
          details: List.from(_details),
        ),
      );
    }

    if (popOnSuccess && mounted) {
      context.pop();
    } else {
      setState(() => _saving = false);
    }
  }

  bool _hasChanges() {
    final metric = _initialMetric();
    final initialTitle = metric?.title ?? '';
    final initialDescription = metric?.description ?? '';
    final initialPercent = (metric?.percent ?? 50).toDouble();
    final initialDetails = metric?.details ?? [];

    if (_titleController.text.trim() != initialTitle) return true;
    if (_descriptionController.text.trim() != initialDescription) return true;
    if (_percent != initialPercent) return true;
    if (_noteController.text.trim().isNotEmpty) return true;

    if (_details.length != initialDetails.length) return true;
    for (int i = 0; i < _details.length; i++) {
      final detail = _details[i];
      final initialDetail = initialDetails[i];
      if (detail.title != initialDetail.title ||
          detail.description != initialDetail.description ||
          detail.items.length != initialDetail.items.length) {
        return true;
      }
    }

    return false;
  }

  Future<bool?> _showDiscardDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ForjaColors.surface,
        title: const Text('Descartar alterações?'),
        content: const Text(
          'Você tem alterações não salvas neste indicador. Deseja realmente sair?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: ForjaColors.error),
            child: const Text('Sair sem salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _addOrEditDetail([MetricDetailEntity? detail, int? index]) async {
    final result = await Navigator.of(context).push<MetricDetailEntity>(
      MaterialPageRoute(
        builder: (_) => MetricDetailFormScreen(initialDetail: detail),
      ),
    );

    if (result != null) {
      setState(() {
        if (index != null) {
          _details[index] = result;
        } else {
          _details.add(result);
        }
      });

      if (_isEditing && mounted) {
        _submit(popOnSuccess: false);
      }
    }
  }

  Future<void> _removeDetail(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ForjaColors.surface,
        title: const Text('Remover tópico?'),
        content: Text('Deseja remover o tópico "${_details[index].title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: ForjaColors.error),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _details.removeAt(index));

      if (_isEditing && mounted) {
        _submit(popOnSuccess: false);
      }
    }
  }

  void _adjustPercent(int delta) {
    setState(() => _percent = (_percent + delta).clamp(0, 100).toDouble());
  }

  void _onReorderDetails(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final MetricDetailEntity item = _details.removeAt(oldIndex);
      _details.insert(newIndex, item);
    });

    if (_isEditing && mounted) {
      _submit(popOnSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final areas = context.watch<ProgressBloc>().state.areas;
    final area = _findArea(areas, widget.areaId);
    final metric = widget.metricId == null
        ? null
        : _findMetric(area?.metrics ?? const [], widget.metricId!);
    final canSave = _titleController.text.trim().isNotEmpty && !_saving;
    final percent = _percent.round();

    if (area == null) {
      return const Scaffold(
        appBar: _SimpleFormAppBar(title: 'Indicador'),
        body: _MissingAreaState(),
      );
    }

    if (_isEditing && metric == null) {
      return const Scaffold(
        appBar: _SimpleFormAppBar(title: 'Editar indicador'),
        body: Center(child: Text('Indicador não encontrado.')),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (!_hasChanges()) {
          Navigator.of(context).pop();
          return;
        }

        final bool shouldPop = await _showDiscardDialog() ?? false;
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: _SimpleFormAppBar(
          title: _isEditing ? 'Editar indicador' : 'Novo indicador',
        ),
        body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormHeader(
                    icon: Icons.speed_rounded,
                    title: area.title,
                    subtitle: 'Cadastre um indicador e seu nível atual.',
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Indicador',
                      hintText: 'Língua Portuguesa, Força, Sono profundo',
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _descriptionController,
                    minLines: 3,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'O que você quer medir nessa frente',
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Text('Nível atual', style: text.labelMedium),
                      const Spacer(),
                      Text(
                        '$percent%',
                        style: text.headlineSmall?.copyWith(
                          color: ForjaColors.ember,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _percent,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '$percent%',
                    activeColor: ForjaColors.ember,
                    inactiveColor: ForjaColors.divider,
                    onChanged: (value) => setState(() => _percent = value),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _adjustPercent(-5),
                          icon: const Icon(Icons.remove_rounded),
                          label: const Text('5%'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _adjustPercent(5),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('5%'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _noteController,
                    minLines: 3,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Observação da avaliação',
                      hintText:
                          'Ex: subi de 70% para 80% após revisar pontos fracos',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _IconBadge(icon: Icons.auto_stories_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tópicos de estudo',
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Adicione detalhes, conceitos e regras.',
                              style: text.bodySmall?.copyWith(
                                color: ForjaColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _addOrEditDetail(),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        color: ForjaColors.ember,
                      ),
                    ],
                  ),
                  if (_details.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _details.length,
                      onReorder: _onReorderDetails,
                      itemBuilder: (context, index) {
                        final detail = _details[index];
                        return Material(
                          key: ValueKey(detail.id),
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: ForjaColors.divider.withValues(alpha: 0.5),
                              ),
                            ),
                            onTap: () => _addOrEditDetail(detail, index),
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: ForjaColors.ember.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.bookmark_border_rounded,
                                color: ForjaColors.ember,
                                size: 20,
                              ),
                            ),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: ForjaColors.ember.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: ForjaColors.ember.withValues(alpha: 0.5),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    detail.type.label.toUpperCase(),
                                    style: const TextStyle(
                                      color: ForjaColors.ember,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    detail.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: detail.items.isNotEmpty
                                ? Text(
                                    '${detail.items.length} sub-itens cadastrados',
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (detail.items.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ForjaColors.ember,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      detail.items.length.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                IconButton(
                                  onPressed: () => _removeDetail(index),
                                  icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                    size: 20,
                                  ),
                                  color: ForjaColors.error,
                                ),
                                const Icon(
                                  Icons.drag_indicator_rounded,
                                  color: ForjaColors.textSecondary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: canSave ? _submit : null,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'SALVANDO...' : 'SALVAR INDICADOR'),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _SimpleFormAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _SimpleFormAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconBadge(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: text.bodySmall?.copyWith(
                  color: ForjaColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

ProgressAreaEntity? _findArea(List<ProgressAreaEntity> areas, String id) {
  for (final area in areas) {
    if (area.id == id) return area;
  }
  return null;
}

ProgressMetricEntity? _findMetric(
  List<ProgressMetricEntity> metrics,
  String id,
) {
  for (final metric in metrics) {
    if (metric.id == id) return metric;
  }
  return null;
}
