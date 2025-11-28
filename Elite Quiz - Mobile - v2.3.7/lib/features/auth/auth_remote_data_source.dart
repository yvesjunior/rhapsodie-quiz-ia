import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as fcm;
import 'package:flutterquiz/core/constants/api_exception.dart';
import 'package:flutterquiz/core/constants/constants.dart';
import 'package:flutterquiz/features/auth/models/auth_providers_enum.dart';
import 'package:flutterquiz/utils/api_utils.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  //to addUser
  Future<Map<String, dynamic>> addUser({
    required String firebaseId,
    required String type,
    required String name,
    String? profile,
    String? mobile,
    String? email,
    String? referCode,
    String? friendCode,
    String? appLanguage,
  }) async {
    try {
      final fcmToken = await getFCMToken();
      //body of post request
      final body = <String, String>{
        firebaseIdKey: firebaseId,
        typeKey: type,
        nameKey: name,
        emailKey: email ?? '',
        profileKey: profile ?? '',
        mobileKey: mobile ?? '',
        fcmIdKey: fcmToken,
        friendCodeKey: friendCode ?? '',
        'app_language': ?appLanguage,
      };

      log('🔵 [API] Calling addUser: $addUserUrl');
      log('🔵 [API] Body: ${body.toString()}');
      final response = await http
          .post(Uri.parse(addUserUrl), body: body)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              log('❌ [API] addUser timeout after 30 seconds');
              throw const ApiException(errorCodeNoInternet);
            },
          );
      log('✅ [API] addUser response status: ${response.statusCode}');
      log('🔵 [API] addUser response body: ${response.body}');
      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseJson['error'] as bool) {
        log('❌ [API] addUser error: ${responseJson['message']}');
        throw ApiException(responseJson['message'].toString());
      }
      log('✅ [API] addUser success');
      return responseJson['data'] as Map<String, dynamic>;
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on ApiException {
      rethrow;
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  //to addUser
  Future<String> getJWTTokenOfUser({
    required String firebaseId,
    required String type,
  }) async {
    try {
      //body of post request
      final body = <String, String>{firebaseIdKey: firebaseId, typeKey: type};

      log('🔵 [API] Calling getJWTTokenOfUser: $addUserUrl');
      log('🔵 [API] Body: ${body.toString()}');
      final response = await http
          .post(Uri.parse(addUserUrl), body: body)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              log('❌ [API] getJWTTokenOfUser timeout after 30 seconds');
              throw const ApiException(errorCodeNoInternet);
            },
          );
      log('✅ [API] getJWTTokenOfUser response status: ${response.statusCode}');
      log('🔵 [API] getJWTTokenOfUser response body: ${response.body}');
      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseJson['error'] as bool) {
        log('❌ [API] getJWTTokenOfUser error: ${responseJson['message']}');
        throw ApiException(responseJson['message'].toString());
      }
      final data = responseJson['data'] as Map<String, dynamic>;
      log('✅ [API] getJWTTokenOfUser success');
      return data['api_token'].toString();
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on ApiException {
      rethrow;
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  Future<bool> isUserExist(String firebaseId) async {
    try {
      log('🔵 [API] Checking if user exists: $firebaseId');
      final body = {firebaseIdKey: firebaseId};
      final response = await http
          .post(
            Uri.parse(checkUserExistUrl),
            body: body,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              log('❌ [API] isUserExist timeout after 30 seconds');
              throw const ApiException(errorCodeNoInternet);
            },
          );
      log('✅ [API] isUserExist response status: ${response.statusCode}');
      log('🔵 [API] isUserExist response body: ${response.body}');
      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseJson['error'] as bool) {
        throw ApiException(responseJson['message'].toString());
      }

      return responseJson['message'].toString() == errorCodeUserExists;
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on ApiException {
      rethrow;
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  Future<void> updateFcmId({
    required String firebaseId,
    required bool userLoggingOut,
  }) async {
    try {
      final fcmId = userLoggingOut
          ? ''
          : await fcm.FirebaseMessaging.instance.getToken() ?? '';
      final body = {
        fcmIdKey: fcmId,
        firebaseIdKey: firebaseId.isNotEmpty ? firebaseId : 'firebaseId',
      };
      final response = await http.post(
        Uri.parse(updateFcmIdUrl),
        body: body,
        headers: await ApiUtils.getHeaders(),
      );
      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

      /// Ignore Error when user is logging out. as old token would be expired and
      /// you will always get 129 something went wrong error.
      if (!userLoggingOut && responseJson['error'] as bool) {
        throw ApiException(responseJson['message'].toString());
      }
    } on ApiException {
      rethrow;
    } on Exception {
      rethrow;
    }
  }

  //signIn using phone number
  Future<UserCredential> signInWithPhoneNumber({
    required String verificationId,
    required String smsCode,
  }) async {
    final phoneAuthCredential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(
      phoneAuthCredential,
    );
    return userCredential;
  }

  //SignIn user will accept AuthProvider (enum)
  Future<UserCredential> signInUser(
    AuthProviders authProvider, {
    String? email,
    String? password,
    String? verificationId,
    String? smsCode,
  }) async {
    try {
      return switch (authProvider) {
        AuthProviders.gmail => await signInWithGoogle(),
        AuthProviders.mobile => await signInWithPhoneNumber(
          verificationId: verificationId!,
          smsCode: smsCode!,
        ),
        AuthProviders.email => await signInWithEmailAndPassword(
          email!,
          password!,
        ),
        _ => await signInWithApple(),
      };
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on FirebaseAuthException catch (e) {
      throw ApiException(firebaseErrorCodeToNumber(e.code));
    } on ApiException {
      rethrow;
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  //signIn using google account
  Future<UserCredential> signInWithGoogle() async {
    try {
      log('🔵 [Google Login] Step 1: Initializing Google Sign In...');
      await _googleSignIn.initialize();
      log('✅ [Google Login] Step 1: Google Sign In initialized');
      
      log('🔵 [Google Login] Step 2: Authenticating with Google...');
      final googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );
      log('✅ [Google Login] Step 2: Google authentication successful');
      
      log('🔵 [Google Login] Step 3: Getting Google auth tokens...');
      final googleAuth = googleUser.authentication;
      final authClient = await googleUser.authorizationClient
          .authorizationForScopes(['email', 'profile']);
      log('✅ [Google Login] Step 3: Got auth tokens');

      log('🔵 [Google Login] Step 4: Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: authClient?.accessToken,
        idToken: googleAuth.idToken,
      );
      log('✅ [Google Login] Step 4: Firebase credential created');

      log('🔵 [Google Login] Step 5: Signing in with Firebase...');
      final result = await _firebaseAuth.signInWithCredential(credential);
      log('✅ [Google Login] Step 5: Firebase sign in successful. UID: ${result.user?.uid}');
      
      return result;
    } catch (e, stackTrace) {
      log('❌ [Google Login] Error: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<UserCredential> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oAuthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(
        oAuthCredential,
      );

      if (userCredential.additionalUserInfo!.isNewUser ||
          userCredential.user!.displayName == null) {
        final user = userCredential.user!;
        final givenName = credential.givenName ?? '';
        final familyName = credential.familyName ?? '';

        await user.updateDisplayName('$givenName $familyName');
        await user.reload();
      }

      return userCredential;
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      log('🔵 [Email Login] Step 1: Signing in with email/password...');
      //sign in using email
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      log('✅ [Email Login] Step 1: Firebase authentication successful. UID: ${userCredential.user?.uid}');
      // Email verification check removed - users can login without verifying email
      return userCredential;
    } on FirebaseAuthException catch (e, stackTrace) {
      log('❌ [Email Login] Firebase error: ${e.code} - ${e.message}', error: e, stackTrace: stackTrace);
      throw ApiException(firebaseErrorCodeToNumber(e.code));
    } on Exception catch (e, stackTrace) {
      log('❌ [Email Login] General error: $e', error: e, stackTrace: stackTrace);
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  Future<void> resetPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  static Future<String> getFCMToken() async {
    try {
      return await fcm.FirebaseMessaging.instance.getToken() ?? '';
    } on Exception catch (_) {
      return '';
    }
  }

  //create user account
  Future<void> signUpUser(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      //verify email address
      await userCredential.user!.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw ApiException(firebaseErrorCodeToNumber(e.code));
    } on SocketException {
      throw const ApiException(errorCodeNoInternet);
    } on Exception {
      throw const ApiException(errorCodeDefaultMessage);
    }
  }

  Future<void> signOut(AuthProviders? authProvider) async {
    await _firebaseAuth.signOut();
    if (authProvider == AuthProviders.gmail) {
      await _googleSignIn.initialize();
      await _googleSignIn.signOut();
    }
  }
}
