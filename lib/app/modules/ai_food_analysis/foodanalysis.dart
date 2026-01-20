import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../services/food_analysis.dart'; // Pastikan file service sudah sesuai

class FoodAnalysisScreen extends StatefulWidget {
  @override
  _FoodAnalysisScreenState createState() => _FoodAnalysisScreenState();
}

class _FoodAnalysisScreenState extends State<FoodAnalysisScreen> {
  File? _image; // Untuk menyimpan gambar yang dipilih (mobile)
  XFile? _webImage; // Untuk menyimpan gambar di web
  bool _isLoading =
      false; // Untuk menampilkan loading saat analisis berlangsung
  List<Map<String, dynamic>> _nutritionResults = []; // Hasil analisis nutrisi

  /// Fungsi untuk memilih gambar dari galeri dan menganalisis makanan
  Future<void> _pickImageAndAnalyze() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          _webImage = pickedFile;
        } else {
          _image = File(pickedFile.path);
        }
        _isLoading = true; // Tampilkan indikator loading
      });

      try {
        // Analisis makanan dan dapatkan hasil nutrisi
        final results = await analyzeAndFetchNutritionFromXFile(pickedFile);

        // Filter hasil untuk hanya menampilkan yang memiliki confidence > 50
        final filteredResults = results.where((item) {
          return item.containsKey('confidence') &&
              double.tryParse(item['confidence'].toString()) != null &&
              double.tryParse(item['confidence'].toString())! > 50.00;
        }).toList();

        setState(() {
          _nutritionResults =
              filteredResults; // Simpan hasil yang sudah difilter ke state
        });
      } catch (e) {
        // Tampilkan pesan error jika terjadi kesalahan
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      } finally {
        setState(() {
          _isLoading = false; // Sembunyikan indikator loading
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Analisis Gizi Makanan"),
        backgroundColor: Colors.white, // Warna latar belakang app bar
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Kembali ke halaman sebelumnya
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              Color(0xFFE8D1D3),
              Color(0xFFC70039),
            ],
          ),
        ),
        child: Column(
          children: [
            // Disclaimer untuk web browser
            if (kIsWeb)
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[900]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Perhatian: Analisis AI tidak tersedia di web browser karena keterbatasan CORS. Data yang ditampilkan adalah data simulasi untuk testing UI. Untuk analisis AI yang sebenarnya, gunakan aplikasi mobile.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Tampilkan gambar yang dipilih
            if (_image != null || _webImage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: kIsWeb
                      ? Image.network(
                          _webImage!.path,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: Icon(Icons.image, size: 50),
                            );
                          },
                        )
                      : Image.file(
                          _image!,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            const SizedBox(height: 20),
            // Tombol untuk memilih gambar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _pickImageAndAnalyze,
                child: Text("Pilih Gambar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // Warna tombol
                  padding:
                      EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ),

            // Indikator loading
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),

            // Tampilkan hasil analisis
            Expanded(
              child: _nutritionResults.isEmpty
                  ? Center(
                      child: Text(
                        "Belum ada hasil analisis.",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _nutritionResults.length,
                      itemBuilder: (context, index) {
                        final item = _nutritionResults[index];
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          elevation: 4.0,
                          child: ListTile(
                            leading: Icon(Icons.fastfood,
                                color: Colors.red.shade700),
                            title: Text(
                              item.containsKey('name')
                                  ? item['name']
                                  : 'Nama Tidak Ditemukan', // Pastikan key 'name' ada
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.containsKey('error'))
                                  Text(
                                    "Error: ${item['error']}",
                                    style: TextStyle(color: Colors.red),
                                  )
                                else ...[
                                  Text(
                                    item.containsKey('confidence')
                                        ? "Confidence: ${item['confidence']}%"
                                        : 'Confidence Tidak Ditemukan',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    item.containsKey('calories')
                                        ? "Kalori: ${item['calories']} kcal"
                                        : 'Kalori Tidak Ditemukan',
                                  ),
                                  Text(
                                    item.containsKey('protein')
                                        ? "Protein: ${item['protein']} g"
                                        : 'Protein Tidak Ditemukan',
                                  ),
                                  Text(
                                    item.containsKey('fat')
                                        ? "Lemak: ${item['fat']} g"
                                        : 'Lemak Tidak Ditemukan',
                                  ),
                                  Text(
                                    item.containsKey('carbohydrates')
                                        ? "Karbohidrat: ${item['carbohydrates']} g"
                                        : 'Karbohidrat Tidak Ditemukan',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
