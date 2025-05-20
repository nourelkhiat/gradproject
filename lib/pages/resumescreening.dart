import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class ResumeScreeningPage extends StatefulWidget {
  const ResumeScreeningPage({super.key});

  @override
  State<ResumeScreeningPage> createState() => _ResumeScreeningPageState();
}

class _ResumeScreeningPageState extends State<ResumeScreeningPage> {
  List<Map<String, dynamic>> resumes = [];

  Future<void> uploadResume() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb,
    );

    if (result != null) {
      String fileName = result.files.single.name;
      Uint8List? fileBytes = result.files.single.bytes;

      // Fallback for non-web
      if (fileBytes == null && !kIsWeb) {
        final filePath = result.files.single.path!;
        final file = io.File(filePath);
        fileBytes = await file.readAsBytes();
      }

      if (fileBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to read file.')),
        );
        return;
      }

      // ✅ Use correct backend IP from your Flask output (e.g. 192.168.1.24)
      var uri = Uri.parse('http://192.168.1.24:5000/upload_resume');
      var request = http.MultipartRequest('POST', uri);

      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
      request.fields['job_description'] = 'Software Developer'; // Or get from user input

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final parsed = json.decode(responseData);

        setState(() {
          resumes.add({
            'name': parsed['filename'] ?? 'Unknown',
            'score': parsed['score'] ?? 0.0,
            'status': 'Pending',
            'role': 'Candidate',
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload successful. Score: ${parsed['score']}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Resume Screening")),
      body: Column(
        children: [
          ElevatedButton.icon(
            onPressed: uploadResume,
            icon: const Icon(Icons.upload),
            label: const Text("Upload Resume"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: resumes.length,
              itemBuilder: (context, index) {
                var resume = resumes[index];
                return ListTile(
                  title: Text(resume['name']),
                  subtitle: Text('Score: ${resume['score']}'),
                  trailing: Text(resume['status']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
