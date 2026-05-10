import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bengkel_v3.db'); // Update versi DB
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Tabel Stok
    await db.execute('''
      CREATE TABLE stok (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        harga INTEGER NOT NULL,
        gambar TEXT
      )
    ''');

    // Tabel Transaksi Baru
    await db.execute('''
      CREATE TABLE transaksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deskripsi TEXT NOT NULL,
        biaya_jasa INTEGER NOT NULL DEFAULT 0,
        total_barang INTEGER NOT NULL,
        grand_total INTEGER NOT NULL,
        tanggal TEXT NOT NULL
      )
    ''');
  }

  // --- FUNGSI STOK (Sama seperti sebelumnya) ---
  Future<List<Map<String, dynamic>>> cariBarang(String keyword) async {
    final db = await instance.database;
    return await db.query(
      'stok',
      where: 'nama LIKE ?',
      whereArgs: ['%$keyword%'],
    );
  }

  Future<int> tambahBarang(String nama, int harga, {String? gambar}) async {
    final db = await instance.database;
    return await db.insert('stok', {
      'nama': nama,
      'harga': harga,
      'gambar': gambar,
    });
  }

  Future<int> updateBarang(
    int id,
    String nama,
    int harga, {
    String? gambar,
  }) async {
    final db = await instance.database;
    return await db.update(
      'stok',
      {'nama': nama, 'harga': harga, 'gambar': gambar},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> hapusBarang(int id) async {
    final db = await instance.database;
    return await db.delete('stok', where: 'id = ?', whereArgs: [id]);
  }

  // --- FUNGSI TRANSAKSI BARU ---
  Future<int> catatTransaksi(
    String deskripsi,
    int biayaJasa,
    int totalBarang,
  ) async {
    final db = await instance.database;
    int grandTotal = totalBarang + biayaJasa;
    return await db.insert('transaksi', {
      'deskripsi': deskripsi,
      'biaya_jasa': biayaJasa,
      'total_barang': totalBarang,
      'grand_total': grandTotal,
      'tanggal': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getTransaksi({
    String? startDate,
    String? endDate,
  }) async {
    final db = await instance.database;
    if (startDate != null && endDate != null) {
      return await db.query(
        'transaksi',
        where: "tanggal BETWEEN ? AND ?",
        whereArgs: ["$startDate", "${endDate}T23:59:59"],
        orderBy: "tanggal DESC",
      );
    }
    return await db.query('transaksi', orderBy: "tanggal DESC");
  }

  Future<int> updateTransaksi(
    int id,
    String deskripsi,
    int biayaJasa,
    int totalBarang,
  ) async {
    final db = await instance.database;
    int grandTotal = biayaJasa + totalBarang;
    return await db.update(
      'transaksi',
      {
        'deskripsi': deskripsi,
        'biaya_jasa': biayaJasa,
        'total_barang': totalBarang,
        'grand_total': grandTotal,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> hapusTransaksi(int id) async {
    final db = await instance.database;
    return await db.delete('transaksi', where: 'id = ?', whereArgs: [id]);
  }
}
