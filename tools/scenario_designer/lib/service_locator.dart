import 'package:get_it/get_it.dart';
import 'services/local_file_service.dart';
import 'utils/app_theme.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<LocalFileService>(() => LocalFileService());
  getIt.registerLazySingleton<AppThemeProvider>(() => AppThemeProvider());
}
