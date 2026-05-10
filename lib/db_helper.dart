import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bengkel_v9.db'); // Nama file DB diperbarui
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        // WAJIB: Agar fitur hapus berantai (CASCADE) berfungsi
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. Tabel Stok
    await db.execute('''
      CREATE TABLE stok (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        harga INTEGER NOT NULL,
        gambar TEXT
      )
    ''');

    // 2. Tabel Transaksi Penjualan (Induk Kasir)
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

    // 3. Tabel Detail Barang Transaksi (BARU - Pemisah per item Penjualan)
    await db.execute('''
      CREATE TABLE detail_transaksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaksi_id INTEGER NOT NULL,
        nama_barang TEXT NOT NULL,
        qty INTEGER NOT NULL DEFAULT 1,
        harga_satuan INTEGER NOT NULL,
        subtotal INTEGER NOT NULL,
        FOREIGN KEY (transaksi_id) REFERENCES transaksi(id) ON DELETE CASCADE
      )
    ''');

    // 4. Tabel Detail Jasa Penjualan
    await db.execute('''
      CREATE TABLE jasa_transaksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaksi_id INTEGER NOT NULL,
        nama_jasa TEXT NOT NULL,
        biaya INTEGER NOT NULL,
        FOREIGN KEY (transaksi_id) REFERENCES transaksi(id) ON DELETE CASCADE
      )
    ''');

    // 5. Tabel Induk Belanja (Nota Pembelian)
    await db.execute('''
      CREATE TABLE belanja (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_belanja INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        keterangan TEXT
      )
    ''');

    // 6. Tabel Detail Item Belanja (Pemisah per item Pembelian)
    await db.execute('''
      CREATE TABLE detail_belanja (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        belanja_id INTEGER NOT NULL,
        nama_barang TEXT NOT NULL,
        qty INTEGER NOT NULL,
        harga_satuan INTEGER NOT NULL,
        subtotal INTEGER NOT NULL,
        FOREIGN KEY (belanja_id) REFERENCES belanja(id) ON DELETE CASCADE
      )
    ''');
  }

  // --- FUNGSI STOK ---
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

  // --- FUNGSI TRANSAKSI PENJUALAN ---
  Future<int> catatTransaksi(
    String deskripsi,
    int biayaJasa,
    int totalBarang,
  ) async {
    final db = await instance.database;
    return await db.insert('transaksi', {
      'deskripsi': deskripsi, // Sekarang difungsikan sebagai catatan opsional
      'biaya_jasa': biayaJasa,
      'total_barang': totalBarang,
      'grand_total': totalBarang + biayaJasa,
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
        whereArgs: [startDate, "${endDate}T23:59:59"],
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
    return await db.update(
      'transaksi',
      {
        'deskripsi': deskripsi,
        'biaya_jasa': biayaJasa,
        'total_barang': totalBarang,
        'grand_total': totalBarang + biayaJasa,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> hapusTransaksi(int id) async {
    final db = await instance.database;
    return await db.delete('transaksi', where: 'id = ?', whereArgs: [id]);
  }

  // --- FUNGSI DETAIL BARANG TRANSAKSI ---
  Future<void> tambahDetailTransaksi(
    int transaksiId,
    List<Map<String, dynamic>> items,
  ) async {
    final db = await instance.database;
    for (var item in items) {
      await db.insert('detail_transaksi', {
        'transaksi_id': transaksiId,
        'nama_barang': item['nama_barang'].toString(),
        'qty': (item['qty'] as num).toInt(),
        'harga_satuan': (item['harga'] as num).toInt(),
        'subtotal': ((item['qty'] as num) * (item['harga'] as num)).toInt(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getDetailTransaksi(int transaksiId) async {
    final db = await instance.database;
    return await db.query(
      'detail_transaksi',
      where: 'transaksi_id = ?',
      whereArgs: [transaksiId],
      orderBy: 'id ASC',
    );
  }

  Future<int> hapusSemuaDetailTransaksi(int transaksiId) async {
    final db = await instance.database;
    return await db.delete(
      'detail_transaksi',
      where: 'transaksi_id = ?',
      whereArgs: [transaksiId],
    );
  }

  // --- FUNGSI JASA TRANSAKSI ---
  Future<void> tambahJasaTransaksi(
    int transaksiId,
    List<Map<String, dynamic>> listJasa,
  ) async {
    final db = await instance.database;
    for (final jasa in listJasa) {
      await db.insert('jasa_transaksi', {
        'transaksi_id': transaksiId,
        'nama_jasa': jasa['nama_jasa'].toString(),
        'biaya': (jasa['biaya'] as num).toInt(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getJasaByTransaksi(int transaksiId) async {
    final db = await instance.database;
    return await db.query(
      'jasa_transaksi',
      where: 'transaksi_id = ?',
      whereArgs: [transaksiId],
      orderBy: 'id ASC',
    );
  }

  Future<int> hapusSemuaJasaTransaksi(int transaksiId) async {
    final db = await instance.database;
    return await db.delete(
      'jasa_transaksi',
      where: 'transaksi_id = ?',
      whereArgs: [transaksiId],
    );
  }

  // --- FUNGSI BELANJA ---
  Future<int> catatBelanjaInduk(
    int totalBelanja,
    String tanggal, {
    String? keterangan,
  }) async {
    final db = await instance.database;
    return await db.insert('belanja', {
      'total_belanja': totalBelanja,
      'tanggal': tanggal,
      'keterangan': keterangan ?? "",
    });
  }

  Future<int> updateBelanja(
    int id,
    int totalBelanja,
    String tanggal,
    String keterangan,
  ) async {
    final db = await instance.database;
    return await db.update(
      'belanja',
      {
        'total_belanja': totalBelanja,
        'tanggal': tanggal,
        'keterangan': keterangan,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> tambahDetailBelanja(
    int belanjaId,
    List<Map<String, dynamic>> items,
  ) async {
    final db = await instance.database;
    for (var item in items) {
      await db.insert('detail_belanja', {
        'belanja_id': belanjaId,
        'nama_barang': item['nama'].toString(),
        'qty': (item['qty'] as num).toInt(),
        'harga_satuan': (item['harga'] as num).toInt(),
        'subtotal': ((item['qty'] as num) * (item['harga'] as num)).toInt(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getBelanja({
    String? startDate,
    String? endDate,
  }) async {
    final db = await instance.database;
    if (startDate != null && endDate != null) {
      return await db.query(
        'belanja',
        where: "tanggal BETWEEN ? AND ?",
        whereArgs: [startDate, "${endDate}T23:59:59"],
        orderBy: "tanggal DESC",
      );
    }
    return await db.query('belanja', orderBy: "tanggal DESC");
  }

  Future<List<Map<String, dynamic>>> getDetailBelanja(int belanjaId) async {
    final db = await instance.database;
    return await db.query(
      'detail_belanja',
      where: 'belanja_id = ?',
      whereArgs: [belanjaId],
    );
  }

  Future<int> hapusSemuaDetailBelanja(int belanjaId) async {
    final db = await instance.database;
    return await db.delete(
      'detail_belanja',
      where: 'belanja_id = ?',
      whereArgs: [belanjaId],
    );
  }

  Future<int> hapusBelanja(int id) async {
    final db = await instance.database;
    return await db.delete('belanja', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // --- FUNGSI STATISTIK UNTUK DASHBOARD ---
  // ==========================================

  // 1. Total jumlah barang yang dijual (keseluruhan)
  Future<int> getTotalBarangTerjual() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(qty) as total FROM detail_transaksi',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  // 2. Jumlah transaksi bulan ini
  Future<int> getJumlahTransaksiBulanIni() async {
    final db = await instance.database;
    String currentMonth = DateTime.now().toIso8601String().substring(
      0,
      7,
    ); // Format: YYYY-MM
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM transaksi WHERE tanggal LIKE ?',
      ['$currentMonth%'],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  // 3. Total belanja bulan ini
  Future<int> getTotalBelanjaBulanIni() async {
    final db = await instance.database;
    String currentMonth = DateTime.now().toIso8601String().substring(0, 7);
    final result = await db.rawQuery(
      'SELECT SUM(total_belanja) as total FROM belanja WHERE tanggal LIKE ?',
      ['$currentMonth%'],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  // 4. Total pendapatan hari ini
  Future<int> getPendapatanHariIni() async {
    final db = await instance.database;
    String today = DateTime.now().toIso8601String().substring(
      0,
      10,
    ); // Format: YYYY-MM-DD
    final result = await db.rawQuery(
      'SELECT SUM(grand_total) as total FROM transaksi WHERE tanggal LIKE ?',
      ['$today%'],
    );
    return (result.first['total'] as int?) ?? 0;
  }
}
