import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // IMPORT BARU
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
    const StockPage(),
    const ChatbotPage(),
    const TransactionPage(),
    const ReportPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? "Manajemen Stok"
              : _selectedIndex == 1
              ? "Asisten AI"
              : "Kasir Transaksi",
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

// COMPONENT: SIDE MENU (Drawer)
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
                const Icon(Icons.engineering, size: 48, color: primaryColor),
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
            title: "Daftar Stok",
            icon: Icons.inventory_2_outlined,
            press: () => onIndexChanged(0),
            selected: selectedIndex == 0,
          ),
          DrawerListTile(
            title: "Asisten AI",
            icon: Icons.chat_bubble_outline,
            press: () => onIndexChanged(1),
            selected: selectedIndex == 1,
          ),
          DrawerListTile(
            title: "Catat Transaksi",
            icon: Icons.point_of_sale,
            press: () => onIndexChanged(2),
            selected: selectedIndex == 2,
          ),
          DrawerListTile(
            title: "Laporan Penjualan",
            icon: Icons.summarize_outlined,
            press: () => onIndexChanged(3),
            selected: selectedIndex == 3,
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

// --- HALAMAN DAFTAR STOK ---
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

  void _fetchData() async {
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
    final photo = await picker.pickImage(source: source, imageQuality: 50);
    if (photo != null) {
      setState(() => _refImage = File(photo.path));
    }
  }

  void _showEntryDialog({Map<String, dynamic>? item}) {
    if (item != null) {
      _nameController.text = item['nama']
          .toString(); // FIX: Pastikan jadi string
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
              const Text(
                "Daftar Stok",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showEntryDialog(),
                icon: const Icon(Icons.add),
                label: const Text("Tambah Baru"),
              ),
            ],
          ),
          const SizedBox(height: defaultPadding),
          Expanded(
            child: ListView.builder(
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
                              // FIX: Pastikan path dibaca sebagai String
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
        ],
      ),
    );
  }
}

// --- HALAMAN CHATBOT & KAMERA ---
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
          "Halo bos! Asisten udah pakai server premium nih. Mau cek harga apa hari ini?",
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
      final allData = await DatabaseHelper.instance.cariBarang("");
      String dbContext = allData
          .map((e) => "${e['nama']}: Rp${e['harga']}")
          .join(", ");

      String prompt =
          '''
      Kamu adalah asisten bengkel 'NF Garage'.
      Data stok saat ini: [$dbContext].
      ''';

      if (userText.isNotEmpty) {
        prompt += '\nPesan/Caption dari User: "$userText".';
      }

      List<Map<String, dynamic>> contentArray = [];

      if (imageToSend != null) {
        if (userText.isEmpty) {
          prompt += '''
          \nUser melampirkan foto barang tanpa teks pesan.
          TUGASMU:
          1. Identifikasi nama sparepart/barang apa yang ada di dalam foto ini.
          2. Cari tahu harganya HANYA berdasarkan [Data stok saat ini] yang diberikan di atas.
          3. Jawab dengan gaya montir bengkel. Beri tahu harganya jika ada. Jika barang tidak ada di data stok, bilang "stok belum terdaftar bos".
          4. DILARANG merespon dengan format JSON atau menyuruh menyimpan data baru.
          ''';
        } else {
          prompt += '''
          \nUser melampirkan gambar beserta caption teks.
          1. Jika caption menyuruh SIMPAN/CATAT/MASUKKAN, ekstrak nama dan harga ke JSON: {"action": "simpan", "nama": "Nama", "harga": 0}
          2. Jika caption BERTANYA harga, jawab berdasarkan Data stok.
          ''';
        }

        final bytes = await imageToSend.readAsBytes();
        final base64Image = base64Encode(bytes);

        contentArray.add({"type": "text", "text": prompt});
        contentArray.add({
          "type": "image_url",
          "image_url": {"url": "data:image/jpeg;base64,$base64Image"},
        });
      } else {
        prompt +=
            "\nJawab pertanyaan user berdasarkan Data stok dengan gaya montir bengkel.";
        contentArray.add({"type": "text", "text": prompt});
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
          "temperature": 0.20,
          "top_p": 0.70,
          "stream": false,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String aiResponse = responseData['choices'][0]['message']['content'];

        if (aiResponse.contains('"action":') &&
            aiResponse.contains('"simpan"')) {
          try {
            String rawJson = aiResponse.substring(
              aiResponse.indexOf('{'),
              aiResponse.lastIndexOf('}') + 1,
            );
            final data = jsonDecode(rawJson);

            // FIX: Parsing tipe data numerik agar tidak error
            int hargaBarang = (data['harga'] as num).toInt();

            await DatabaseHelper.instance.tambahBarang(
              data['nama'].toString(),
              hargaBarang,
            );

            setState(() {
              _messages.insert(0, {
                "text":
                    "Sip bos! Data ${data['nama']} (Rp$hargaBarang) otomatis masuk ke daftar stok.",
                "isUser": false,
                "image": null,
              });
            });
          } catch (e) {
            setState(
              () => _messages.insert(0, {
                "text":
                    "Waduh, gagal mengekstrak data JSON bos. Coba ulangi instruksinya.",
                "isUser": false,
                "image": null,
              }),
            );
          }
        } else {
          setState(
            () => _messages.insert(0, {
              "text": aiResponse,
              "isUser": false,
              "image": null,
            }),
          );
        }
      } else {
        setState(
          () => _messages.insert(0, {
            "text": "Server Error (${response.statusCode}): ${response.body}",
            "isUser": false,
            "image": null,
          }),
        );
      }
    } catch (e) {
      setState(
        () => _messages.insert(0, {
          "text": "Koneksi ke NVIDIA terputus bos. Error: $e",
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
                          // FIX: Gunakan "as File" agar Dart tidak mengira ini dynamic
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

// --- HALAMAN KASIR TRANSAKSI (MULTIPLE IMAGES) ---
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

  @override
  void initState() {
    super.initState();
    _messages.add({
      "text":
          "Mode Kasir aktif! Kirim foto barang/struk, sebutin juga biaya jasanya (kalo ada).",
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
                  // FIX: Gunakan tipe nullable List<XFile>? untuk versi image_picker tertentu
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

    if (userText.isEmpty && imagesToSend.isEmpty) return;

    setState(() {
      // Jika user tidak ngetik, kasih tahu di UI kalau dia kirim gambar
      _messages.insert(0, {
        "text": userText.isEmpty ? "(Mengirim Gambar)" : userText,
        "isUser": true,
        "images": imagesToSend,
      });
      _controller.clear();
      _selectedImages.clear();
      _isLoading = true;
    });

    try {
      final allData = await DatabaseHelper.instance.cariBarang("");
      // Format daftar diperjelas agar AI mudah mencocokkan harga
      String dbContext = allData
          .map((e) => "- ${e['nama']} (Harga: Rp${e['harga']})")
          .join("\n");

      // PROMPT SUPER KETAT ANTI-NGARANG
      String prompt =
          '''
Kamu adalah mesin sistem kasir. Tugasmu HANYA membaca data dan merespon dengan JSON.

DAFTAR HARGA STOK RESMI:
$dbContext

ATURAN MUTLAK (JIKA DILANGGAR TRANSAKSI GAGAL):
1. Lihat barang apa yang ada di foto atau yang diminta pada pesan user.
2. CARI nama barang tersebut di "DAFTAR HARGA STOK RESMI" di atas.
3. HARGA WAJIB DIAMBIL DARI DAFTAR DI ATAS. Dilarang keras menggunakan harga dari luar daftar!
4. Jika beli lebih dari satu (misal "2 busi"), kalikan harganya.
5. Jika barang yang difoto TIDAK ADA di "DAFTAR HARGA STOK RESMI", dilarang membuat JSON. Jawab dengan teks: "Barang tidak ditemukan di database stok".
6. Jika ada teks biaya jasa (misal: "jasa 20rb"), ekstrak angkanya ke "biaya_jasa". Jika tidak disebutkan, isi 0.
7. Jawab HANYA menggunakan format JSON murni.

CONTOH JSON:
{"action": "transaksi", "deskripsi": "Oli MPX", "biaya_jasa": 20000, "total_barang": 50000}

PESAN DARI USER:
"${userText.isEmpty ? '[User hanya melampirkan foto tanpa teks]' : userText}"
''';

      List<Map<String, dynamic>> contentArray = [];
      contentArray.add({"type": "text", "text": prompt});

      if (imagesToSend.isNotEmpty) {
        for (var file in imagesToSend) {
          final bytes = await file.readAsBytes();
          final base64Image = base64Encode(bytes);
          contentArray.add({
            "type": "image_url",
            "image_url": {"url": "data:image/jpeg;base64,$base64Image"},
          });
        }
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
          "temperature":
              0.0, // NOL MUTLAK: Mematikan total kemampuan AI untuk menebak/berimajinasi
          "top_p": 0.1, // Fokus tinggi pada kecocokan teks
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

            int bJasa = (data['biaya_jasa'] as num?)?.toInt() ?? 0;
            int tBarang = (data['total_barang'] as num?)?.toInt() ?? 0;
            int grandTotal = bJasa + tBarang;

            await DatabaseHelper.instance.catatTransaksi(
              data['deskripsi'].toString(),
              bJasa,
              tBarang,
            );

            setState(() {
              _messages.insert(0, {
                "text":
                    "✅ Transaksi Berhasil Dicatat!\nBarang: ${data['deskripsi']}\nTotal Barang: Rp$tBarang\nBiaya Jasa: Rp$bJasa\nGrand Total: Rp$grandTotal",
                "isUser": false,
                "images": <File>[],
              });
            });
          } catch (e) {
            setState(
              () => _messages.insert(0, {
                "text": "Gagal menyimpan transaksi bos. Format data salah.",
                "isUser": false,
                "images": <File>[],
              }),
            );
          }
        } else {
          // Jika AI membalas teks (misal: "Barang tidak ditemukan")
          setState(
            () => _messages.insert(0, {
              "text": aiResponse,
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

              // FIX: Aman dari tipe dynamic saat narik list gambar
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
                    maxWidth: MediaQuery.of(context).size.width * 0.80,
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
                    hintText: "Contoh: Jasa ganti 20rb",
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

  void _loadData() async {
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

  // FUNGSI EXPORT EXCEL
  Future<void> _exportToExcel() async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Laporan Penjualan'];
    excel.delete('Sheet1');

    // Header
    sheet.appendRow([
      TextCellValue("No"),
      TextCellValue("Tanggal"),
      TextCellValue("Deskripsi"),
      TextCellValue("Biaya Barang"),
      TextCellValue("Biaya Jasa"),
      TextCellValue("Grand Total"),
    ]);

    for (var i = 0; i < _reports.length; i++) {
      var r = _reports[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(
          DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(r['tanggal'])),
        ),
        TextCellValue(r['deskripsi']),
        IntCellValue(r['total_barang']),
        IntCellValue(r['biaya_jasa']),
        IntCellValue(r['grand_total']),
      ]);
    }

    var fileBytes = excel.save();
    var directory = await getTemporaryDirectory();
    String filePath =
        "${directory.path}/Laporan_Penjualan_${DateTime.now().millisecondsSinceEpoch}.xlsx";
    File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes!);

    await Share.shareXFiles([
      XFile(filePath),
    ], text: 'Laporan Penjualan NF Garage');
  }

  void _showEditDialog(Map<String, dynamic> item) {
    final deskController = TextEditingController(text: item['deskripsi']);
    final jasaController = TextEditingController(
      text: item['biaya_jasa'].toString(),
    );
    final barangController = TextEditingController(
      text: item['total_barang'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: secondaryColor,
        title: const Text("Edit Transaksi"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: deskController,
              decoration: const InputDecoration(labelText: "Deskripsi"),
            ),
            TextField(
              controller: barangController,
              decoration: const InputDecoration(labelText: "Total Barang"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: jasaController,
              decoration: const InputDecoration(labelText: "Biaya Jasa"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.updateTransaksi(
                item['id'],
                deskController.text,
                int.parse(jasaController.text),
                int.parse(barangController.text),
              );
              Navigator.pop(context);
              _loadData();
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Column(
        children: [
          // HEADER & FILTER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Riwayat Transaksi",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        builder: (context, child) => Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: primaryColor,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setState(() => _selectedDateRange = picked);
                        _loadData();
                      }
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
          // TABEL DATA
          Expanded(
            child: ListView.builder(
              itemCount: _reports.length,
              itemBuilder: (context, index) {
                final r = _reports[index];
                return Container(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['deskripsi'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
                              "Barang: Rp${r['total_barang']} | Jasa: Rp${r['biaya_jasa']}",
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
                                  color: Colors.redAccent.withOpacity(0.5),
                                ),
                                onPressed: () async {
                                  await DatabaseHelper.instance.hapusTransaksi(
                                    r['id'],
                                  );
                                  _loadData();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
