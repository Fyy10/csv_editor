import 'dart:convert';
import 'dart:io';
import 'package:csv/csv_settings_autodetection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';

class EditPage extends StatefulWidget {
  const EditPage({super.key});

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  List<List<dynamic>> _data = [];
  String? filePath;

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CSV File Editor"),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _pickFile,
                child: const Text("Select File"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  if (filePath == null) {
                    showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                              title: const Text('File path is empty'),
                              content: const Text(
                                  'Please select a .csv file before saving'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, 'OK'),
                                  child: const Text('OK'),
                                )
                              ],
                            ));
                  } else {
                    _saveFile(filePath!);
                  }
                },
                child: const Text("Save File"),
              ),
              const SizedBox(width: 10),
              Text('File Path: ${filePath ?? ''}'),
            ],
          ),
          Expanded(
            child: _data.isNotEmpty
                ? Scrollbar(
                    thumbVisibility: true,
                    controller: _verticalController,
                    child: SingleChildScrollView(
                      controller: _verticalController,
                      scrollDirection: Axis.vertical,
                      child: Scrollbar(
                        thumbVisibility: true,
                        controller: _horizontalController,
                        child: SingleChildScrollView(
                          controller: _horizontalController,
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: _data[0]
                                .map((header) =>
                                    DataColumn(label: Text(header.toString())))
                                .toList(),
                            rows: _data.sublist(1).map((row) {
                              return DataRow(
                                cells: row.map((cell) {
                                  return DataCell(
                                    Text(cell.toString()),
                                    showEditIcon: true,
                                    onTap: () {
                                      _editCell(row, cell);
                                    },
                                  );
                                }).toList(),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  )
                : const Center(child: Text('Please select a .csv file')),
          ),
        ],
      ),
    );
  }

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null) return;
    filePath = result.files.single.path!;
    final input = File(filePath!).openRead();
    const eolDetector = FirstOccurrenceSettingsDetector(eols: ['\r\n', '\n']);
    final fields = await input
        .transform(utf8.decoder)
        .transform(const CsvToListConverter(fieldDelimiter: ',', csvSettingsDetector: eolDetector))
        .toList();
    setState(() {
      _data = fields;
    });
  }

  void _editCell(List<dynamic> row, dynamic cell) async {
    final TextEditingController controller =
        TextEditingController(text: cell.toString());
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Cell'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter new value'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newValue != null) {
      setState(() {
        final index = row.indexOf(cell);
        row[index] = newValue;
      });
    }
  }

  void _saveFile(String path) async {
    if (_data.isEmpty) return;

    final csvData = const ListToCsvConverter().convert(_data);
    final file = File(path);

    await file.writeAsString(csvData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File saved to $path')),
    );
  }
}
