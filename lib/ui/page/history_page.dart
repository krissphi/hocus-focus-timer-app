import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timtam/data/model/session.dart';
import 'package:timtam/ui/widget/history/history_item_card.dart';
import 'package:timtam/ui/widget/history/weekly_chart.card.dart';

import '../../state/view_providers.dart';
import '../utils/history_utils.dart';
import '../utils/type_device_utils.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  HistoryFilter _selectedFilter = HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(appIsLoadingProvider);
    final historyData = ref.watch(historyPageDataProvider(_selectedFilter));

    final isDesktop = TypeDeviceUtils.isDesktop(context);
    final padding = isDesktop
        ? const EdgeInsets.symmetric(horizontal: 180.0, vertical: 16.0)
        : const EdgeInsets.all(12.0);

    final historyRows = <_HistoryListRow>[];
    for (final date in historyData.orderedDates) {
      historyRows.add(_HistoryListRow.header(date));
      final sessionsForDate = historyData.groupedSessions[date]!;
      for (final session in sessionsForDate) {
        historyRows.add(_HistoryListRow.item(session));
      }
    }

    const topSectionCount = 2;
    const footerCount = 0;
    final hasNoData = historyRows.isEmpty;
    final listItemCount =
        topSectionCount + (hasNoData ? 1 : historyRows.length) + footerCount;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: padding,
              itemCount: listItemCount,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Weekly Overview',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Productivity stats for ${historyData.weekRangeLabel}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'TOTAL FOCUS',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${historyData.totalWeekHours.toStringAsFixed(1)}h',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      WeeklyChartCard(
                        secondsByDay: historyData.weekSecondsByDay,
                      ),
                      const SizedBox(height: 28),
                    ],
                  );
                }

                if (index == 1) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'History',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          PopupMenuButton<HistoryFilter>(
                            tooltip: 'Filter',
                            onSelected: (value) {
                              setState(() {
                                _selectedFilter = value;
                              });
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: HistoryFilter.all,
                                child: Text('All'),
                              ),
                              const PopupMenuItem(
                                value: HistoryFilter.today,
                                child: Text('Today'),
                              ),
                              const PopupMenuItem(
                                value: HistoryFilter.thisWeek,
                                child: Text('This Week'),
                              ),
                            ],
                            child: Row(
                              children: [
                                Icon(
                                  Icons.tune,
                                  size: 16,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  HistoryUtils.filterLabel(_selectedFilter),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                  );
                }

                final firstContentIndex = 2;
                if (hasNoData && index == firstContentIndex) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No history data',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                }

                final rowIndex = index - firstContentIndex;
                final row = historyRows[rowIndex];

                if (row.isHeader) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      HistoryUtils.dateSectionLabel(row.date!, historyData.now),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 0.8,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }

                final session = row.session!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: HistoryItemCard(
                    session: session,
                    task: historyData.tasksById[session.taskId],
                    focusSeconds:
                        historyData.segmentSecondsBySessionId[session.id] ??
                        session.endAt!.difference(session.startAt).inSeconds,
                  ),
                );
              },
            ),
    );
  }
}

class _HistoryListRow {
  const _HistoryListRow.header(this.date) : session = null;
  const _HistoryListRow.item(this.session) : date = null;

  final DateTime? date;
  final Session? session;

  bool get isHeader => date != null;
}
