// frontend/lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/chat/presentation/providers/chat_provider.dart';
import 'features/chat/repositories/chat_repository.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'core/network/api_client.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';

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
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (context) {
            return ChatProvider(
              chatRepository: ChatRepository(apiClient: apiClient),
              authProvider: authProvider,
            );
          },
          update: (context, auth, previous) {
            return previous ?? ChatProvider(
              chatRepository: ChatRepository(apiClient: apiClient),
              authProvider: auth,
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
                      Text(
                        'Chargement...',
                        style: TextStyle(
                          color: Color(0xFF1E2937),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return MaterialApp(
            title: 'Guide Scolaire Comores',
            theme: ThemeData(
              primarySwatch: Colors.green,
              useMaterial3: true,
              fontFamily: 'Poppins',
              scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            ),
            // 🔥 CORRECTION : Enlever le const
            home: HomeScreen(),  // 👈 Plus de const
            onGenerateRoute: AppRouter.generateRoute,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}