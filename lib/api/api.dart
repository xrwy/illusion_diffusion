import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class Api {
  static const String apiUrl = "https://api.replicate.com/v1/predictions";
  static const String apiToken = "r8_bsr2q6wH1j8vchHqnNeNFfACErbZiEM1RrGzJ";

  static const api_KEY = "54c71b7361b4c5c6d495d474cfe9b378";

  static Future<Map<String, dynamic>?> uploadImageToImgbb(
      File imagePath) async {
    final url = Uri.parse("https://api.imgbb.com/1/upload");
    final request = http.MultipartRequest('POST', url)
      ..fields['key'] = api_KEY
      ..fields['expiration'] = "600"
      ..files.add(await http.MultipartFile.fromPath('image', imagePath.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
        print("Image uploaded!");
        return {
          "url": jsonResponse['data']['url'],
          "delete_url": jsonResponse['data']['delete_url'],
        };
      } else {
        print("Image upload failed.");
        print(response.reasonPhrase);
        return null;
      }
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  static Future<File> saveUint8ListToFile(Uint8List bytes, String fileName) async {
    // Uygulamanın belgeler klasörünü al
    //Directory appDocDir = await getApplicationDocumentsDirectory();
    String filePath = fileName;

    // Dosya oluştur ve byte verisini yaz
    return File(filePath).writeAsBytes(bytes);
  }



  static Future<String> makePostRequest(
      Uint8List convertedBytes, String userPrompt, File pingImageResult) async {
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Token $apiToken",
    };

    try {
      Uint8List myData = convertedBytes;
      File myFile = await saveUint8ListToFile(myData, pingImageResult.path);


      var response = await Api.uploadImageToImgbb(myFile);

      if (response != "" || response != null) {
        final data = {
          "version":
          "3c64e669051f9b358e748c8e2fb8a06e64122a9ece762ef133252e2c99da77c1",
          "input": {
            "prompt": userPrompt,
            "negative_prompt":"ugly, disfigured, low quality, blurry, nsfw",
            "num_inference_steps":40,
            "guidance_scale":7.5,
            "seed":1057727382,
            "num_outputs":1,
            "image": response?["url"],
            "controlnet_conditioning_scale":1,
            "border":1,
            "qrcode_background":"gray"
          }
        };

        try {
          final response = await http.post(
            Uri.parse(apiUrl),
            headers: headers,
            body: json.encode(data),
          );

          if (response.statusCode == 201) {
            final predictionId = json.decode(response.body)['id'];
            final getUrl = "$apiUrl/$predictionId";

            while (true) {
              final checkResponse =
              await http.get(Uri.parse(getUrl), headers: headers);
              final status = json.decode(checkResponse.body)['status'];

              if (status == "succeeded") {
                final imageUrl = json.decode(checkResponse.body)['output'];
                print("Resim URL'si: $imageUrl");

                return imageUrl[0];
              } else if (status == "failed") {
                throw Exception("Resim yüklenirken bir hata oluştu.");
              }

              await Future.delayed(const Duration(seconds: 2));
            }
          } else {
            throw Exception(
                "İstek başarısız oldu. Durum kodu: ${response.statusCode}");
          }
        } catch (e) {
          if (e is SocketException) {
            throw Exception("İnternet bağlantınızı kontrol edin.");
          } else {
            throw Exception("Bir hata oluştu. $e");
          }
        }
      }else {
        throw Exception("Hatalı");
      }
    } catch (e) {

      throw Exception(e.toString());
    }
  }
}