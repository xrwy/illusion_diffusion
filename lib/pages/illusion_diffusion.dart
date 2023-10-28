import 'package:flutter/material.dart';
import 'package:illusion_diffusion/api/api.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

class IllusionDiffusion extends StatefulWidget {
  const IllusionDiffusion({super.key});

  @override
  State<StatefulWidget> createState() {
    return IllusionDiffusionState();
  }
}

class IllusionDiffusionState extends State<IllusionDiffusion> {
  final TextEditingController _userPrompt = TextEditingController();

  String userPrompt = "";
  File? pingImageResult;
  Uint8List? _convertedBytes;
  double sliderValue = 1;
  final ScrollController _controller = ScrollController();

  circularProgressIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 60.0),
      child: const CircularProgressIndicator(),
    );
  }

  snapShotHasError(snapshot) {
    return Center(
        child: Container(
          margin: const EdgeInsets.only(bottom: 35.0, right: 29.0, left: 29.0),
      padding: const EdgeInsets.only(top: 20.0, right: 45.0, bottom: 20.0, left: 45.0),
      decoration: const BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.all(Radius.circular(8.0))),
      child: Container(
        margin: null,
        child: Column(
          children: [
            const Text(
              'Error',
              style: TextStyle(
                  fontSize: 22.0,
                  color: Colors.white,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10.0),
            Text(
              '${snapshot.error}',
              style: const TextStyle(fontSize: 20.0, color: Colors.white),
            )
          ],
        ),
      ),
    ));
  }

  Future selectImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final File imageTemp = File(image.path);
      setState(() => pingImageResult = imageTemp);

      _convertImageToGrayScale();
    } on PlatformException catch (e) {
      throw Exception(e.toString());
    }
  }

  _convertImageToGrayScale() async {
    if (pingImageResult != null) {
      File imageFile = File(pingImageResult!.path);
      Uint8List bytesList = await imageFile.readAsBytes();

      final ByteData data = ByteData.sublistView(bytesList);
      List<int> bytes = data.buffer.asUint8List();
      img.Image? image = img.decodeImage(Uint8List.fromList(bytes));
      img.grayscale(image!);
      _convertedBytes = Uint8List.fromList(img.encodeJpg(image));

      setState(() {}); // Ekranı yeniden inşa et
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Illusion Diffusion',
          style: TextStyle(fontSize: 21.0),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add_alert),
            tooltip: 'Show Snackbar',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('This is a snackbar')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            tooltip: 'Go to the next page',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute<void>(
                builder: (BuildContext context) {
                  return Scaffold(
                    appBar: AppBar(
                      title: const Text('Next Page'),
                      backgroundColor: Colors.blueAccent,
                    ),
                    body: const Center(
                      child: Text(
                        'This is the next page',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  );
                },
              ));
            },
          ),
        ],
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        toolbarHeight: 72.0,
      ),
      body: Container(
          margin: const EdgeInsets.only(top: 30.0),
          child: Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                controller: _controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    pingImageResult != null && _convertedBytes != null
                        ? Container(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              children: [
                                Align(
                                    alignment: Alignment.center,
                                    child: Image.memory(
                                      _convertedBytes!,
                                      height: 350.0,
                                    )),
                                const SizedBox(
                                  height: 10.0,
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(),
                    Align(
                        alignment: Alignment.center,
                        heightFactor: 1.0,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            foregroundColor:
                                MaterialStateProperty.all<Color>(Colors.white),
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.blueAccent),
                            shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(7.0)),
                            )),
                            padding: MaterialStateProperty.resolveWith<
                                EdgeInsetsGeometry>(
                              (Set<MaterialState> states) {
                                return const EdgeInsets.all(15);
                              },
                            ),
                          ),
                          onPressed: () {
                            selectImage();
                          },
                          child: const Text(
                            'Select Image',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 18.0,
                            ),
                          ),
                        )),
                    const SizedBox(
                      height: 40.0,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: _userPrompt,
                        style: const TextStyle(fontSize: 18.0),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.only(
                              top: 24.0, right: 12.0, bottom: 24.0, left: 12.0),
                          labelText: "Prompt:",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 50.0,
                    ),
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Controlnet Conditioning Scale',
                        style: TextStyle(
                            fontSize: 17.0, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Slider(
                      value: sliderValue,
                      min: 1,
                      max: 4,
                      label: sliderValue.toStringAsFixed(2),
                      onChanged: (double value) {
                        setState(() {
                          sliderValue = value;
                        });
                      },
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                          'Selected Value : ${sliderValue.toStringAsFixed(2)}'),
                    ),
                    const SizedBox(
                      height: 50.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Align(
                            alignment: Alignment.center,
                            child: ElevatedButton(
                                style: ButtonStyle(
                                  foregroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.white),
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.green),
                                  shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                      const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(7.0)),
                                  )),
                                  padding: MaterialStateProperty.resolveWith<
                                      EdgeInsetsGeometry>(
                                    (Set<MaterialState> states) {
                                      return const EdgeInsets.all(15);
                                    },
                                  ),
                                ),
                                onPressed: () {
                                  if (_userPrompt.text.isNotEmpty) {
                                    setState(() {
                                      userPrompt = _userPrompt.text;
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content:
                                          Text('The Input Field is Mandatory'),
                                      backgroundColor: Colors.red,
                                    ));
                                  }
                                },
                                child: const Text("Create Image",
                                    style: TextStyle(fontSize: 18)))),
                        Align(
                            alignment: Alignment.center,
                            child: ElevatedButton(
                                style: ButtonStyle(
                                  foregroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.white),
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.red),
                                  shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                      const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(7.0)),
                                  )),
                                  padding: MaterialStateProperty.resolveWith<
                                      EdgeInsetsGeometry>(
                                    (Set<MaterialState> states) {
                                      return const EdgeInsets.all(15);
                                    },
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    userPrompt = "";
                                    pingImageResult = null;
                                    _convertedBytes = null;
                                    sliderValue = 1;
                                  });
                                },
                                child: const Text("Clear All Fields",
                                    style: TextStyle(fontSize: 18)))),
                      ],
                    ),
                    const SizedBox(
                      height: 30.0,
                    ),
                    userPrompt.isNotEmpty &&
                            pingImageResult != null &&
                            _convertedBytes != null
                        ? FutureBuilder<String>(
                            future: Api.makePostRequest(
                                _convertedBytes!,
                                userPrompt,
                                pingImageResult!,
                                sliderValue.toStringAsFixed(2)),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 70.0),
                                    child: circularProgressIndicator(),
                                  ),
                                );
                              } else if (snapshot.hasError) {
                                return Align(
                                    alignment: Alignment.center,
                                    child: snapShotHasError(snapshot));
                              } else if (!snapshot.hasData) {
                                return Container(
                                  margin: const EdgeInsets.all(16.0),
                                  child: const Text("No Data"),
                                );
                              } else if (snapshot.data!.endsWith(".png") ||
                                  snapshot.data!.endsWith(".jpeg") ||
                                  snapshot.data!.endsWith(".bmp") ||
                                  snapshot.data!.endsWith(".psd")) {
                                return Container(
                                    padding: const EdgeInsets.all(18.0),
                                    child: Align(
                                        alignment: Alignment.center,
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(top: 30.0),
                                          child: Image.network(
                                            snapshot.data!,
                                          ),
                                        )));
                              } else {
                                return Align(
                                    alignment: Alignment.center,
                                    child: Text("ergfergre"));
                              }
                            })
                        : const SizedBox(),
                  ],
                ),
              ))),
    );
  }
}
