import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'db_helper.dart';
import 'constants.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// KREDENSIAL API NVIDIA
const String apiKey =
    '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';
const String apiUrl = 'https://integrate.api.nvidia.com/v1/chat/completions';
const String aiModel = 'google/gemma-3n-e4b-it';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: bgColor,
        canvasColor: secondaryColor,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: const MainScreen(),
    ),
  );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const StockPage(),
    const ChatbotPage(),
    const TransactionPage(),
    const ReportPage(),
    const PurchaseBotPage(),
    const PurchaseReportPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? "Dashboard"
              : _selectedIndex == 1
              ? "Manajemen Stok"
              : _selectedIndex == 2
              ? "Asisten AI"
              : _selectedIndex == 3
              ? "Kasir Transaksi"
              : _selectedIndex == 4
              ? "Laporan Penjualan"
              : _selectedIndex == 5
              ? "Catat Belanja (AI)"
              : "Data Pembelian",
        ),
        backgroundColor: bgColor,
        elevation: 0,
      ),
      drawer: SideMenu(
        onIndexChanged: (index) {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
        selectedIndex: _selectedIndex,
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
    );
  }
}

// ============================================================
// --- COMPONENT: SIDE MENU (Drawer) (DIPERBARUI) ---
// ============================================================
class SideMenu extends StatelessWidget {
  final Function(int) onIndexChanged;
  final int selectedIndex;

  const SideMenu({
    super.key,
    required this.onIndexChanged,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- PERUBAHAN DI SINI: Mengganti Ikon dengan Foto ---
                Container(
                  padding: const EdgeInsets.all(3), // Border tipis
                  decoration: const BoxDecoration(
                    color: primaryColor, // Warna border
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 40, // Ukuran di Sidebar
                    // Pastikan path dan nama file ini sesuai dengan pubspec.yaml Anda
                    backgroundImage: AssetImage('android/assets/images/logo.png'),
                    backgroundColor: bgColor, // Warna cadangan saat loading
                  ),
                ),
                // -----------------------------------------------------
                const SizedBox(height: 10),
                const Text(
                  "NF Garage Admin",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          DrawerListTile(
            title: "Dashboard",
            icon: Icons.dashboard,
            press: () => onIndexChanged(0),
            selected: selectedIndex == 0,
          ),
          const Divider(color: Colors.white10),
          DrawerListTile(
            title: "Daftar Stok",
            icon: Icons.inventory_2_outlined,
            press: () => onIndexChanged(1),
            selected: selectedIndex == 1,
          ),
          DrawerListTile(
            title: "Asisten AI",
            icon: Icons.chat_bubble_outline,
            press: () => onIndexChanged(2),
            selected: selectedIndex == 2,
          ),
          DrawerListTile(
            title: "Catat Transaksi",
            icon: Icons.point_of_sale,
            press: () => onIndexChanged(3),
            selected: selectedIndex == 3,
          ),
          DrawerListTile(
            title: "Laporan Penjualan",
            icon: Icons.summarize_outlined,
            press: () => onIndexChanged(4),
            selected: selectedIndex == 4,
          ),
          const Divider(color: Colors.white10),
          DrawerListTile(
            title: "Catat Belanja (AI)",
            icon: Icons.add_shopping_cart,
            press: () => onIndexChanged(5),
            selected: selectedIndex == 5,
          ),
          DrawerListTile(
            title: "Data Pembelian",
            icon: Icons.receipt_long,
            press: () => onIndexChanged(6),
            selected: selectedIndex == 6,
          ),
        ],
      ),
    );
  }
}

class DrawerListTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback press;
  final bool selected;

  const DrawerListTile({
    super.key,
    required this.title,
    required this.icon,
    required this.press,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: press,
      horizontalTitleGap: 0.0,
      leading: Icon(
        icon,
        color: selected ? primaryColor : Colors.white54,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(color: selected ? Colors.white : Colors.white54),
      ),
      selected: selected,
      selectedTileColor: primaryColor.withOpacity(0.1),
    );
  }
}

// ============================================================
// --- HALAMAN DASHBOARD (DIPERBARUI) ---
// ============================================================
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int barangTerjual = 0;
  int transaksiBulanIni = 0;
  int belanjaBulanIni = 0;
  int pendapatanHariIni = 0;

  Future<void> _loadSummary() async {
    final dbHelper = DatabaseHelper.instance;
    final bt = await dbHelper.getTotalBarangTerjual();
    final tb = await dbHelper.getJumlahTransaksiBulanIni();
    final bb = await dbHelper.getTotalBelanjaBulanIni();
    final ph = await dbHelper.getPendapatanHariIni();

    if (mounted) {
      setState(() {
        barangTerjual = bt;
        transaksiBulanIni = tb;
        belanjaBulanIni = bb;
        pendapatanHariIni = ph;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Widget _buildCard(String title, String value, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return RefreshIndicator(
      onRefresh: _loadSummary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "WELCOME BACK",
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "NF Garage Admin",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // --- PERUBAHAN DI SINI: Mengganti Ikon dengan Foto ---
              Container(
                padding: const EdgeInsets.all(2), // Border tipis
                decoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const CircleAvatar(
                  radius: 28, // Ukuran di Dashboard
                  // Pastikan path dan nama file ini sesuai dengan pubspec.yaml Anda
                  backgroundImage: AssetImage('android/assets/images/logo.png'),
                  backgroundColor: secondaryColor, // Warna cadangan
                ),
              ),
              // -----------------------------------------------------
            ],
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.05,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildCard(
                "Barang Terjual",
                "$barangTerjual",
                const Color(0xFF74DE5D),
                "Total akumulasi qty",
              ),
              _buildCard(
                "Transaksi",
                "$transaksiBulanIni",
                const Color(0xFFF72A57),
                "Nota bulan ini",
              ),
              _buildCard(
                "Belanja (Bulan Ini)",
                currencyFormat.format(belanjaBulanIni),
                const Color(0xFFFACC39),
                "Pengeluaran kulakan",
              ),
              _buildCard(
                "Pendapatan",
                currencyFormat.format(pendapatanHariIni),
                const Color(0xFF5A75F8),
                "Total omzet hari ini",
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- HALAMAN DAFTAR STOK ---
// (Kode halaman Stok tetap sama, tidak ada perubahan)
class StockPage extends StatefulWidget {
  const StockPage({super.key});
  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  List<Map<String, dynamic>> _inventory = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  File? _refImage;

  Future<void> _fetchData() async {
    final data = await DatabaseHelper.instance.cariBarang("");
    setState(() => _inventory = data);
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _pickRefImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: source,
      imageQuality: 50,
    );
    if (photo != null) {
      setState(() => _refImage = File(photo.path));
    }
  }

  void _showEntryDialog({Map<String, dynamic>? item}) {
    if (item != null) {
      _nameController.text = item['nama'].toString();
      _priceController.text = item['harga'].toString();
      _refImage = item['gambar'] != null
          ? File(item['gambar'].toString())
          : null;
    } else {
      _nameController.clear();
      _priceController.clear();
      _refImage = null;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: secondaryColor,
          title: Text(item == null ? "Tambah Barang" : "Edit Barang"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    await _pickRefImage(ImageSource.gallery);
                    setDialogState(() {});
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: _refImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_refImage!, fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: primaryColor),
                              Text(
                                "Klik untuk Foto Referensi",
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Nama Barang"),
                ),
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: "Harga"),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () async {
                if (item == null) {
                  await DatabaseHelper.instance.tambahBarang(
                    _nameController.text,
                    int.parse(_priceController.text),
                    gambar: _refImage?.path,
                  );
                } else {
                  await DatabaseHelper.instance.updateBarang(
                    item['id'] as int,
                    _nameController.text,
                    int.parse(_priceController.text),
                    gambar: _refImage?.path,
                  );
                }
                if (context.mounted) Navigator.pop(context);
                _fetchData();
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    "Daftar Stok",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      color: primaryColor,
                      size: 20,
                    ),
                    tooltip: "Refresh Data",
                    onPressed: () {
                      _fetchData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Data Stok diperbarui"),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showEntryDialog(),
                icon: const Icon(Icons.add),
                label: const Text("Tambah"),
              ),
            ],
          ),
          const SizedBox(height: defaultPadding),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchData,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _inventory.length,
                itemBuilder: (context, index) {
                  final barang = _inventory[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: secondaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: barang['gambar'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(barang['gambar'].toString()),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.image_not_supported,
                                color: Colors.white24,
                              ),
                      ),
                      title: Text(barang['nama'].toString()),
                      subtitle: Text("Rp${barang['harga']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: primaryColor),
                            onPressed: () => _showEntryDialog(item: barang),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () async {
                              await DatabaseHelper.instance.hapusBarang(
                                barang['id'] as int,
                              );
                              _fetchData();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- HALAMAN CHATBOT & KAMERA ---
// (Kode Chatbot tetap sama)
class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _messages.add({
      "text":
          "Halo bos! Asisten udah pakai server premium nih. Mau cek harga atau tanya laporan hari ini?",
      "isUser": false,
      "image": null,
    });
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: secondaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text(
                  "Ambil dari Kamera",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.white),
                title: const Text(
                  "Pilih dari Galeri",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
      });
    }
  }

  Future<void> _sendMessage() async {
    String userText = _controller.text.trim();
    File? imageToSend = _selectedImage;

    if (userText.isEmpty && imageToSend == null) return;

    setState(() {
      _messages.insert(0, {
        "text": userText,
        "isUser": true,
        "image": imageToSend,
      });
      _controller.clear();
      _selectedImage = null;
      _isLoading = true;
    });

    try {
      final allStok = await DatabaseHelper.instance.cariBarang("");
      final allTransaksi = await DatabaseHelper.instance.getTransaksi();
      final allBelanja = await DatabaseHelper.instance.getBelanja();

      String dbContext = allStok
          .map((e) => "- ${e['nama']}: Rp${e['harga']}")
          .join("\n");

      String trxContext = allTransaksi.isEmpty
          ? "Belum ada transaksi"
          : allTransaksi
                .map(
                  (e) =>
                      "- Tgl ${e['tanggal'].toString().substring(0, 10)} : Rp${e['grand_total']}",
                )
                .join("\n");

      String bljContext = allBelanja.isEmpty
          ? "Belum ada pengeluaran"
          : allBelanja
                .map(
                  (e) =>
                      "- Tgl ${e['tanggal'].toString().substring(0, 10)} : Rp${e['total_belanja']} (${e['keterangan'] ?? 'Belanja'})",
                )
                .join("\n");

      List<Map<String, dynamic>> contentArray = [];

      if (imageToSend != null) {
        String promptGambar =
            '''
[SISTEM] Kamu asisten 'NF Garage'.
[DATA STOK]:
$dbContext

[TUGAS]
''';
        if (userText.isEmpty) {
          promptGambar +=
              "Identifikasi barang di foto dan sebutkan harganya dari Data Stok. JANGAN KASIH JSON.";
        } else {
          promptGambar +=
              "Pesan User: \"$userText\"\nJika instruksi simpan stok, beri JSON: {\"action\": \"simpan\", \"nama\": \"\", \"harga\": 0}";
        }

        final bytes = await imageToSend.readAsBytes();
        contentArray.add({"type": "text", "text": promptGambar});
        contentArray.add({
          "type": "image_url",
          "image_url": {"url": "data:image/jpeg;base64,${base64Encode(bytes)}"},
        });
      } else {
        String promptTeks =
            '''
[SISTEM] Kamu adalah Asisten Cerdas 'NF Garage'. Kamu bertugas menjawab pertanyaan terkait harga barang, total pendapatan, and total pengeluaran bengkel.
Hitung dengan teliti and akurat berdasarkan data mutlak di bawah ini:

--- DATA STOK BARANG ---
$dbContext

--- DATA PENDAPATAN (KAS MASUK) ---
$trxContext

--- DATA PENGELUARAN (BELANJA) ---
$bljContext

[ATURAN]
1. Jika user bertanya total pendapatan/pengeluaran pada periode tertentu, kelompokkan tanggalnya, HITUNG TOTALNYA, and berikan jawabannya.
2. Jika ditanya harga, lihat Data Stok.
3. Jawab dengan gaya bahasa ramah and asik ala asisten bengkel.
4. JANGAN menampilkan data mentah yang panjang, langsung berikan rangkuman analisis and hasil hitungannya saja.

[USER] $userText
[ASISTEN]''';

        contentArray.add({"type": "text", "text": promptTeks});
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": aiModel,
          "messages": [
            {"role": "user", "content": contentArray},
          ],
          "max_tokens": 800,
          "temperature": 0.1,
          "stream": false,
        }),
      );

      if (response.statusCode == 200) {
        String aiRes = jsonDecode(
          response.body,
        )['choices'][0]['message']['content'].toString().trim();

        if (aiRes.contains('"action":') && aiRes.contains('"simpan"')) {
          try {
            final data = jsonDecode(
              aiRes.substring(aiRes.indexOf('{'), aiRes.lastIndexOf('}') + 1),
            );
            await DatabaseHelper.instance.tambahBarang(
              data['nama'].toString(),
              (data['harga'] as num).toInt(),
            );
            setState(
              () => _messages.insert(0, {
                "text":
                    "Sip! Stok ${data['nama']} (Rp${data['harga']}) masuk ke database.",
                "isUser": false,
                "image": null,
              }),
            );
          } catch (_) {
            setState(
              () => _messages.insert(0, {
                "text": "Gagal baca data JSON bos.",
                "isUser": false,
                "image": null,
              }),
            );
          }
        } else {
          setState(
            () => _messages.insert(0, {
              "text": aiRes,
              "isUser": false,
              "image": null,
            }),
          );
        }
      } else {
        setState(
          () => _messages.insert(0, {
            "text": "Error Server (${response.statusCode})",
            "isUser": false,
            "image": null,
          }),
        );
      }
    } catch (e) {
      setState(
        () => _messages.insert(0, {
          "text": "Koneksi terputus. Error: $e",
          "isUser": false,
          "image": null,
        }),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(defaultPadding),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return Align(
                alignment: msg['isUser']
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: msg['isUser'] ? primaryColor : secondaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (msg['image'] != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            msg['image'] as File,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (msg['text'].toString().isNotEmpty)
                        Text(
                          msg['text'].toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_isLoading)
          const LinearProgressIndicator(
            color: primaryColor,
            backgroundColor: secondaryColor,
          ),
        _buildChatInput(),
      ],
    );
  }

  Widget _buildChatInput() {
    return Column(
      children: [
        if (_selectedImage != null)
          Container(
            padding: const EdgeInsets.all(10),
            color: bgColor,
            alignment: Alignment.centerLeft,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImage!,
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: -5,
                  top: -5,
                  child: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.redAccent),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(defaultPadding),
          decoration: const BoxDecoration(
            color: secondaryColor,
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.add_a_photo, color: primaryColor),
                onPressed: _showPickerOptions,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  minLines: 1,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Tanya harga atau kasih caption...",
                    fillColor: bgColor,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                margin: const EdgeInsets.only(bottom: 2),
                decoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// --- HALAMAN KASIR TRANSAKSI, LAPORAN, BELANJA ---
// (Kode halaman-halaman ini tetap sama seperti Turn sebelumnya)
// ============================================================
class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  List<File> _selectedImages = [];

  final List<Map<String, dynamic>> _jasaManual = [];
  final TextEditingController _namaJasaController = TextEditingController();
  final TextEditingController _biayaJasaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _messages.add({
      "text":
          "Mode Kasir aktif!\n\nKirim foto barang/struk untuk scan otomatis. "
          "Atau tambahkan jasa manual di bawah lalu ketuk Kirim.",
      "isUser": false,
      "images": <File>[],
    });
  }

  void _showKelolaJasaDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: secondaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tambah Biaya Jasa",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: _namaJasaController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Nama Jasa",
                          labelStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: bgColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _biayaJasaController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Biaya (Rp)",
                          labelStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: bgColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                      ),
                      onPressed: () {
                        final nama = _namaJasaController.text.trim();
                        final biayaStr = _biayaJasaController.text.trim();
                        if (nama.isEmpty || biayaStr.isEmpty) return;
                        final biaya = int.tryParse(biayaStr) ?? 0;
                        setSheet(() {
                          setState(() {
                            _jasaManual.add({
                              "nama_jasa": nama,
                              "biaya": biaya,
                            });
                          });
                        });
                        _namaJasaController.clear();
                        _biayaJasaController.clear();
                      },
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_jasaManual.isNotEmpty) ...[
                  const Divider(color: Colors.white12),
                  const Text(
                    "Daftar Jasa:",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  ..._jasaManual.asMap().entries.map((entry) {
                    final i = entry.key;
                    final jasa = entry.value;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.build,
                        color: primaryColor,
                        size: 18,
                      ),
                      title: Text(
                        jasa['nama_jasa'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Rp${jasa['biaya']}",
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 13,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            onPressed: () {
                              setSheet(() {
                                setState(() => _jasaManual.removeAt(i));
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(color: Colors.white12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Total Jasa: Rp${_jasaManual.fold<int>(0, (sum, j) => sum + (j['biaya'] as int))}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Selesai"),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: secondaryColor,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text("Ambil Foto (Kamera)"),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final photo = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 70,
                  );
                  if (photo != null) {
                    setState(() => _selectedImages.add(File(photo.path)));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text("Pilih Beberapa Foto (Galeri)"),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final List<XFile>? photos = await picker.pickMultiImage(
                    imageQuality: 70,
                  );
                  if (photos != null && photos.isNotEmpty) {
                    setState(() {
                      _selectedImages.addAll(photos.map((e) => File(e.path)));
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    String userText = _controller.text.trim();
    List<File> imagesToSend = List.from(_selectedImages);
    List<Map<String, dynamic>> jasaSnapshot = List.from(_jasaManual);

    if (userText.isEmpty && imagesToSend.isEmpty && jasaSnapshot.isEmpty) {
      return;
    }

    String praJasa = jasaSnapshot.isEmpty
        ? ""
        : "\n🔧 Jasa: ${jasaSnapshot.map((j) => "${j['nama_jasa']} (Rp${j['biaya']})").join(", ")}";

    setState(() {
      _messages.insert(0, {
        "text": userText.isEmpty
            ? "(Mengirim Gambar)$praJasa"
            : "$userText$praJasa",
        "isUser": true,
        "images": imagesToSend,
      });
      _controller.clear();
      _selectedImages.clear();
      _isLoading = true;
    });

    try {
      final allData = await DatabaseHelper.instance.cariBarang("");
      String dbContext = allData
          .map((e) => "- ${e['nama']} (Harga: Rp${e['harga']})")
          .join("\n");

      String promptJasaTambahan = jasaSnapshot.isEmpty
          ? "Jika ada teks biaya jasa dari pesan user, masukkan ke \"list_jasa\". Jika tidak ada, isi list_jasa dengan array kosong []."
          : "Jasa berikut sudah dicatat manual oleh kasir (JANGAN duplikasi): "
                "${jasaSnapshot.map((j) => "${j['nama_jasa']} Rp${j['biaya']}").join(", ")}. "
                "Jika ada JASA TAMBAHAN lain yang disebut user di teks pesannya, tambahkan ke list_jasa. Sisanya kosongkan.";

      String prompt =
          '''
Kamu adalah mesin sistem kasir. Tugasmu HANYA membaca data dan merespon dengan JSON murni.

DAFTAR HARGA STOK RESMI:
$dbContext

ATURAN PENTING:
1. Identifikasi SEMUA barang di foto atau pesan user.
2. Cocokkan dengan "DAFTAR HARGA STOK RESMI".
3. Pisahkan barang yang dibeli ke dalam array "list_barang" (nama_barang, qty, harga).
4. $promptJasaTambahan
5. WAJIB SELALU merespon dengan format JSON, tidak boleh membalas dengan teks biasa!

FORMAT JSON WAJIB:
{
  "action": "transaksi",
  "catatan": "Catatan tambahan pelanggan (Opsional)",
  "list_barang": [
    {"nama_barang": "Oli MPX", "qty": 1, "harga": 50000},
    {"nama_barang": "Busi NGK", "qty": 2, "harga": 20000}
  ],
  "list_jasa": [
    {"nama_jasa": "Service CVT", "biaya": 30000}
  ],
  "total_barang": 90000
}

PESAN DARI USER:
"${userText.isEmpty ? '[User hanya melampirkan foto tanpa teks]' : userText}"
''';

      List<Map<String, dynamic>> contentArray = [];
      contentArray.add({"type": "text", "text": prompt});

      for (var file in imagesToSend) {
        final bytes = await file.readAsBytes();
        final base64Image = base64Encode(bytes);
        contentArray.add({
          "type": "image_url",
          "image_url": {"url": "data:image/jpeg;base64,$base64Image"},
        });
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "model": aiModel,
          "messages": [
            {"role": "user", "content": contentArray},
          ],
          "max_tokens": 512,
          "temperature": 0.0,
          "top_p": 0.1,
          "stream": false,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String aiResponse = responseData['choices'][0]['message']['content']
            .toString()
            .trim();

        if (aiResponse.contains('"action":') &&
            aiResponse.contains('"transaksi"')) {
          try {
            String rawJson = aiResponse.substring(
              aiResponse.indexOf('{'),
              aiResponse.lastIndexOf('}') + 1,
            );
            final data = jsonDecode(rawJson);

            // MAPPING BARANG YANG DIBELI
            List<Map<String, dynamic>> allBarang = [];
            if (data['list_barang'] != null) {
              for (var b in (data['list_barang'] as List)) {
                allBarang.add({
                  "nama_barang": b['nama_barang'].toString(),
                  "qty": (b['qty'] as num?)?.toInt() ?? 1,
                  "harga": (b['harga'] as num?)?.toInt() ?? 0,
                });
              }
            }

            int tBarang = (data['total_barang'] as num?)?.toInt() ?? 0;
            if (tBarang == 0 && allBarang.isNotEmpty) {
              tBarang = allBarang.fold(
                0,
                (s, b) => s + ((b['qty'] as int) * (b['harga'] as int)),
              );
            }

            String catatan = data['catatan']?.toString() ?? "";
            if (catatan.trim().isEmpty && allBarang.isEmpty)
              catatan = "Hanya Jasa";

            // MAPPING JASA
            List<Map<String, dynamic>> allJasa = [];
            if (data['list_jasa'] != null) {
              for (var j in (data['list_jasa'] as List)) {
                allJasa.add({
                  "nama_jasa": j['nama_jasa'].toString(),
                  "biaya": (j['biaya'] as num).toInt(),
                });
              }
            }
            allJasa.addAll(jasaSnapshot);
            int totalJasa = allJasa.fold(
              0,
              (sum, j) => sum + (j['biaya'] as int),
            );

            if (tBarang <= 0 && totalJasa <= 0) {
              setState(
                () => _messages.insert(0, {
                  "text": "❌ Transaksi dibatalkan bos. Tidak ada barang/jasa.",
                  "isUser": false,
                  "images": <File>[],
                }),
              );
              return;
            }

            int grandTotal = tBarang + totalJasa;

            // 1. Simpan Transaksi Induk
            int transaksiId = await DatabaseHelper.instance.catatTransaksi(
              catatan,
              totalJasa,
              tBarang,
            );

            // 2. Simpan Detail Barang
            if (allBarang.isNotEmpty) {
              await DatabaseHelper.instance.tambahDetailTransaksi(
                transaksiId,
                allBarang,
              );
            }

            // 3. Simpan Detail Jasa
            if (allJasa.isNotEmpty) {
              await DatabaseHelper.instance.tambahJasaTransaksi(
                transaksiId,
                allJasa,
              );
            }

            String notaBarang = allBarang.isEmpty
                ? "  (tidak ada)"
                : allBarang
                      .map(
                        (b) =>
                            "  • ${b['nama_barang']} (${b['qty']}x): Rp${b['harga']}",
                      )
                      .join("\n");

            String notaJasa = allJasa.isEmpty
                ? "  (tidak ada)"
                : allJasa
                      .map((j) => "  • ${j['nama_jasa']}: Rp${j['biaya']}")
                      .join("\n");

            setState(() {
              _jasaManual.clear();
              _messages.insert(0, {
                "text":
                    "✅ Transaksi Dicatat!\n\n"
                    "🛒 Barang:\n$notaBarang\n\n"
                    "🔧 Jasa:\n$notaJasa\n\n"
                    "📦 Total Barang : Rp$tBarang\n"
                    "🔩 Total Jasa   : Rp$totalJasa\n"
                    "💰 Grand Total  : Rp$grandTotal",
                "isUser": false,
                "images": <File>[],
              });
            });
          } catch (e) {
            setState(
              () => _messages.insert(0, {
                "text":
                    "Gagal menyimpan transaksi bos. AI salah format. Error: $e",
                "isUser": false,
                "images": <File>[],
              }),
            );
          }
        } else {
          setState(
            () => _messages.insert(0, {
              "text": "$aiResponse\n\n⚠️ Jasa manual masih tersimpan.",
              "isUser": false,
              "images": <File>[],
            }),
          );
        }
      } else {
        setState(
          () => _messages.insert(0, {
            "text": "Error Server (${response.statusCode})",
            "isUser": false,
            "images": <File>[],
          }),
        );
      }
    } catch (e) {
      setState(
        () => _messages.insert(0, {
          "text": "Koneksi terputus. Error: $e",
          "isUser": false,
          "images": <File>[],
        }),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_jasaManual.isNotEmpty)
          GestureDetector(
            onTap: _showKelolaJasaDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: primaryColor.withOpacity(0.15),
              child: Row(
                children: [
                  const Icon(Icons.build, color: primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${_jasaManual.length} jasa ditambahkan · "
                      "Total Rp${_jasaManual.fold<int>(0, (s, j) => s + (j['biaya'] as int))}",
                      style: const TextStyle(color: primaryColor, fontSize: 13),
                    ),
                  ),
                  const Icon(Icons.edit, color: primaryColor, size: 16),
                ],
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(defaultPadding),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final List<File> imgs = msg['images'] != null
                  ? List<File>.from(msg['images'] as Iterable)
                  : [];

              return Align(
                alignment: msg['isUser']
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.82,
                  ),
                  decoration: BoxDecoration(
                    color: msg['isUser'] ? primaryColor : secondaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imgs.isNotEmpty)
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: imgs
                              .map(
                                (f) => ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    f,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      if (imgs.isNotEmpty) const SizedBox(height: 8),
                      if (msg['text'].toString().isNotEmpty)
                        Text(
                          msg['text'].toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_isLoading)
          const LinearProgressIndicator(
            color: primaryColor,
            backgroundColor: secondaryColor,
          ),
        _buildChatInput(),
      ],
    );
  }

  Widget _buildChatInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImages.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            color: bgColor,
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: -5,
                      child: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.redAccent),
                        onPressed: () =>
                            setState(() => _selectedImages.removeAt(index)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        Container(
          padding: const EdgeInsets.all(defaultPadding),
          decoration: const BoxDecoration(
            color: secondaryColor,
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.add_a_photo, color: primaryColor),
                onPressed: _showPickerOptions,
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.build, color: primaryColor),
                    onPressed: _showKelolaJasaDialog,
                    tooltip: "Tambah Biaya Jasa",
                  ),
                  if (_jasaManual.isNotEmpty)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            "${_jasaManual.length}",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  minLines: 1,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Ketik nama barang / catatan...",
                    hintStyle: const TextStyle(color: Colors.white38),
                    fillColor: bgColor,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  List<Map<String, dynamic>> _reports = [];
  DateTimeRange? _selectedDateRange;

  Future<void> _loadData() async {
    String? start, end;
    if (_selectedDateRange != null) {
      start = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
      end = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
    }
    final data = await DatabaseHelper.instance.getTransaksi(
      startDate: start,
      endDate: end,
    );
    setState(() => _reports = data);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _showDetailDialog(Map<String, dynamic> item) async {
    final listJasa = await DatabaseHelper.instance.getJasaByTransaksi(
      item['id'] as int,
    );
    final listBarang = await DatabaseHelper.instance.getDetailTransaksi(
      item['id'] as int,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: secondaryColor,
        title: const Text("Detail Transaksi"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat(
                  'dd MMM yyyy HH:mm',
                ).format(DateTime.parse(item['tanggal'])),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              if (item['deskripsi'] != null &&
                  item['deskripsi'].toString().isNotEmpty &&
                  item['deskripsi'] != "Hanya Jasa") ...[
                const SizedBox(height: 8),
                Text(
                  "Catatan: ${item['deskripsi']}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                "🛒 Barang Terjual:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              if (listBarang.isEmpty)
                const Text(
                  "  (tidak ada barang)",
                  style: TextStyle(color: Colors.white54),
                )
              else
                ...listBarang.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "  • ${b['nama_barang']} (${b['qty']}x)",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        Text(
                          "Rp${b['subtotal']}",
                          style: const TextStyle(color: Colors.greenAccent),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              const Text(
                "🔧 Biaya Jasa:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              if (listJasa.isEmpty)
                const Text(
                  "  (tidak ada)",
                  style: TextStyle(color: Colors.white54),
                )
              else
                ...listJasa.map(
                  (j) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "  • ${j['nama_jasa']}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          "Rp${j['biaya']}",
                          style: const TextStyle(color: Colors.greenAccent),
                        ),
                      ],
                    ),
                  ),
                ),
              const Divider(color: Colors.white12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Barang"),
                  Text(
                    "Rp${item['total_barang']}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Jasa"),
                  Text(
                    "Rp${item['biaya_jasa']}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const Divider(color: Colors.white12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Grand Total",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Rp${item['grand_total']}",
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> item) async {
    final existingJasa = await DatabaseHelper.instance.getJasaByTransaksi(
      item['id'] as int,
    );
    final existingBarang = await DatabaseHelper.instance.getDetailTransaksi(
      item['id'] as int,
    );

    if (!mounted) return;

    final deskController = TextEditingController(text: item['deskripsi']);

    List<Map<String, dynamic>> editJasa = existingJasa
        .map(
          (j) => {
            "id": j['id'],
            "nama_jasa": j['nama_jasa'],
            "biaya": j['biaya'],
          },
        )
        .toList();
    List<Map<String, dynamic>> editBarang = existingBarang
        .map(
          (b) => {
            "id": b['id'],
            "nama_barang": b['nama_barang'],
            "qty": b['qty'],
            "harga": b['harga_satuan'],
          },
        )
        .toList();

    final namaJasaCtrl = TextEditingController();
    final biayaJasaCtrl = TextEditingController();

    final namaBarangCtrl = TextEditingController();
    final qtyBarangCtrl = TextEditingController();
    final hargaBarangCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: secondaryColor,
          title: const Text("Edit Transaksi"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: deskController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Catatan Tambahan",
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  "🛒 Edit Barang:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...editBarang.asMap().entries.map((entry) {
                  final i = entry.key;
                  final b = entry.value;
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${b['nama_barang']} (${b['qty']}x) — Rp${b['harga']}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: () => setDlg(() => editBarang.removeAt(i)),
                      ),
                    ],
                  );
                }),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: namaBarangCtrl,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          labelText: "Barang Baru",
                          filled: true,
                          fillColor: bgColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: qtyBarangCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          labelText: "Qty",
                          filled: true,
                          fillColor: bgColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: hargaBarangCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          labelText: "Harga",
                          filled: true,
                          fillColor: bgColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: primaryColor),
                      onPressed: () {
                        if (namaBarangCtrl.text.isEmpty) return;
                        setDlg(() {
                          editBarang.add({
                            "id": null,
                            "nama_barang": namaBarangCtrl.text.trim(),
                            "qty": int.tryParse(qtyBarangCtrl.text) ?? 1,
                            "harga": int.tryParse(hargaBarangCtrl.text) ?? 0,
                          });
                        });
                        namaBarangCtrl.clear();
                        qtyBarangCtrl.clear();
                        hargaBarangCtrl.clear();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text(
                  "🔧 Edit Jasa:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...editJasa.asMap().entries.map((entry) {
                  final i = entry.key;
                  final j = entry.value;
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${j['nama_jasa']} — Rp${j['biaya']}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: () => setDlg(() => editJasa.removeAt(i)),
                      ),
                    ],
                  );
                }),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: namaJasaCtrl,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          labelText: "Jasa Baru",
                          filled: true,
                          fillColor: bgColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: biayaJasaCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          labelText: "Biaya",
                          filled: true,
                          fillColor: bgColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: primaryColor),
                      onPressed: () {
                        if (namaJasaCtrl.text.isEmpty) return;
                        setDlg(() {
                          editJasa.add({
                            "id": null,
                            "nama_jasa": namaJasaCtrl.text.trim(),
                            "biaya": int.tryParse(biayaJasaCtrl.text) ?? 0,
                          });
                        });
                        namaJasaCtrl.clear();
                        biayaJasaCtrl.clear();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () async {
                int totalBarang = editBarang.fold(
                  0,
                  (s, b) => s + ((b['qty'] as int) * (b['harga'] as int)),
                );
                int totalJasa = editJasa.fold(
                  0,
                  (s, j) => s + (j['biaya'] as int),
                );

                await DatabaseHelper.instance.updateTransaksi(
                  item['id'],
                  deskController.text,
                  totalJasa,
                  totalBarang,
                );

                await DatabaseHelper.instance.hapusSemuaDetailTransaksi(
                  item['id'],
                );
                if (editBarang.isNotEmpty) {
                  await DatabaseHelper.instance.tambahDetailTransaksi(
                    item['id'],
                    editBarang,
                  );
                }

                await DatabaseHelper.instance.hapusSemuaJasaTransaksi(
                  item['id'],
                );
                if (editJasa.isNotEmpty) {
                  await DatabaseHelper.instance.tambahJasaTransaksi(
                    item['id'],
                    editJasa,
                  );
                }

                if (context.mounted) Navigator.pop(context);
                _loadData();
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToExcel() async {
    if (_reports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada data untuk diekspor bos!")),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sedang merakit laporan penjualan..."),
          duration: Duration(seconds: 1),
        ),
      );
      var excel = Excel.createExcel();
      var sheet = excel['Sheet1'];

      sheet.appendRow([
        TextCellValue("No"),
        TextCellValue("Tanggal"),
        TextCellValue("Catatan"),
        TextCellValue("Rincian Barang Terjual"),
        TextCellValue("Rincian Jasa"),
        TextCellValue("Biaya Barang (Rp)"),
        TextCellValue("Biaya Jasa (Rp)"),
        TextCellValue("Grand Total (Rp)"),
      ]);

      int totalPendapatan = 0;

      for (var i = 0; i < _reports.length; i++) {
        var r = _reports[i];
        int subTotal = int.parse(r['grand_total'].toString());
        totalPendapatan += subTotal;

        final listBarang = await DatabaseHelper.instance.getDetailTransaksi(
          r['id'] as int,
        );
        final listJasa = await DatabaseHelper.instance.getJasaByTransaksi(
          r['id'] as int,
        );

        String rincianBarang = listBarang.isEmpty
            ? "-"
            : listBarang
                  .map(
                    (b) =>
                        "${b['nama_barang']} (${b['qty']}x Rp${b['harga_satuan']})",
                  )
                  .join(", ");
        String rincianJasa = listJasa.isEmpty
            ? "-"
            : listJasa
                  .map((j) => "${j['nama_jasa']} (Rp${j['biaya']})")
                  .join(", ");

        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(
            DateFormat(
              'dd/MM/yyyy HH:mm',
            ).format(DateTime.parse(r['tanggal'].toString())),
          ),
          TextCellValue(r['deskripsi'].toString()),
          TextCellValue(rincianBarang),
          TextCellValue(rincianJasa),
          IntCellValue(int.parse(r['total_barang'].toString())),
          IntCellValue(int.parse(r['biaya_jasa'].toString())),
          IntCellValue(subTotal),
        ]);
      }

      sheet.appendRow([TextCellValue("")]);
      sheet.appendRow([
        TextCellValue(""),
        TextCellValue(""),
        TextCellValue(""),
        TextCellValue("TOTAL PENDAPATAN KESELURUHAN"),
        TextCellValue(""),
        TextCellValue(""),
        TextCellValue(""),
        IntCellValue(totalPendapatan),
      ]);

      var fileBytes = excel.save();
      final directory = await getApplicationDocumentsDirectory();
      String filePath =
          "${directory.path}/Laporan_Penjualan_NF_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx";

      final file = File(filePath);
      await file.writeAsBytes(fileBytes!);
      await Share.shareXFiles([
        XFile(filePath),
      ], text: 'Laporan Penjualan NF Garage - Total: Rp$totalPendapatan');
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal export: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Riwayat Transaksi",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: primaryColor,
                          size: 20,
                        ),
                        tooltip: "Refresh Data",
                        onPressed: () {
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Data Transaksi diperbarui"),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Text(
                    _selectedDateRange == null
                        ? "Semua Periode"
                        : "${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.date_range, color: primaryColor),
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedDateRange = picked);
                        _loadData();
                      }
                    },
                  ),
                  if (_selectedDateRange != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: () {
                        setState(() => _selectedDateRange = null);
                        _loadData();
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.green),
                    onPressed: _exportToExcel,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: defaultPadding),
          Expanded(
            child: _reports.isEmpty
                ? const Center(
                    child: Text(
                      "Belum ada transaksi",
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _reports.length,
                      itemBuilder: (context, index) {
                        final r = _reports[index];
                        return GestureDetector(
                          onTap: () => _showDetailDialog(r),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: secondaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Nota #${r['id']} - ${r['deskripsi'] == '' || r['deskripsi'] == 'Hanya Jasa' ? 'Transaksi Kasir' : r['deskripsi']}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        DateFormat(
                                          'dd MMM yyyy HH:mm',
                                        ).format(DateTime.parse(r['tanggal'])),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white38,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        "Barang: Rp${r['total_barang']} · Jasa: Rp${r['biaya_jasa']}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Rp${r['grand_total']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.greenAccent,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 18,
                                            color: Colors.white24,
                                          ),
                                          onPressed: () => _showEditDialog(r),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            size: 18,
                                            color: Colors.redAccent.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                          onPressed: () async {
                                            await DatabaseHelper.instance
                                                .hapusTransaksi(r['id']);
                                            _loadData();
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class PurchaseBotPage extends StatefulWidget {
  const PurchaseBotPage({super.key});
  @override
  State<PurchaseBotPage> createState() => _PurchaseBotPageState();
}

class _PurchaseBotPageState extends State<PurchaseBotPage> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  List<File> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _messages.add({
      "text": "Bos, foto struk kulakan atau ketik daftar belanjaan di sini ya!",
      "isUser": false,
      "images": <File>[],
    });
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: secondaryColor,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text("Ambil Foto (Kamera)"),
                onTap: () async {
                  Navigator.pop(context);
                  final photo = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                    imageQuality: 70,
                  );
                  if (photo != null)
                    setState(() => _selectedImages.add(File(photo.path)));
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text("Pilih Foto (Galeri)"),
                onTap: () async {
                  Navigator.pop(context);
                  final photos = await ImagePicker().pickMultiImage(
                    imageQuality: 70,
                  );
                  if (photos != null && photos.isNotEmpty) {
                    setState(
                      () => _selectedImages.addAll(
                        photos.map((e) => File(e.path)),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    String userText = _controller.text.trim();
    List<File> imagesToSend = List.from(_selectedImages);

    if (userText.isEmpty && imagesToSend.isEmpty) return;

    setState(() {
      _messages.insert(0, {
        "text": userText.isEmpty ? "(Mengirim Foto Struk)" : userText,
        "isUser": true,
        "images": imagesToSend,
      });
      _controller.clear();
      _selectedImages.clear();
      _isLoading = true;
    });

    try {
      String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      String prompt =
          '''
Kamu adalah asisten Purchasing 'NF Garage'. Catat struk belanja/pengeluaran secara mendetail.

ATURAN PENTING:
1. Identifikasi SETIAP barang atau jasa yang dibayar di dalam struk.
2. Pisahkan data ke dalam "list_barang".
3. BACA TANGGAL DARI FOTO STRUK (contoh tulisan tangan 30/7-25 artinya 2025-07-30). Ubah ke format YYYY-MM-DD. 
4. JIKA TIDAK ADA TANGGAL SAMA SEKALI DI GAMBAR, gunakan tanggal hari ini: $todayDate.
5. PENTING: Output WAJIB JSON murni (JANGAN gunakan teks format markdown ```json and JANGAN salin tanggal dari contoh di bawah ini):

FORMAT JSON:
{
  "action": "belanja", 
  "tanggal": "YYYY-MM-DD",
  "keterangan": "Plat/Nama Toko (Opsional)",
  "list_barang": [
    {"nama": "Item A", "qty": 1, "harga": 35000},
    {"nama": "Item B", "qty": 2, "harga": 20000}
  ],
  "total_keseluruhan": 75000
}

PESAN USER: "${userText.isEmpty ? '[User melampirkan foto struk]' : userText}"
''';

      List<Map<String, dynamic>> contentArray = [
        {"type": "text", "text": prompt},
      ];
      for (var file in imagesToSend) {
        contentArray.add({
          "type": "image_url",
          "image_url": {
            "url":
                "data:image/jpeg;base64,${base64Encode(await file.readAsBytes())}",
          },
        });
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": aiModel,
          "messages": [
            {"role": "user", "content": contentArray},
          ],
          "max_tokens": 1000,
          "temperature": 0.0,
          "stream": false,
        }),
      );

      if (response.statusCode == 200) {
        String aiRes = jsonDecode(
          response.body,
        )['choices'][0]['message']['content'].toString().trim();
        if (aiRes.contains('"action":') && aiRes.contains('"belanja"')) {
          try {
            final data = jsonDecode(
              aiRes.substring(aiRes.indexOf('{'), aiRes.lastIndexOf('}') + 1),
            );

            String tgl = data['tanggal'] ?? DateTime.now().toIso8601String();
            if (tgl.isEmpty || tgl == "null")
              tgl = DateTime.now().toIso8601String();
            int total = (data['total_keseluruhan'] as num).toInt();
            List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(
              data['list_barang'] ?? [],
            );

            String keterangan = data['keterangan']?.toString() ?? "";
            if (keterangan.isEmpty && items.isNotEmpty)
              keterangan = items
                  .map((e) => "${e['nama']} (${e['qty']}x)")
                  .join(", ");

            int belanjaId = await DatabaseHelper.instance.catatBelanjaInduk(
              total,
              tgl,
              keterangan: keterangan,
            );
            if (items.isNotEmpty)
              await DatabaseHelper.instance.tambahDetailBelanja(
                belanjaId,
                items,
              );

            setState(() {
              _messages.insert(0, {
                "text":
                    "✅ Belanja Berhasil Dicatat!\n\n${items.map((e) => "• ${e['nama']} (${e['qty']}x)").join("\n")}\n\nTotal: Rp$total",
                "isUser": false,
                "images": <File>[],
              });
            });
          } catch (e) {
            setState(
              () => _messages.insert(0, {
                "text": "Gagal simpan data detail.",
                "isUser": false,
              }),
            );
          }
        } else {
          setState(
            () => _messages.insert(0, {
              "text": aiRes,
              "isUser": false,
              "images": <File>[],
            }),
          );
        }
      } else {
        setState(
          () => _messages.insert(0, {
            "text": "Error Server",
            "isUser": false,
            "images": <File>[],
          }),
        );
      }
    } catch (e) {
      setState(
        () => _messages.insert(0, {
          "text": "Koneksi terputus.",
          "isUser": false,
          "images": <File>[],
        }),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(defaultPadding),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final imgs = msg['images'] != null
                  ? List<File>.from(msg['images'] as Iterable)
                  : [];
              return Align(
                alignment: msg['isUser']
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.82,
                  ),
                  decoration: BoxDecoration(
                    color: msg['isUser'] ? primaryColor : secondaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imgs.isNotEmpty)
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: imgs
                              .map(
                                (f) => ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    f,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      if (imgs.isNotEmpty) const SizedBox(height: 8),
                      if (msg['text'].toString().isNotEmpty)
                        Text(
                          msg['text'].toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_isLoading)
          const LinearProgressIndicator(
            color: primaryColor,
            backgroundColor: secondaryColor,
          ),
        _buildChatInput(),
      ],
    );
  }

  Widget _buildChatInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImages.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            color: bgColor,
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: -5,
                      child: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.redAccent),
                        onPressed: () =>
                            setState(() => _selectedImages.removeAt(index)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        Container(
          padding: const EdgeInsets.all(defaultPadding),
          decoration: const BoxDecoration(
            color: secondaryColor,
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.add_a_photo, color: primaryColor),
                onPressed: _showPickerOptions,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  minLines: 1,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Contoh: Beli busi 3 pcs 35rb/pcs",
                    fillColor: bgColor,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PurchaseReportPage extends StatefulWidget {
  const PurchaseReportPage({super.key});
  @override
  State<PurchaseReportPage> createState() => _PurchaseReportPageState();
}

class _PurchaseReportPageState extends State<PurchaseReportPage> {
  List<Map<String, dynamic>> _reports = [];
  DateTimeRange? _selectedDateRange;

  Future<void> _loadData() async {
    String? start, end;
    if (_selectedDateRange != null) {
      start = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start);
      end = DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end);
    }
    final data = await DatabaseHelper.instance.getBelanja(
      startDate: start,
      endDate: end,
    );
    setState(() => _reports = data);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _showEntryDialog({Map<String, dynamic>? item}) async {
    final deskController = TextEditingController(
      text: item?['keterangan'] ?? "",
    );
    DateTime selectedDate = item != null
        ? DateTime.parse(item['tanggal'])
        : DateTime.now();

    List<Map<String, dynamic>> editBarang = [];

    if (item != null) {
      final existingBarang = await DatabaseHelper.instance.getDetailBelanja(
        item['id'] as int,
      );
      editBarang = existingBarang
          .map(
            (b) => {
              "id": b['id'],
              "nama": b['nama_barang'],
              "qty": b['qty'],
              "harga": b['harga_satuan'],
            },
          )
          .toList();
    }

    if (!mounted) return;

    final namaBarangCtrl = TextEditingController();
    final qtyBarangCtrl = TextEditingController();
    final hargaBarangCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDlg) {
          int totalCurrent = editBarang.fold(
            0,
            (s, b) => s + ((b['qty'] as int) * (b['harga'] as int)),
          );

          return AlertDialog(
            backgroundColor: secondaryColor,
            title: Text(
              item == null ? "Tambah Pengeluaran" : "Edit Pengeluaran",
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: deskController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Keterangan / Nama Toko (Opsional)",
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    "🛒 Daftar Barang Dibeli:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  ...editBarang.asMap().entries.map((entry) {
                    final i = entry.key;
                    final b = entry.value;
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${b['nama']} (${b['qty']}x) — Rp${b['harga']}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: () => setDlg(() => editBarang.removeAt(i)),
                        ),
                      ],
                    );
                  }),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: namaBarangCtrl,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          decoration: InputDecoration(
                            labelText: "Barang",
                            filled: true,
                            fillColor: bgColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: qtyBarangCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          decoration: InputDecoration(
                            labelText: "Qty",
                            filled: true,
                            fillColor: bgColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: hargaBarangCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          decoration: InputDecoration(
                            labelText: "Harga/item",
                            filled: true,
                            fillColor: bgColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: primaryColor),
                        onPressed: () {
                          if (namaBarangCtrl.text.isEmpty) return;
                          setDlg(() {
                            editBarang.add({
                              "id": null,
                              "nama": namaBarangCtrl.text.trim(),
                              "qty": int.tryParse(qtyBarangCtrl.text) ?? 1,
                              "harga": int.tryParse(hargaBarangCtrl.text) ?? 0,
                            });
                          });
                          namaBarangCtrl.clear();
                          qtyBarangCtrl.clear();
                          hargaBarangCtrl.clear();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Belanja:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Rp$totalCurrent",
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Tgl: ${DateFormat('dd MMM yyyy').format(selectedDate)}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null)
                            setDlg(() => selectedDate = picked);
                        },
                        child: const Text(
                          "Ubah Tanggal",
                          style: TextStyle(color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                onPressed: () async {
                  int finalTotal = editBarang.fold(
                    0,
                    (s, b) => s + ((b['qty'] as int) * (b['harga'] as int)),
                  );

                  if (item == null) {
                    int belanjaId = await DatabaseHelper.instance
                        .catatBelanjaInduk(
                          finalTotal,
                          selectedDate.toIso8601String(),
                          keterangan: deskController.text,
                        );

                    if (editBarang.isNotEmpty) {
                      await DatabaseHelper.instance.tambahDetailBelanja(
                        belanjaId,
                        editBarang,
                      );
                    }
                  } else {
                    await DatabaseHelper.instance.updateBelanja(
                      item['id'],
                      finalTotal,
                      selectedDate.toIso8601String(),
                      deskController.text,
                    );

                    await DatabaseHelper.instance.hapusSemuaDetailBelanja(
                      item['id'],
                    );

                    if (editBarang.isNotEmpty) {
                      await DatabaseHelper.instance.tambahDetailBelanja(
                        item['id'],
                        editBarang,
                      );
                    }
                  }

                  if (context.mounted) Navigator.pop(context);
                  _loadData();
                },
                child: const Text("Simpan"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportToExcel() async {
    if (_reports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada data untuk diekspor bos!")),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sedang merakit laporan pengeluaran...")),
      );
      var excel = Excel.createExcel();
      var sheet = excel['Sheet1'];

      sheet.appendRow([
        TextCellValue("No"),
        TextCellValue("Tanggal"),
        TextCellValue("Keterangan Induk"),
        TextCellValue("Rincian Item Belanja"),
        TextCellValue("Total Pengeluaran (Rp)"),
      ]);

      int totalPengeluaran = 0;
      for (var i = 0; i < _reports.length; i++) {
        var r = _reports[i];
        int subTotal = int.parse(r['total_belanja'].toString());
        totalPengeluaran += subTotal;

        final details = await DatabaseHelper.instance.getDetailBelanja(r['id']);
        String rincian = details.isEmpty
            ? "-"
            : details
                  .map(
                    (d) =>
                        "${d['nama_barang']} (${d['qty']}x Rp${d['harga_satuan']})",
                  )
                  .join(", ");

        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(
            DateFormat(
              'dd/MM/yyyy',
            ).format(DateTime.parse(r['tanggal'].toString())),
          ),
          TextCellValue(r['keterangan'].toString()),
          TextCellValue(rincian),
          IntCellValue(subTotal),
        ]);
      }

      sheet.appendRow([TextCellValue("")]);
      sheet.appendRow([
        TextCellValue(""),
        TextCellValue(""),
        TextCellValue(""),
        TextCellValue("TOTAL PENGELUARAN KESELURUHAN"),
        IntCellValue(totalPengeluaran),
      ]);

      var fileBytes = excel.save();
      final directory = await getApplicationDocumentsDirectory();
      String filePath =
          "${directory.path}/Laporan_Belanja_NF_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx";

      await File(filePath).writeAsBytes(fileBytes!);
      await Share.shareXFiles(
        [XFile(filePath)],
        text:
            'Laporan Belanja/Pengeluaran NF Garage - Total: Rp$totalPengeluaran',
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal export: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Data Pembelian",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: primaryColor,
                          size: 20,
                        ),
                        tooltip: "Refresh Data",
                        onPressed: () {
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Data Pembelian diperbarui"),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Text(
                    _selectedDateRange == null
                        ? "Semua Periode"
                        : "${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_box, color: primaryColor),
                    onPressed: () => _showEntryDialog(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.date_range, color: primaryColor),
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedDateRange = picked);
                        _loadData();
                      }
                    },
                  ),
                  if (_selectedDateRange != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: () {
                        setState(() => _selectedDateRange = null);
                        _loadData();
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.redAccent),
                    onPressed: _exportToExcel,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: defaultPadding),
          Expanded(
            child: _reports.isEmpty
                ? const Center(
                    child: Text(
                      "Belum ada data belanja",
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _reports.length,
                      itemBuilder: (context, index) {
                        final r = _reports[index];
                        return GestureDetector(
                          onTap: () async {
                            final details = await DatabaseHelper.instance
                                .getDetailBelanja(r['id']);
                            if (!context.mounted) return;
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: secondaryColor,
                                title: Text("Rincian Nota #${r['id']}"),
                                content: details.isEmpty
                                    ? const Text(
                                        "Tidak ada rincian item (Input Manual).",
                                      )
                                    : SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: details
                                              .map(
                                                (d) => ListTile(
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                  title: Text(
                                                    d['nama_barang'],
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    "${d['qty']} x Rp${d['harga_satuan']}",
                                                    style: const TextStyle(
                                                      color: Colors.white54,
                                                    ),
                                                  ),
                                                  trailing: Text(
                                                    "Rp${d['subtotal']}",
                                                    style: const TextStyle(
                                                      color: Colors.greenAccent,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text("Tutup"),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: secondaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r['keterangan'] == ""
                                            ? "Nota #${r['id']}"
                                            : r['keterangan'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        DateFormat(
                                          'dd MMM yyyy',
                                        ).format(DateTime.parse(r['tanggal'])),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "- Rp${r['total_belanja']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 18,
                                            color: Colors.white24,
                                          ),
                                          onPressed: () =>
                                              _showEntryDialog(item: r),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            size: 18,
                                            color: Colors.redAccent.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                          onPressed: () async {
                                            await DatabaseHelper.instance
                                                .hapusBelanja(r['id']);
                                            _loadData();
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
