


import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ftp_file_transfer/blocs/file_browser/file_browser_bloc.dart';
import 'package:ftp_file_transfer/blocs/file_transfer/file_transfer_bloc.dart';
import 'package:ftp_file_transfer/blocs/ftp_connection/ftp_connection_bloc.dart';
import 'package:ftp_file_transfer/services/ftp_service.dart';
import 'package:get_it/get_it.dart';

class Injector {
  Injector._();

  static void init() {
    // Repositories

    GetIt.I.registerLazySingleton(()=>FtpService());
    GetIt.I.registerLazySingleton(()=>Connectivity());
    GetIt.I.registerLazySingleton(()=>FileBrowserBloc());

    GetIt.I.registerLazySingleton(() {
      return FileTransferBloc();
    });

    GetIt.I.registerLazySingleton(() {
      return FtpConnectionBloc(connectivity: GetIt.I());
    });


  }
}