import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../data/providers/providers.dart';
import 'weekly_report_model.dart';

class WeeklyReportScreen extends ConsumerWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(weeklyReportProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios Semanais')),
      body: reports.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: ForjaColors.textSecondary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum relatório gerado ainda.\nAguarde até o próximo domingo.',
                    textAlign: TextAlign.center,
                    style: text.bodyLarge?.copyWith(color: ForjaColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final report = reports[index];
                return _ReportCard(report: report);
              },
            ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final dateStr = DateFormat('dd/MM/yyyy').format(report.date);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ForjaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ForjaColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Semana de $dateStr',
                style: text.titleMedium?.copyWith(color: ForjaColors.ember, fontWeight: FontWeight.bold),
              ),
              if (report.cleanDaysCount == 7)
                const Icon(Icons.verified_rounded, color: ForjaColors.ember),
            ],
          ),
          const SizedBox(height: 16),
          _StatRow(
            icon: Icons.calendar_today_rounded,
            label: 'Dias limpos:',
            value: '${report.cleanDaysCount}/7',
          ),
          _StatRow(
            icon: Icons.checklist_rounded,
            label: 'Missões concluídas:',
            value: '${report.totalMissionsCompleted}',
          ),
          _StatRow(
            icon: Icons.military_tech_rounded,
            label: 'Desafio semanal:',
            value: report.challengeCompleted ? 'Concluído' : 'Não concluído',
          ),
          _StatRow(
            icon: Icons.security_rounded,
            label: 'Modo Monge:',
            value: report.monkModeActive ? 'Ativo' : 'Inativo',
          ),
          if (report.journalEntries.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'REFLEXÕES DA SEMANA',
              style: text.labelSmall?.copyWith(color: ForjaColors.textSecondary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...report.journalEntries.take(3).map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${entry.length > 60 ? "${entry.substring(0, 60)}..." : entry}',
                    style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                  ),
                )),
          ],
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ForjaColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ForjaColors.divider),
            ),
            child: Text(
              report.closingMessage,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: ForjaColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: ForjaColors.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: text.bodyMedium),
          const Spacer(),
          Text(value, style: text.bodyMedium?.copyWith(color: ForjaColors.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
