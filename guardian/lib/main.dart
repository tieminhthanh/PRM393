import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// sqflite ffi for desktop platforms
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:guardian/app.dart';

// Import Database
import 'package:guardian/core/database/database_helper.dart';

import 'package:guardian/features/admin/data/datasource/admin_local_datasource.dart';

// Import Product Feature
import 'package:guardian/features/product/data/datasource/product_local_datasource.dart';
import 'package:guardian/features/product/data/repositories/product_repository_impl.dart';
import 'package:guardian/features/product/presentation/bloc/product_bloc.dart';
import 'package:guardian/features/product/presentation/bloc/product_event.dart';

void main() async {
  // Đảm bảo Flutter binding được khởi tạo trước khi gọi native code (SQLite)
  WidgetsFlutterBinding.ensureInitialized();

  // If running on desktop (Windows/macOS/Linux) we need to initialize
  // the ffi implementation of sqflite. This avoids the "databaseFactory
  // not initialized" error when using sqflite_common_ffi.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // 1. Khởi tạo Database Services
  final dbProvider = DatabaseProvider(config: databaseConfig);
  final dbService = DatabaseService(dbProvider);
  final domainQueries = DomainQueries(dbService);
  final adminLocalDS = AdminLocalDataSourceImpl(dbService);

  // 2. Khởi tạo Data Sources & Repositories cho Product
  final productLocalDS = ProductLocalDataSourceImpl(dbService, domainQueries);
  final productRepo = ProductRepositoryImpl(productLocalDS);

  // 3. Chạy App kèm MultiBlocProvider
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<ProductBloc>(
          // Khởi tạo Bloc và gọi Event LoadProducts ngay khi app mở
          create: (context) => ProductBloc(repository: productRepo)..add(LoadProducts()),
        ),
      ],
      child: GuardianApp(adminLocalDataSource: adminLocalDS),
    ),
  );
}
