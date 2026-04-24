import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const cloudName = "YOUR_CLOUD_NAME";
  static const uploadPreset = "YOUR_UPLOAD_PRESET";

  static Future<String?> uploadImage(File imageFile) async {
    final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    var request = http.MultipartRequest("POST", url);

    request.files.add(
      await http.MultipartFile.fromPath("file", imageFile.path),
    );

    request.fields["upload_preset"] = uploadPreset;

    var response = await request.send();

    if (response.statusCode == 200) {
      var res = await http.Response.fromStream(response);
      var data = jsonDecode(res.body);
      return data["secure_url"];
    } else {
      return null;
    }
  }
}