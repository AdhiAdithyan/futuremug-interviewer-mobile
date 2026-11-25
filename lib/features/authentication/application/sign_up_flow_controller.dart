import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:futuremug_interviewer/features/authentication/data/auth_repository.dart';

/// What the sign-up screens share: the phone being verified, the OTP session
/// and, once verified, the token that allows creating credentials.
///
/// Kept in a provider rather than passed as route `extra`, so it survives
/// rebuilds and deep links.
class SignUpFlowState {
  const SignUpFlowState({
    this.countryCode,
    this.phoneNumber,
    this.challenge,
    this.verificationToken,
  });

  final String? countryCode;
  final String? phoneNumber;
  final OtpChallenge? challenge;
  final String? verificationToken;

  bool get hasOtpSession => challenge != null;
  bool get isPhoneVerified => verificationToken != null;

  String get displayPhone => '${countryCode ?? ''} ${phoneNumber ?? ''}'.trim();
}

class SignUpFlowController extends Notifier<SignUpFlowState> {
  @override
  SignUpFlowState build() => const SignUpFlowState();

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> sendOtp({
    required String countryCode,
    required String phoneNumber,
  }) async {
    final challenge = await _repository.sendOtp(
      countryCode: countryCode,
      phoneNumber: phoneNumber,
    );
    state = SignUpFlowState(
      countryCode: countryCode,
      phoneNumber: phoneNumber,
      challenge: challenge,
    );
  }

  Future<void> resendOtp() async {
    final code = state.countryCode;
    final phone = state.phoneNumber;
    if (code == null || phone == null) return;
    await sendOtp(countryCode: code, phoneNumber: phone);
  }

  Future<void> verifyOtp(String otpCode) async {
    final challenge = state.challenge;
    if (challenge == null) {
      throw StateError('verifyOtp called before sendOtp');
    }
    final token = await _repository.verifyOtp(
      otpSessionId: challenge.otpSessionId,
      otpCode: otpCode,
    );
    state = SignUpFlowState(
      countryCode: state.countryCode,
      phoneNumber: state.phoneNumber,
      challenge: challenge,
      verificationToken: token,
    );
  }

  void reset() => state = const SignUpFlowState();
}

final signUpFlowProvider =
    NotifierProvider<SignUpFlowController, SignUpFlowState>(
  SignUpFlowController.new,
);
