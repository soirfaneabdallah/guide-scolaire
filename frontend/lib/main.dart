// frontend/lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/chat/presentation/providers/chat_provider.dart';
import 'features/chat/repositories/chat_repository.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'core/network/api_client.dart';
import 'core/routing/app_router.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AuthProvider authProvider;
  late ApiClient apiClient;

  @override
  void initState() {
    super.initState();

    authProvider = AuthProvider();
    apiClient = ApiClient(authProvider: authProvider);
    authProvider.setApiClient(apiClient);
    authProvider.init();
  }

  @override
  void dispose() {
    authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider(
          create: (context) => DashboardProvider(apiClient: apiClient),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, DashboardProvider, ChatProvider>(
          create: (context) {
            final auth = context.read<AuthProvider>();
            final dashboard = context.read<DashboardProvider>();
            final api = context.read<ApiClient>();
            final subject = dashboard.selectedSubject;
            
            return ChatProvider(
              chatRepository: ChatRepository(apiClient: api),
              authProvider: auth,
              subjectId: subject?.id ?? 1,  // 👈 Utiliser l'ID (1 = Mathématiques par défaut)
            );
          },
          update: (context, auth, dashboard, previous) {
            final subject = dashboard.selectedSubject;
            final api = context.read<ApiClient>();
            final newSubjectId = subject?.id ?? 1;
            
            if (previous != null && previous.subjectId != newSubjectId) {
              return ChatProvider(
                chatRepository: ChatRepository(apiClient: api),
                authProvider: auth,
                subjectId: newSubjectId,
              );
            }
            
            return previous ?? ChatProvider(
              chatRepository: ChatRepository(apiClient: api),
              authProvider: auth,
              subjectId: newSubjectId,
            );
          },
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isInitialized) {
            return const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Chargement...'),
                    ],
                  ),
                ),
              ),
            );
          }

          return MaterialApp(
            title: 'E-learningAI',
            theme: ThemeData(
              primarySwatch: Colors.green,
              useMaterial3: true,
              fontFamily: 'Poppins',
              scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            ),
            home: HomeScreen(),
            onGenerateRoute: AppRouter.generateRoute,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}