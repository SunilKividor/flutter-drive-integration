import 'dart:io';

import 'package:driveapp/driveee.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as ga;
import 'package:url_launcher/url_launcher.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

const clientId = '573678008824-crjlmicb9prmh5bv4a4bi2en1d9751sd.apps.googleusercontent.com';
final scopes = ['https://www.googleapis.com/auth/drive.file'];
const iosClientId = '573678008824-bffj08jakm74l3k0o0gd7k6j7vnep2tn.apps.googleusercontent.com';
const iosrevId = 'com.googleusercontent.apps.573678008824-bffj08jakm74l3k0o0gd7k6j7vnep2tn';

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

class DriveService {

  GoogleSignInAccount? _currentUser;

final GoogleSignIn googleSignIn = GoogleSignIn(
  // clientId: iosClientId,
  scopes: scopes,
);

Future<void> handleSignIn() async {
  
    try {
      _currentUser = await googleSignIn.signIn();
      final googleSignInAuth = await _currentUser!.authentication;

      final accessToken = googleSignInAuth.accessToken;

    final com =  await GoogleDriveClient.create(_currentUser!, accessToken!);
    await com.uploadFile("This is Avex uploading the hexcode");

      print("accessToken ==== $accessToken");
    } catch (error) {
      print(error.toString());
    }
  }

  Future<void> logout() async {
    await googleSignIn.signOut();
  }
}
