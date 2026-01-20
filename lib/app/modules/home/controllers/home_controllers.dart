import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeController extends GetxController {
  var selectedDate = 7.obs;
  var selectedCategory = 'Sarapan'.obs;
  var isLoading = false.obs;
  var foodItems = [].obs; // Observable list to hold food items from API

  @override
  void onInit() {
    super.onInit();
    // fetchFoodItems(); // Disabled - no backend API available
  }

  // Fetch food items from the API (disabled for now)
  Future<void> fetchFoodItems() async {
    try {
      isLoading.value = true;
      // API call disabled - no backend available
      // final response =
      //     await http.get(Uri.parse('http://192.168.1.3:3000/api/data'));
      // if (response.statusCode == 200) {
      //   final List<dynamic> data = json.decode(response.body);
      //   foodItems.assignAll(data); // Assign API data to foodItems
      // } else {
      //   Get.snackbar('Error', 'Failed to fetch food items');
      // }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
