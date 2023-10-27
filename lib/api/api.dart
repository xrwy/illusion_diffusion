import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:io';


class Api {
  static const String apiUrl = "https://api.replicate.com/v1/predictions";
  static const String apiToken = "r8_D4p5z9rd57dpuM4x9C7QONjiL0pJeLI3hcLcP";

  static const apiKEY = "54c71b7361b4c5c6d495d474cfe9b378";

  static File? filePathWriteAsBytes;
  static String filePath = "";

  static Future<Map<String, dynamic>?> uploadImageToImgbb(
      String imagePath) async {
    final url = Uri.parse("https://api.imgbb.com/1/upload");
    final request = http.MultipartRequest('POST', url)
      ..fields['key'] = apiKEY
      ..fields['expiration'] = "600"
      ..files.add(await http.MultipartFile.fromPath('image', imagePath));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
        return {
          "url": jsonResponse['data']['url'],
          "delete_url": jsonResponse['data']['delete_url'],
        };
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<String?> saveUint8ListToFile(Uint8List bytes, String fileName) async {
    filePath = fileName;
    try {
      filePathWriteAsBytes = await File(filePath).writeAsBytes(bytes);
      return null;
    }catch (e) {
      return e.toString();
    }
  }


  static Future<String> makePostRequest(
      Uint8List convertedBytes, String userPrompt, File pingImageResult, String sliderValue) async {
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Token $apiToken",
    };

    try {
      Uint8List myData = convertedBytes;
      String? myFile = await saveUint8ListToFile(myData, pingImageResult.path);

      if(myFile != null){
        throw Exception(myFile.toString());
      }


      var response = await Api.uploadImageToImgbb(filePath);

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
            "controlnet_conditioning_scale": double.parse(sliderValue),
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
                return imageUrl[0];
              } else if (status == "failed") {
                throw Exception("An error occurred while loading the image.");
              }

              await Future.delayed(const Duration(seconds: 2));
            }
          } else {
            throw Exception(
                "The request failed. Status code: ${response.statusCode}");
          }
        } catch (e) {
          if (e is SocketException) {
            throw Exception("Check your internet connection.");
          } else {
            throw Exception("Something went wrong. $e");
          }
        }
      }else {
        throw Exception("Error");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}