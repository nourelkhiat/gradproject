import 'dart:convert';
import 'dart:typed_data'; // For web file handling
import 'dart:io' as io; // For mobile
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
    // Use FilePicker for both mobile and web
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb, // Important for web to allow file data
    );

    if (result != null) {
      String fileName = result.files.single.name;
      Uint8List? fileBytes = result.files.single.bytes;

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

      // Update this with your actual local IP address for the backend (running Flask)
      var uri = Uri.parse('http://192.168.1.11:5000/upload_resume');
      var request = http.MultipartRequest('POST', uri);

      // Use MultipartFile.fromBytes for Web
      request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));
      request.fields['job_description'] = 'Software Developer'; // Replace dynamically if needed

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
      appBar: AppBar(
        title: const Text("Resume Screening"),
      ),
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
                  title: Text(resume['name']), // Display the resume filename
                  subtitle: Text('Score: ${resume['score']}'), // Display the score
                  trailing: Text(resume['status']), // Optional: You can display 'status' as well
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}