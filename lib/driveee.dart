import 'dart:io' as io;
import 'dart:async';

import 'package:path_provider/path_provider.dart';

import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:googleapis/drive/v3.dart' as gApi;
import 'package:googleapis_auth/googleapis_auth.dart' as gAuth;

import "package:http/http.dart" as http;

const drivefileName = 'hexFile';
const fileMime = 'application/vnd.google-apps.file';

// const fileMime = 'application/vnd.google-apps.document';
// const fileMime = 'text/plain';

const appDataFolderName = 'AvexTest';
const folderMime = 'application/vnd.google-apps.folder';

//http client
class AuthClient extends http.BaseClient {
  final http.Client _baseClient;
  final Map<String, String> _headers;

  AuthClient(this._baseClient, this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _baseClient.send(request);
  }
}

class GoogleDriveClient {
  late String _accessToken;
  late GoogleSignInAccount _googleAccount;
  late gApi.DriveApi _driveApi;

  GoogleDriveClient._create(
      GoogleSignInAccount googleAccount, String accessToken) {
    _googleAccount = googleAccount;
    _accessToken = accessToken;
  }

  static Future<GoogleDriveClient> create(
      GoogleSignInAccount googleAccount, String accessToken) async {
    var component = GoogleDriveClient._create(googleAccount, accessToken);
    await component._initGoogleDriveApi();

    return component;
  }


  Future<void> _initGoogleDriveApi() async {
    final gAuth.AccessCredentials credentials = gAuth.AccessCredentials(
      gAuth.AccessToken(
        'Bearer',
        _accessToken,
        DateTime.now().toUtc().add(const Duration(days: 365)),
      ),
      null,
      [gApi.DriveApi.driveAppdataScope],
    );
    var client = gAuth.authenticatedClient(http.Client(), credentials);
    var localAuthHeaders = await _googleAccount.authHeaders;
    var headers = localAuthHeaders;
    var authClient = AuthClient(client, headers);
    _driveApi = gApi.DriveApi(authClient);
  }

Future<String?> _createFileOnGoogleDrive(String fileName,
      {String? mimeType,
      String? content,
      List<String> parents = const []}) async {
    gApi.Media? media;

    // Checks if the file already exists on Google Drive.
    // If it does, we delete it here and create a new one.
    var currentFileId = await _getFileIdFromGoogleDrive(fileName);
    if (currentFileId != null) {
      await _driveApi.files.delete(currentFileId);
      print('deleted file');
    }

    if (fileName == drivefileName && content != null) {
      final directory = await getApplicationDocumentsDirectory();
      print('directory ==== $directory');
      var created = io.File("${directory.path}/$fileName");
      created.writeAsString(content);
      var bytes = await created.readAsBytes();
      media = gApi.Media(created.openRead(), bytes.lengthInBytes);
    }

    gApi.File file = gApi.File();
    file.name = fileName;
    file.mimeType = mimeType;
    file.parents = parents;

    // The acual file creation on Google Drive
    final fileCreation = await _driveApi.files.create(file, uploadMedia: media);
    if (fileCreation.id == null) {
      throw PlatformException(
        code: 'Error remoteStorageException',
        message: 'unable to create file on Google Drive',
      );
    }

    print("Created File ID: ${fileCreation.id} on RemoteStorage");

    return fileCreation.id!;
  }

  // Public client API:
  uploadFile(String fileContent) async {
    try {
      String? folderId = await _createFileOnGoogleDrive(appDataFolderName,
          mimeType: folderMime);
      if (folderId != null) {
        print('Entered file creation');
        final fileId = await _createFileOnGoogleDrive(drivefileName,
            content: fileContent, parents: [folderId]);
            final content = await downloadFileToDevice(fileId!);
            print(content);
      }
    } catch (e) {
      print("GoogleDrive, uploadfileContent $e");
    }
  }

  //get id of the file 
  Future<String?> _getFileIdFromGoogleDrive(String fileName) async {
    gApi.FileList found = await _driveApi.files.list(
      q: "name = '$fileName'",
    );
    final files = found.files;
    if (files == null) {
      return null;
    }

    if (files.isNotEmpty) {
      return files.first.id;
    }
    return null;
  }

  Future<String?> downloadFileToDevice(String fileId) async {
    gApi.Media? file = (await _driveApi.files.get(fileId,
        downloadOptions: gApi.DownloadOptions.fullMedia)) as gApi.Media?;
    if (file != null) {
      final directory = await getApplicationDocumentsDirectory();
      final saveFile = io.File('${directory.path}/$drivefileName');
      final first = await file.stream.first;
      saveFile.writeAsBytes(first);
      return saveFile.readAsString();
    }
    return null;
  }
}