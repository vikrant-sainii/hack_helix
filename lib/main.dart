import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/isl/isl_bloc.dart';
import 'repositories/isl_repository.dart';
import 'screens/isl_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HackHelixApp());
}

class HackHelixApp extends StatelessWidget {
  const HackHelixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<IslRepository>(
          create: (_) => IslRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<IslBloc>(
            create: (context) => IslBloc(
              repository: context.read<IslRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'ISL Sign Language',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6C63FF),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0A0E1A),
            fontFamily: 'Roboto',
          ),
          home: const IslScreen(),
        ),
      ),
    );
  }
}
