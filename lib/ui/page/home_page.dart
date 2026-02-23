import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timtam/ui/widget/home/stats_card.dart';

import '../../data/model/task.dart';
import '../../state/entity_providers.dart';
import '../../state/task_timer_provider.dart';
import '../../state/view_providers.dart';
import '../utils/date_time_utils.dart';
import '../utils/type_device_utils.dart';
import '../widget/home/day_timeline.dart';
import '../widget/home/task_list.dart';
import 'history_page.dart';
import 'task_form.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionNotifierProvider);
    final segmentState = ref.watch(segmentNotifierProvider);
    final taskController = ref.read(taskNotifierProvider.notifier);
    final timerController = ref.read(taskTimerControllerProvider);
    final now = DateTime.now();
    final today = AppDateUtils.dateOnly(now);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      timerController.ensureNormalized(now: now);
    });

    final sessions = sessionState.items;
    final segments = segmentState.items;
    final isLoading = ref.watch(appIsLoadingProvider);

    final tasksForToday = ref.watch(tasksForDayProvider(today));
    final taskListData = ref.watch(taskListDataProvider(today));
    final dailyStats = ref.watch(homeDailyStatsProvider(today));
    final totalFocusLabel = TimeFormatUtils.formatSeconds(
      dailyStats.totalFocusSeconds,
    );

    final isDesktop = TypeDeviceUtils.isDesktop(context);

    void notifyTargetReached(Task task) {
      SystemSound.play(SystemSoundType.alert);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${task.title} sudah mencapai 100% 🎉'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
    }

    final title = isDesktop
        ? const Text('Hocus Focus - Stay In Locus')
        : const Text('Hocus Focus');

    final padding = isDesktop
        ? const EdgeInsets.symmetric(horizontal: 180.0, vertical: 16.0)
        : const EdgeInsets.all(12.0);

    void handleTaskFormResult(Task? result, Task? initialTask) {
      if (result == null) {
        return;
      }
      if (initialTask == null) {
        taskController.addTask(result);
      } else {
        taskController.updateTask(result);
      }
    }

    void showDialogForm(Task? task) {
      showDialog<Task>(
        context: context,
        builder: (_) => TaskFormDialog(initialTask: task),
      ).then((result) => handleTaskFormResult(result, task));
    }

    void showBottomSheetForm(Task? task) {
      showModalBottomSheet<Task>(
        context: context,
        isScrollControlled: true,
        builder: (_) => TaskFormDialog(initialTask: task),
      ).then((result) => handleTaskFormResult(result, task));
    }

    return Scaffold(
      appBar: AppBar(
        title: title,

        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const HistoryPage()));
            },
            icon: const Icon(Icons.history),
            tooltip: 'History',
          ),
          Padding(
            padding: isDesktop
                ? const EdgeInsets.only(right: 90.0)
                : EdgeInsets.zero,
            child: isDesktop
                ? _desktopButton(() => showDialogForm(null))
                : _mobileButton(() => showBottomSheetForm(null)),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: padding,
              child: Column(
                children: [
                  DayTimeline(
                    tasks: tasksForToday,
                    sessions: sessions,
                    segments: segments,
                    day: today,
                    isDesktop: isDesktop,
                  ),
                  SizedBox(height: isDesktop ? 16 : 8),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Total Focus Time',
                          value: totalFocusLabel,
                        ),
                      ),
                      if (isDesktop) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: StatCard(
                            label: 'Completed Task',
                            value: '${dailyStats.completedTaskCount}',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: StatCard(
                            label: 'Remaining Task',
                            value: '${dailyStats.remainingTaskCount}',
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: isDesktop ? 16 : 8),
                  Expanded(
                    child: TaskList(
                      data: taskListData,
                      day: today,
                      isDesktop: isDesktop,
                      onStart: timerController.startTask,
                      onPause: timerController.pauseTask,
                      onResume: timerController.resumeTask,
                      onStop: timerController.completeTask,
                      onDelete: taskController.deleteTask,
                      onEdit: (task) {
                        if (isDesktop) {
                          showDialogForm(task);
                        } else {
                          showBottomSheetForm(task);
                        }
                      },
                      onTargetReached: notifyTargetReached,
                      onReset: (taskId) =>
                          timerController.clearCompletion(taskId, today),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _desktopButton(VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_circle_outline),
      label: const Text('Add Task'),
    );
  }

  Widget _mobileButton(VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.add_circle_outline),
      tooltip: 'Add Task',
    );
  }
}
