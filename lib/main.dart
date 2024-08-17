import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:win32/win32.dart';
import 'package:win32_registry/win32_registry.dart';

Directory folder = Directory.current;
List immaz = [];
Future<void> main() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey("number")) {
    prefs.setString("number", "0");
  }

  if (folder.listSync().isNotEmpty) {
    for (var pat in folder.listSync()) {
      if (pat.existsSync() &&
              pat.runtimeType.toString() != "_Directory" &&
              pat.path.split(".").last == "png" ||
          pat.path.split(".").last == "jpeg" ||
          pat.path.split(".").last == "jpg") {
        immaz.add(pat);
      }
    }
  }

  if (!Directory("${folder.path}\\WTChecker\\").existsSync()) {
    Directory("${folder.path}\\WTChecker\\").createSync(recursive: true);
  } else {
    Directory("${folder.path}\\WTChecker\\").deleteSync(recursive: true);
    Directory("${folder.path}\\WTChecker\\").createSync(recursive: true);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WTChecker',
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
            background: Color.fromARGB(255, 36, 36, 36), primary: Colors.red),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'WTChecker'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String postUrl = '';
  bool online = false;
  String thumb = '';
  String lastUrl = '';
  String tempImage = '';
  String number = "0";

  var header = {'User-Agent': 'Walltaker-Checker/'};
  bool setter = true;
  bool isNsfw = true;
  String status = '';
  String setBy = 'Cat';
  bool colorsIconsA = false;
  Map data = {};
  bool setNumber = false;
  TextEditingController numberController = TextEditingController();

  Icon sfw = const Icon(
    Icons.child_friendly,
    color: Colors.red,
  );

  void wallpape(String path) {
    final hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    if (FAILED(hr)) {
      throw WindowsException(hr);
    }

    final wallpaper = DesktopWallpaper.createInstance();
    final wallpaperPath = path;

    wallpaper.setWallpaper(nullptr, wallpaperPath.toNativeUtf16());
  }

  void sfwF() {
    if (isNsfw == false) {
      sfw = const Icon(
        Icons.child_friendly,
        color: Colors.red,
      );
      setState(() {});
      isNsfw = true;
    } else {
      sfw = const Icon(
        Icons.image,
        color: Colors.green,
      );
      setState(() {});
      isNsfw = false;
    }
  }

  void panicF() {
    setState(() {
      status = "Panic";
      setter = false;
      postUrl = "";
      lastUrl = "";
    });

    if (immaz.isNotEmpty) {
      wallpape(immaz.first.path);
    } else {
      wallpape("${folder.path}\\data\\flutter_assets\\image\\default.jpg");
    }
    Timer(const Duration(seconds: 2), () {
      exit(0);
    });
  }

  void stopF() {
    if (setter) {
      setState(() {
        status = "stopped";
        setter = false;
      });
    } else {
      setState(() {
        status = "restart";
        setter = true;
        postUrl = "";
        lastUrl = "";
      });
    }

    if (immaz.isNotEmpty) {
      wallpape(immaz.first.path);
    } else {
      wallpape("${folder.path}\\data\\flutter_assets\\image\\default.jpg");
    }
  }

  void webImage() {
    var md5 = postUrl.toString().split('/')[6];
    md5 = md5.split('.')[0];
    if (postUrl != "null" && postUrl != "") {
      launchUrl(Uri.parse("https://e621.net/posts?tags=md5%3A$md5"));
    }
  }

  void myLink() {
    launchUrl(Uri.parse("https://walltaker.joi.how/links"));
  }

  void webSetter() {
    if (setBy != "null" && setBy != "" && setBy != "Anonimous") {
      launchUrl(Uri.parse("https://walltaker.joi.how/users/$setBy"));
    }
  }

  String? getWallpaperStyle() {
    var da = Registry.openPath(RegistryHive.currentUser,
            path: "Control Panel\\Desktop")
        .getValueAsString('WallpaperStyle');
    return da;
  }

  Widget stoppe() {
    if (setter) {
      return FilledButton(
        onPressed: () {
          stopF();
        },
        child: const Text("Stop"),
      );
    } else {
      return FilledButton(
        onPressed: () {
          stopF();
        },
        child: const Text("Restart"),
      );
    }
  }

  Widget imagge() {
    if (!setNumber) {
      if (postUrl == '' && number != "0") {
        return Expanded(child: Image.asset("image/cat.png"));
      } else if (isNsfw && number != "0") {
        return Expanded(
            child: Image.network(
          thumb,
        ));
      } else {
        return const Expanded(
            child: ColoredBox(
          color: Color.fromARGB(255, 36, 36, 36),
        ));
      }
    }
    return numberSetter();
  }

  Widget numberSetter() {
    return Column(
      children: [
        TextField(
            controller: numberController,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly
            ],
            decoration: const InputDecoration(
                labelText: "Insert your link number",
                icon: Icon(Icons.desktop_windows))),
        const Text(""),
        ElevatedButton(
          child: const Text('Save'),
          onPressed: () {
            setNumber = false;
            if (numberController.text.isNotEmpty) {
              number = numberController.text;
              saveN();
            }
          },
        )
      ],
    );
  }

  Future<void> saveN() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("number", numberController.text);
    setState(() {
      setBy = "Cat";
      status = "Starting";
    });
  }

  void cropF() {
    final hkcu = Registry.currentUser;
    const subkeyName = 'Control Panel\\Desktop';
    final subkey = hkcu.createKey(subkeyName);
    const regSz =
        RegistryValue('WallpaperStyle', RegistryValueType.string, "6");
    subkey.createValue(regSz);
    status = "Setting Crop";
    wallpape(tempImage);
    colorsIconsA = true;
    setState(() {});
  }

  void fitF() {
    final hkcu = Registry.currentUser;
    const subkeyName = 'Control Panel\\Desktop';
    final subkey = hkcu.createKey(subkeyName);
    const regSz =
        RegistryValue('WallpaperStyle', RegistryValueType.string, "10");
    subkey.createValue(regSz);
    wallpape(tempImage);
    status = "Setting Fit";
    colorsIconsA = false;
    setState(() {});
  }

  Widget fitCrop() {
    if (colorsIconsA) {
      return Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.crop,
              color: Colors.red,
            ),
            onPressed: () {
              cropF();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.fit_screen,
              color: Colors.green,
            ),
            onPressed: () {
              fitF();
            },
          ),
        ],
      );
    } else {
      return Row(children: [
        IconButton(
          icon: const Icon(
            Icons.crop,
            color: Colors.green,
          ),
          onPressed: () {
            cropF();
          },
        ),
        IconButton(
          icon: const Icon(
            Icons.fit_screen,
            color: Colors.red,
          ),
          onPressed: () {
            fitF();
          },
        )
      ]);
    }
  }

  /*Future<void> socket() async {
       const linkId = 658;
    const url = 'wss://walltaker.joi.how/cable';

    final channel = WebSocketChannel.connect(Uri.parse(url));

    final subscribeMessage = jsonEncode({
      "command": "subscribe",
      "identifier": jsonEncode({"channel": "LinkChannel", "id": linkId})
    });

    channel.sink.add(subscribeMessage);

    channel.stream.listen((message) {
      print('Received: $message');

      // Handle the incoming messages here
      final data = jsonDecode(message);
      if (data['type'] == 'confirm_subscription') {
        print('Subscription confirmed');

        final announce = jsonEncode({
          "command": "message",
          "identifier": jsonEncode({"channel": "LinkChannel", "id": linkId}),
          "data": jsonEncode({
            "id": linkId,
            "action": "announce_client",
            "client": "Walltaker-Changer/"
          })
        });
        channel.sink.add(announce);
        /*final checker = {
          "command": "message",
          "identifier": jsonEncode({"channel": "LinkChannel", "id": linkId}),
          "data": jsonEncode({"id": linkId, "action": "check"})
        };
        channel.sink.add(checker);*/
      } else if (data['message'] != null && data['type'] != "ping") {
        print(data['message']["post_url"]);
        print('Message data: ${data['message']}');
      }
    }, onDone: () {
      print('Connection closed');
    }, onError: (error) {
      print('Error: $error');
    });

    // actionCable.disconnect();
  }*/

  Future<void> checker() async {
    if (number != "0") {
      try {
        var response = await get(
            Uri.parse('https://walltaker.joi.how/api/links/$number.json'),
            headers: header);
        data = jsonDecode(response.body.toString());
        // ignore: empty_catches
      } catch (e) {}
      if (data['post_url'] != "") {
        postUrl = data['post_url'];
        thumb = data['post_thumbnail_url'];
        if (data['set_by'] != null) {
          setBy = data['set_by'];
        } else {
          setBy = "Anonimous";
        }
        setState(() {
          if (setter) {
            status = "Checking";
          } else {
            status = "Stopped";
          }
        });
      }

      if (postUrl != lastUrl && setter) {
        var style = getWallpaperStyle();
        if (style == "10") {
          colorsIconsA = false;
        } else if (style == "6") {
          colorsIconsA = true;
        }

        tempImage = "${folder.path}\\WTChecker\\${postUrl.split("/").last}";

        //download
        final task = DownloadTask(
            url: postUrl,
            filename: postUrl.split("/").last,
            directory: "${folder.path}\\WTChecker");
        await FileDownloader().download(task);
        wallpape(tempImage);

        lastUrl = postUrl;
        setState(() {
          if (setter) {
            status = "Checking";
          } else {
            status = "Stopped";
          }
        });
      }
    } else {
      setState(() {
        setNumber = true;
        setBy = "nobody";
        status = "link number can't be 0";
      });
    }
  }

  void numberSet() {
    setNumber = true;
    setState(() {});
  }

  Future<void> loadSavedValue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      number = prefs.getString("number")!;
    });
  }

  @override
  void initState() {
    super.initState();
    loadSavedValue().then((value) {
      var style = getWallpaperStyle();
      if (style == "10") {
        colorsIconsA = false;
      } else if (style == "6") {
        colorsIconsA = true;
      }
      checker();
      Timer.periodic(const Duration(seconds: 10), (timer) {
        checker();
      });
    });
//socket();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(""),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TextButton(
                onPressed: () {
                  myLink();
                },
                onLongPress: () {
                  numberSet();
                },
                child: const Row(
                  children: [
                    Icon(Icons.dataset_linked),
                    Text(" My links"),
                  ],
                )),
            fitCrop(),
          ],
        ),
        imagge(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () {
                webSetter();
              },
              child: Text("Set by $setBy"),
            ),
            IconButton(
              icon: const Icon(
                Icons.wallpaper,
                color: Colors.blue,
              ),
              onPressed: () {
                webImage();
              },
            )
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            stoppe(),
            FilledButton(
              onPressed: () {
                panicF();
              },
              child: const Text("Panic"),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    sfwF();
                  },
                  icon: sfw,
                )
              ],
            )
          ],
        ),
        Text(status),
      ],
    )));
  }
}
