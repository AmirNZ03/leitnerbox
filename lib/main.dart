import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as Path;
import 'dart:html' as html;
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const String _title = 'Flutter Stateful Clicker Counter';
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _title,
      theme: ThemeData(
        // useMaterial3: false,
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.
  // This class is the configuration for the state.
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // final now = DateTime.now();
  // final createDate = DateTime
  //     .now(); // یا اگر پروژه قبلاً ذخیره شده بود، از create_date قبلی استفاده کنید
  // final currentDay = now.difference(createDate).inDays;
  final TextEditingController _userNameController = TextEditingController();
  int dayword = 0;
  int score = 1;
  void _exportCsvForWeb(List<List<dynamic>> csvData) {
    final csvBuffer = StringBuffer();

    for (final row in csvData) {
      csvBuffer.writeln(row.map((e) => '"$e"').join(',')); // تبدیل لیست به CSV
    }

    final bytes = utf8.encode(csvBuffer.toString());
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "export.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // List<List<dynamic>> _csvData = [];
  List<List<dynamic>> _selectedItems = [];
  int _selectedWordCount = 10;
  void _saveProjectAsJson() async {
    final TextEditingController _userNameController = TextEditingController();

    String userName = _userNameController.text.trim();
    if (userName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a user name")),
      );
      return;
    }

    Map<String, dynamic> jsonMap = {
      "user_name": userName,
      "create_date": DateTime.now().toIso8601String().split("T")[0],
      // "current_day": currentDay, // ذخیره مقدار currentDay
      "dictionary": {},
      "box": {},
    };

    // پر کردن dictionary
    for (int i = 0; i < _csvData.length; i++) {
      if (_csvData[i].length >= 2) {
        jsonMap["dictionary"]["${i + 1}"] = {
          "word": _csvData[i][0].toString(),
          "translation": _csvData[i][1].toString(),
        };
      }
    }

    // پر کردن box
    for (int i = 0; i < _selectedItems.length; i++) {
      if (_selectedItems[i].length >= 3) {
        jsonMap["box"]["${i + 1}"] = {
          "word": _selectedItems[i][0].toString(),
          "translation": _selectedItems[i][1].toString(),
          "level": _selectedItems[i][2],
          "day": _selectedItems[i].length > 3
              ? _selectedItems[i][3]
              : 0, // اگه day داری
        };
      }
    }

    String jsonString = jsonEncode(jsonMap);

    if (kIsWeb) {
      // برای وب: دانلود فایل JSON
      final bytes = utf8.encode(jsonString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "dictionary_project.json")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // برای اندروید یا دسکتاپ: ذخیره فایل
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Storage permission is required!")),
        );
        return;
      }

      Directory? downloadsDirectory;
      if (Platform.isAndroid) {
        downloadsDirectory = Directory('/storage/emulated/0/Download');
      } else {
        downloadsDirectory = await getDownloadsDirectory();
      }

      if (downloadsDirectory != null) {
        String filePath =
            Path.join(downloadsDirectory.path, 'dictionary_project.json');
        File file = File(filePath);
        await file.writeAsString(jsonString);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Project saved to Downloads ✅")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not access Downloads folder ❌")),
        );
      }
    }
  }

  //final TextEditingController _userNameController = TextEditingController();
  // void _saveProjectAsJson() async {
  //   final TextEditingController _userNameController = TextEditingController();

  //   String userName = _userNameController.text.trim();
  //   if (userName.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Please enter a user name")),
  //     );
  //     return;
  //   }

  //   Map<String, dynamic> jsonMap = {
  //     "user_name": userName,
  //     "create_date": DateTime.now().toIso8601String().split("T")[0],
  //     "dictionary": {},
  //   };
  //   //final TextEditingController _userNameController = TextEditingController();
  //   for (int i = 0; i < _csvData.length; i++) {
  //     if (_csvData[i].length >= 2) {
  //       jsonMap["dictionary"]["${i + 1}"] = {
  //         "word": _csvData[i][0].toString(),
  //         "translation": _csvData[i][1].toString(),
  //       };
  //     }
  //   }

  //   String jsonString = jsonEncode(jsonMap);

  //   if (kIsWeb) {
  //     // برای وب: دانلود فایل JSON
  //     final bytes = utf8.encode(jsonString);
  //     final blob = html.Blob([bytes]);
  //     final url = html.Url.createObjectUrlFromBlob(blob);
  //     final anchor = html.AnchorElement(href: url)
  //       ..setAttribute("download", "dictionary_project.json")
  //       ..click();
  //     html.Url.revokeObjectUrl(url);
  //   } else {
  //     // برای اندروید یا دسکتاپ: ذخیره فایل
  //     var status = await Permission.storage.request();
  //     if (!status.isGranted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Storage permission is required!")),
  //       );
  //       return;
  //     }

  //     Directory? downloadsDirectory;
  //     if (Platform.isAndroid) {
  //       downloadsDirectory = Directory('/storage/emulated/0/Download');
  //     } else {
  //       downloadsDirectory = await getDownloadsDirectory();
  //     }

  //     if (downloadsDirectory != null) {
  //       String filePath =
  //           Path.join(downloadsDirectory.path, 'dictionary_project.json');
  //       File file = File(filePath);
  //       await file.writeAsString(jsonString);

  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Project saved to Downloads ✅")),
  //       );
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Could not access Downloads folder ❌")),
  //       );
  //     }
  //   }
  // }

  // void _saveData() async {
  //   Map<String, dynamic> jsonMap = {
  //     "box": {},
  //   };
  //   //final TextEditingController _userNameController = TextEditingController();
  //   for (int i = 0; i < _selectedItems.length; i++) {
  //     if (_selectedItems[i].length >= 2) {
  //       jsonMap["box"]["${i + 1}"] = {
  //         "word": _selectedItems[i][0].toString(),
  //         "translation": _selectedItems[i][1].toString(),
  //         "level":_selectedItems[i][2],
  //       };
  //     }
  //   }

  //   String jsonString = jsonEncode(jsonMap);

  //   if (kIsWeb) {
  //     // برای وب: دانلود فایل JSON
  //     final bytes = utf8.encode(jsonString);
  //     final blob = html.Blob([bytes]);
  //     final url = html.Url.createObjectUrlFromBlob(blob);
  //     final anchor = html.AnchorElement(href: url)
  //       ..setAttribute("download", "dictionary_project.json")
  //       ..click();
  //     html.Url.revokeObjectUrl(url);
  //   } else {
  //     // برای اندروید یا دسکتاپ: ذخیره فایل
  //     var status = await Permission.storage.request();
  //     if (!status.isGranted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Storage permission is required!")),
  //       );
  //       return;
  //     }

  //     Directory? downloadsDirectory;
  //     if (Platform.isAndroid) {
  //       downloadsDirectory = Directory('/storage/emulated/0/Download');
  //     } else {
  //       downloadsDirectory = await getDownloadsDirectory();
  //     }

  //     if (downloadsDirectory != null) {
  //       String filePath =
  //           Path.join(downloadsDirectory.path, 'dictionary_project.json');
  //       File file = File(filePath);
  //       await file.writeAsString(jsonString);

  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Project saved to Downloads ✅")),
  //       );
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Could not access Downloads folder ❌")),
  //       );
  //     }
  //   }
  // }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text('CSV imported successfully ✅'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // void exportCsvForWeb(List<List<dynamic>> csvData) {
  //   String csv = const ListToCsvConverter().convert(csvData);

  //   final bytes = utf8.encode(csv);
  //   final blob = html.Blob([bytes]);
  //   final url = html.Url.createObjectUrlFromBlob(blob);
  //   final anchor = html.AnchorElement(href: url)
  //     ..setAttribute("download", "exported_words.csv")
  //     ..click();
  //   html.Url.revokeObjectUrl(url);
  // }
  int day = 0;
  void _exportCsv() async {
    // گرفتن مجوز ذخیره‌سازی
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Storage permission is required!")),
      );
      return;
    }

    // آماده‌سازی داده CSV
    String csv = const ListToCsvConverter().convert(_csvData);

    // گرفتن مسیر دانلودها
    Directory? downloadsDirectory;
    if (Platform.isAndroid) {
      downloadsDirectory = Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      // برای iOS از getApplicationDocumentsDirectory استفاده کنید
      downloadsDirectory = await getApplicationDocumentsDirectory();
    }

    if (downloadsDirectory != null) {
      String filePath =
          Path.join(downloadsDirectory.path, 'exported_words.csv');
      File file = File(filePath);

      await file.writeAsString(csv);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("File exported ✅")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not access directory ❌")),
      );
    }
  }

  Color _boxColor = Colors.white; // رنگ اولیه باکس (سفید)
  bool isEnabled = false;
  Color _idcolor = Colors.black;
  Color _wordcolor = Colors.black;
  bool correctClicked = false;
  bool wrongClicked = false;
  bool isclick = true;
  bool iswrong = true;
  bool showanswer = false;
  bool showbox = false;
  void _setAnswer() {
    // تغییر رنگ باکس به سبز
    setState(() {
      showanswer = true;
    });
  }

  void _setCorrect() {
    setState(() {
      // تغییر رنگ باکس به سبز
      _boxColor = Colors.green;
      _idcolor = Colors.green;
      _wordcolor = Colors.green;
      isDayIncreased = true;
    });
  }

  void _setWrong() {
    setState(() {
      isDayIncreased = false;
      // تغییر رنگ باکس به سبز
      _boxColor = Colors.red;
      _idcolor = Colors.red;
      _wordcolor = Colors.red;
    });
  }

  void _setnext() {
    setState(() {
      // تغییر رنگ باکس به سبز
      _boxColor = Colors.white;
    });
  }

  bool isDayIncreased = false;
  void _setcorrcet() {
    setState(() {
      // تغییر رنگ باکس به سبز
      isclick = false;
    });
  }

  // void saveProject(String userName, Map<int, Map<String, dynamic>> dictionary) {
  //   DateTime now = DateTime.now();
  //   String createDate = "${now.year}-${now.month}-${now.day}";

  //   Map<String, dynamic> projectData = {
  //     "user_name": _userNameController,
  //     "create_date": createDate,
  //     "dictionary": dictionary,
  //   };

  //   // تبدیل Map به JSON
  //   String jsonData = jsonEncode(projectData);

  //   // ذخیره فایل JSON
  //   File file = File('project.json');
  //   file.writeAsStringSync(jsonData);
  //   print("Project saved to project.json");
  // }

  void loadProject() async {
    try {
      File file = File('project.json');
      String jsonData = await file.readAsString();
      Map<String, dynamic> projectData = jsonDecode(jsonData);

      String userName = projectData["user_name"];
      String createDate = projectData["create_date"];

      Map<String, dynamic> rawDictionary = projectData["dictionary"];
      Map<int, Map<String, dynamic>> dictionary = {
        for (var key in rawDictionary.keys)
          int.parse(key): Map<String, dynamic>.from(rawDictionary[key])
      };

      print("Project loaded. User: $userName, Create Date: $createDate");

      setState(() {
        _userNameController.text = userName;
        _csvData = dictionary.entries.map((entry) {
          final item = entry.value;
          return [
            item["word"],
            item["translation"],
            item["level"],
          ];
        }).toList();
      });
    } catch (e) {
      print("Error loading project: $e");
    }
  }

  List<String> _words = [];
  String? _selectedOption;
  int _currentIndex = 0;

  List<List<dynamic>> _csvData = [];

  List<List<dynamic>> _subdata = [];

  // int count = int.parse(_selectedOption!);
// if (count > _csvData.length) {
//   count = _csvData.length;
// }

//  List<List<dynamic>> selectedItems = _csvData.sublist(0, count);

  //void _addbox() {
  //  int count = int.parse(_selectedOption!);
  //List<List<dynamic>> selectedItems =
  //  _csvData.sublist(0, count); // گرفتن 10 تا اول
  //print("Before removeRange: csvData length = ${_csvData.length}");
  //csvData.removeRange(0, count);
  //print(
  //  "After removeRange: csvData length = ${_csvData.length}"); // حذف 10 تا از لیست اصلی
  //}

  final List<String> _options = ['10', '20', '50', '100', 'all'];
  Future<void> _pickAndReadCsv() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );

    if (result != null) {
      // در صورتی که فایل انتخاب شد، بررسی می‌کنیم که آیا پلتفرم وب است یا خیر
      if (kIsWeb) {
        // برای وب باید از `bytes` استفاده کنیم
        final bytes = result.files.single.bytes;
        if (bytes != null) {
          String fileContent = utf8.decode(bytes);
          List<List<dynamic>> csvTable =
              CsvToListConverter().convert(fileContent);
          setState(() {
            _csvData = csvTable; // ذخیره داده‌های CSV
          });
          _showSuccessDialog();
        }
      } else {
        // در موبایل از `path` برای خواندن فایل استفاده می‌کنیم
        File file = File(result.files.single.path!);
        String fileContent = await file.readAsString();
        List<List<dynamic>> csvTable =
            CsvToListConverter().convert(fileContent);
        setState(() {
          _csvData = csvTable; // ذخیره داده‌های CSV
        });
      }
    } else {
      print('No file selected');
    }
  }

  void _nextRow() {
    setState(() {
      if (_currentIndex < _csvData.length - 1) {
        _currentIndex++;
      }
      isDayIncreased = false;
    });
  }

  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _meaningController = TextEditingController();
  final TextEditingController _addwordController = TextEditingController();
  final TextEditingController _addmeaningController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  // تابعی برای نمایش مدال و اضافه کردن کلمات
  void _showAddWordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add a Word'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _addwordController,
                decoration: const InputDecoration(
                  labelText: 'Word',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _addmeaningController,
                decoration: const InputDecoration(
                  labelText: 'Meaning',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // بستن مدال
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // اضافه کردن کلمه به لیست
                if (_addwordController.text.isNotEmpty &&
                    _addmeaningController.text.isNotEmpty) {
                  setState(() {
                    _csvData.add(
                        [_addwordController.text, _addmeaningController.text]);
                  });
                  _wordController.clear();
                  _meaningController.clear();
                  Navigator.of(context).pop(); // بستن مدال
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _deleteWord() {
    if (_currentIndex >= 0 && _currentIndex < _selectedItems.length) {
      String wordToDelete =
          _selectedItems[_currentIndex][0]; // فرض بر اینه که ستون اول، کلمه‌ست

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm Delete'),
            content: Text(
                "Are you sure you want to delete the word '$wordToDelete'?"),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(); // بستن دیالوگ
                },
              ),
              TextButton(
                child: Text('Yes'),
                onPressed: () {
                  setState(() {
                    _selectedItems.removeAt(_currentIndex);
                    // _csvData.removeAt(_currentIndex);
                    // اگه خواستی بعد از حذف بره ردیف اول یا -1 بشه
                    _currentIndex = _selectedItems.isNotEmpty ? 0 : -1;
                  });
                  Navigator.of(context).pop(); // بستن دیالوگ
                },
              ),
            ],
          );
        },
      );
    }
  }

//  void _addWord() {
//    _csvData.push(_meaningController,_wordController);
//  }
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ردیف دکمه‌ها
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 120, // عرض دلخواه دکمه
                      child: ElevatedButton(
                        onPressed: _pickAndReadCsv,
                        child: Text('Import CSV'),
                      ),
                    ),
                    SizedBox(width: 10),
                    SizedBox(
                      width: 120, // عرض دلخواه دکمه
                      child: ElevatedButton(
                        onPressed: () {
                          _exportCsv();
                          // exportCsvForWeb(_csvData);
                        },
                        child: Text('Export CSV'),
                      ),
                    ),
                    SizedBox(width: 10),
                    SizedBox(
                      width: 80, // عرض دلخواه دکمه
                      child: ElevatedButton(
                        onPressed: _showAddWordDialog,
                        child: Text(
                          'Add Items',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10), // فاصله بین ردیف‌ها
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // saveProject(userName,_csvData);
                        // //  saveProject(userName, _csvData);
                        _saveProjectAsJson();
                      },
                      child: Text('Save Project'),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        loadProject();
                      },
                      child: Text('Load project'),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Text("User Name:"),
                    SizedBox(width: 10), // فاصله بین متن و فیلد
                    SizedBox(
                      width: 90,
                      child: TextField(
                        controller: _userNameController,
                        decoration: InputDecoration(
                          // labelText: 'نام خود را وارد کنید',
                          border: OutlineInputBorder(),
                          isDense: true, // برای جمع‌وجورتر بودن
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    SizedBox(
                      width: 120, // عرض دلخواه دکمه
                      child: ElevatedButton(
                        onPressed: () {
                          //_addbox();
                          if (_selectedOption != null) {
                            int count;

                            if (_selectedOption == 'all') {
                              count = _csvData.length; // همه آیتم‌ها
                            } else {
                              count = int.parse(_selectedOption!);
                            }

                            print("Selected value: $count");
                            //int count = int.parse(_selectedOption!);
                            // اینجا استفاده کن:
                            List<List<dynamic>> selectedItems =
                                _csvData.sublist(0, count);
                            for (int i = 0; i < selectedItems.length; i++) {
                              selectedItems[i].add(score); // مثلا score = 1
                            }
                            _csvData.removeRange(0, count);
                            // _selectedItems[_currentIndex][2] = score;
                            setState(() {
                              _selectedItems.addAll(selectedItems);
                              ; // ذخیره برای نمایش یا استفاده بعدی
                              _currentIndex = 0;
                            });
                          } else {
                            print("هیچ مقداری انتخاب نشده");
                          }
                        },
                        child: Text('Add to Box'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: _selectedOption,
                      hint: const Text('10'),
                      items: _options.map((String option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedOption = newValue;
                        });
                      },
                    ),
                    SizedBox(width: 5),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          showbox = true;
                        });
                      },
                      child: Text('Start'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text("Words left: ${_csvData.length}"),
                    SizedBox(width: 13),
                    Text("Words in box:${_selectedItems.length}"),
                    SizedBox(width: 13),
                    Text("Day:11"),
                  ],
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Text("Today's words:${_selectedItems.length}"),
                  ],
                ),
                SizedBox(height: 10),
                if (showbox)
                  Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            "Word ID: ${_currentIndex + 1}",
                            style: TextStyle(color: _idcolor),
                          ),
                          SizedBox(width: 150),
                          Text(
                            "Word Level:${_selectedItems[_currentIndex][2]}",
                            style: TextStyle(color: _wordcolor),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Container(
                        height: 130,
                        width: double.infinity,
                        padding: EdgeInsets.all(16.0),
                        color: _boxColor,
                        child: ListView.builder(
                          itemCount: 1, // فقط یک ردیف نمایش داده می‌شود
                          itemBuilder: (context, index) {
                            // اطمینان حاصل می‌کنیم که `_currentIndex` معتبر است
                            if (_currentIndex >= 0 &&
                                _currentIndex < _selectedItems.length) {
                              return Container(
                                margin: EdgeInsets.only(bottom: 10.0),
                                padding: EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment
                                      .center, // برای چپ‌چین کردن
                                  children: [
                                    Text(
                                      _selectedItems[_currentIndex][0]
                                          .toString(), // کلمه
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    if (showanswer)
                                      Text(
                                        _selectedItems[_currentIndex][1]
                                            .toString(), // معنی
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            } else {
                              return Container(); // اگر ایندکس معتبر نیست، چیزی نمایش داده نمی‌شود
                            }
                          },
                        ),
                      ),
                      SizedBox(height: 5),
                      Column(
                        children: [
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  isEnabled = true;
                                  if (!isDayIncreased) {
                                    // بررسی اگر روز قبلاً افزایش نیافته باشد
                                    _setCorrect(); // تابع مربوط به حالت درست بودن پاسخ
                                    setState(() {
                                      score++; // افزایش day یک بار
                                      isDayIncreased =
                                          true; // تنظیم پرچم بعد از افزایش day
                                    });
                                  }
                                  wrongClicked
                                      ? null // اگر دکمه wrong کلیک شده، غیرفعاله
                                      : () {
                                          setState(() {
                                            _setCorrect();
                                            score++;
                                            isDayIncreased = true;
                                            correctClicked = true;
                                            wrongClicked = false;
                                            isEnabled =
                                                true; // برای فعال شدن دکمه Next
                                          });
                                        };
                                },
                                child: Text(
                                  'Correct',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  {
                                    setState(() {
                                      isDayIncreased = false;
                                      _setWrong();
                                      day = 0;
                                      wrongClicked = true;
                                      correctClicked = false;
                                      isEnabled =
                                          true; // برای فعال شدن دکمه Next
                                    });
                                  }
                                  ;
                                  // اگر دکمه correct کلیک شده، غیرفعاله
                                },
                                child: Text(
                                  'Wrong',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: isEnabled
                                    ? () {
                                        _nextRow();
                                        _setnext();
                                        setState(() {
                                          isEnabled =
                                              false; // بعد از رفتن به کلمه بعدی، غیرفعال شود
                                        });
                                        // setState(() {
                                        //   isclick =
                                        //       true; // بعد از رفتن به کلمه بعدی، غیرفعال شود
                                        // });
                                        // setState(() {
                                        //   iswrong =
                                        //       true; // بعد از رفتن به کلمه بعدی، غیرفعال شود
                                        // });
                                        setState(() {
                                          day = 0;
                                        });
                                        setState(() {
                                          _idcolor = Colors.black;
                                          _wordcolor = Colors.black;
                                          correctClicked = false;
                                          wrongClicked = false;
                                        });
                                        setState(() {
                                          showanswer =
                                              false; // باید داخل setState باشد
                                        });
                                      }
                                    : null,
                                child: Text(
                                  'Next',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  _wordController.text =
                                      _selectedItems[_currentIndex][0];
                                  _meaningController.text =
                                      _selectedItems[_currentIndex][1];
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Edit a Word'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(
                                              controller: _wordController,
                                              decoration: const InputDecoration(
                                                labelText: 'Word',
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            TextField(
                                              controller: _meaningController,
                                              decoration: const InputDecoration(
                                                labelText: 'Meaning',
                                              ),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(); // بستن مدال
                                            },
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              // اضافه کردن کلمه به لیست
                                              if (_wordController
                                                      .text.isNotEmpty &&
                                                  _meaningController
                                                      .text.isNotEmpty) {
                                                setState(() {
                                                  _csvData.add([
                                                    _wordController.text,
                                                    _meaningController.text
                                                  ]);
                                                });
                                                _wordController.clear();
                                                _meaningController.clear();
                                                Navigator.of(context)
                                                    .pop(); // بستن مدال
                                              }
                                            },
                                            child: ElevatedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _selectedItems[
                                                            _currentIndex][0] =
                                                        _wordController
                                                            .text; // کلمه جدید
                                                    _selectedItems[
                                                            _currentIndex][1] =
                                                        _meaningController
                                                            .text; // معنی جدید
                                                  });
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text("Edit")),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Text(
                                  'Edit',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10), // فاصله بین دو ردیف
                          Row(
                            children: [
                              SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  _deleteWord();
                                },
                                child: Text('Delete',
                                    style: TextStyle(fontSize: 10)),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    showanswer =
                                        true; // باید داخل setState باشد
                                  });
                                },
                                child: Text('Show answer',
                                    style: TextStyle(fontSize: 10)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ادامه محتوا
          // Expanded(
          //   child: Center(
          //     child: Text('محتوای صفحه'),
          //   ),
          // ),
          SizedBox(height: 15),
          SizedBox(
            height: 100,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: 10,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(show: true),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true),
                barGroups: [
                  BarChartGroupData(x: 1, barRods: [
                    BarChartRodData(y: 8, colors: [Colors.orange]),
                  ]),
                  BarChartGroupData(x: 2, barRods: [
                    BarChartRodData(y: 6, colors: [Colors.green]),
                  ]),
                  BarChartGroupData(x: 3, barRods: [
                    BarChartRodData(y: 9, colors: [Colors.blue]),
                  ]),
                  BarChartGroupData(x: 4, barRods: [
                    BarChartRodData(y: 7, colors: [Colors.red]),
                  ]),
                  BarChartGroupData(x: 5, barRods: [
                    BarChartRodData(y: 7, colors: [Colors.purple]),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
