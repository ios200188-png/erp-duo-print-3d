import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/product_asset.dart';

final productAssetsRepositoryProvider = Provider<ProductAssetsRepository>((
  ref,
) {
  return ProductAssetsRepository(ref.watch(appDatabaseProvider));
});

final productImagesProvider = FutureProvider.family<List<ProductImage>, int>((
  ref,
  id,
) {
  return ref.watch(productAssetsRepositoryProvider).images(id);
});
final productFilesProvider = FutureProvider.family<List<ProductFile>, int>((
  ref,
  id,
) {
  return ref.watch(productAssetsRepositoryProvider).files(id);
});
final productVersionsProvider =
    FutureProvider.family<List<ProductVersion>, int>((ref, id) {
      return ref.watch(productAssetsRepositoryProvider).versions(id);
    });

class ProductAssetsRepository {
  ProductAssetsRepository(this._database);
  final AppDatabase _database;

  Future<List<ProductImage>> images(int productId) async {
    final rows = await _database
        .customSelect(
          'SELECT id,product_id,file_path,caption,is_primary,created_at FROM product_images WHERE product_id=? ORDER BY is_primary DESC,created_at DESC',
          variables: [Variable<int>(productId)],
          readsFrom: const {},
        )
        .get();
    return rows.map((r) => ProductImage.fromMap(r.data)).toList();
  }

  Future<void> addImage({
    required int productId,
    required String filePath,
    required String caption,
    required bool primary,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.transaction(() async {
      if (primary) {
        await _database.customStatement(
          'UPDATE product_images SET is_primary=0 WHERE product_id=?',
          [productId],
        );
      }
      await _database.customStatement(
        'INSERT INTO product_images(product_id,file_path,caption,is_primary,created_at) VALUES(?,?,?,?,?)',
        [productId, filePath, caption, primary ? 1 : 0, now],
      );
    });
  }

  Future<void> setPrimary(int productId, int imageId) async {
    await _database.transaction(() async {
      await _database.customStatement(
        'UPDATE product_images SET is_primary=0 WHERE product_id=?',
        [productId],
      );
      await _database.customStatement(
        'UPDATE product_images SET is_primary=1 WHERE id=?',
        [imageId],
      );
    });
  }

  Future<void> deleteImage(int id) =>
      _database.customStatement('DELETE FROM product_images WHERE id=?', [id]);

  Future<List<ProductFile>> files(int productId) async {
    final rows = await _database
        .customSelect(
          'SELECT id,product_id,file_type,file_name,file_path,version,notes,created_at FROM product_files WHERE product_id=? ORDER BY created_at DESC',
          variables: [Variable<int>(productId)],
          readsFrom: const {},
        )
        .get();
    return rows.map((r) => ProductFile.fromMap(r.data)).toList();
  }

  Future<void> addFile({
    required int productId,
    required String type,
    required String name,
    required String path,
    required String version,
    required String notes,
  }) async {
    await _database.customStatement(
      'INSERT INTO product_files(product_id,file_type,file_name,file_path,version,notes,created_at) VALUES(?,?,?,?,?,?,?)',
      [
        productId,
        type,
        name,
        path,
        version,
        notes,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
  }

  Future<void> deleteFile(int id) =>
      _database.customStatement('DELETE FROM product_files WHERE id=?', [id]);

  Future<List<ProductVersion>> versions(int productId) async {
    final rows = await _database
        .customSelect(
          'SELECT id,product_id,version,description,weight,print_minutes,created_at FROM product_versions WHERE product_id=? ORDER BY created_at DESC',
          variables: [Variable<int>(productId)],
          readsFrom: const {},
        )
        .get();
    return rows.map((r) => ProductVersion.fromMap(r.data)).toList();
  }

  Future<void> addVersion({
    required int productId,
    required String version,
    required String description,
    required double weight,
    required int printMinutes,
  }) async {
    await _database.customStatement(
      'INSERT INTO product_versions(product_id,version,description,weight,print_minutes,created_at) VALUES(?,?,?,?,?,?)',
      [
        productId,
        version,
        description,
        weight,
        printMinutes,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
  }

  Future<void> deleteVersion(int id) => _database.customStatement(
    'DELETE FROM product_versions WHERE id=?',
    [id],
  );
}
