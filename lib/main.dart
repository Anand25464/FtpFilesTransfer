import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'blocs/ftp_connection/ftp_connection_bloc.dart';
import 'blocs/file_browser/file_browser_bloc.dart';
import 'blocs/file_transfer/file_transfer_bloc.dart';
import 'screens/server_connection_screen.dart';
import 'screens/file_browser_screen.dart';
import 'screens/file_transfer_screen.dart';
import 'services/ftp_service.dart';
import 'theme/app_theme.dart';
GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    // Services
    final ftpService = FtpService();
    final connectivity = Connectivity();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<FtpService>(
          create: (context) => ftpService,
        ),
        RepositoryProvider<Connectivity>(
          create: (context) => connectivity,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<FtpConnectionBloc>(
            create: (context) => FtpConnectionBloc(
              ftpService: ftpService,
              connectivity: connectivity,
            ),
          ),
          BlocProvider<FileBrowserBloc>(
            create: (context) => FileBrowserBloc(
              ftpService: ftpService,
            ),
          ),
          BlocProvider<FileTransferBloc>(
            create: (context) => FileTransferBloc(
              ftpService: ftpService,
            ),
          ),
        ],
        child: MaterialApp(
          title: 'FTP Client',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          initialRoute: '/connection',
          navigatorKey: navigatorKey,
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/connection':
                return MaterialPageRoute(
                  builder: (_) => const ServerConnectionScreen(),
                );
              case '/file_browser':
                return MaterialPageRoute(
                  builder: (_) => const FileBrowserScreen(),
                );
              case '/transfer':
                final args = settings.arguments as Map<String, dynamic>?;
                if (args != null) {
                  return MaterialPageRoute(
                    builder: (_) => FileTransferScreen(transferParams: args),
                  );
                }
                return _errorRoute();
              default:
                return _errorRoute();
            }
          },
        ),
      ),
    );
  }

  Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Error'),
          ),
          body: const Center(
            child: Text('Route not found!'),
          ),
        );
      },
    );
  }
}