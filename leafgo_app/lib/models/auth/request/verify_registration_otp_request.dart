class VerifyRegistrationOtpRequest {
  final String email;
  final String otpCode;

  const VerifyRegistrationOtpRequest({
    required this.email,
    required this.otpCode,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'otpCode': otpCode,
  };
}
