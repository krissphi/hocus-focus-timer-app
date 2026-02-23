import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'data/adapter/hive_registrar.g.dart';
import 'data/model/session.dart';
import 'data/model/task.dart';
import 'data/model/time_segment.dart';
import 'data/repository/task_repository.dart';
import 'data/repository/task_session_repository.dart';
import 'data/repository/time_segment_repository.dart';
import 'state/entity_providers.dart';
import 'ui/page/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  final docDir = await getApplicationDocumentsDirectory();
  final hiveDir = Directory('${docDir.path}/Hocusfocus/hive');
  if (!await hiveDir.exists()) {
    await hiveDir.create(recursive: true);
  }

  Hive.init(hiveDir.path);
  Hive.registerAdapters();
  Box<Task> taskBox;
  Box<Session> sessionBox;
  Box<TimeSegment> segmentBox;
  taskBox = await Hive.openBox<Task>(TaskRepository.boxName);
  sessionBox = await Hive.openBox<Session>(TaskSessionRepository.boxName);
  segmentBox = await Hive.openBox<TimeSegment>(TimeSegmentRepository.boxName);

  final repository = TaskRepository(taskBox);
  final sessionRepository = TaskSessionRepository(sessionBox);
  final segmentRepository = TimeSegmentRepository(segmentBox);

  runApp(
    ProviderScope(
      overrides: [
        taskRepositoryProvider.overrideWithValue(repository),
        taskSessionRepositoryProvider.overrideWithValue(sessionRepository),
        timeSegmentRepositoryProvider.overrideWithValue(segmentRepository),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E6F5D),
      brightness: Brightness.light,
      surface: const Color(0xFFF7F4EE),
    );

    final textTheme = GoogleFonts.spaceGroteskTextTheme().copyWith(
      titleLarge: GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      bodyMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        textTheme: textTheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F4EE),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withAlpha(235),
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: Color(0xFFE9E4DA)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
        ),
      ),
      home: const HomePage(),
    );
  }
}
