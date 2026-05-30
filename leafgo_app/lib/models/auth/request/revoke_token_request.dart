class RevokeTokenRequest {
  final String refreshToken;

  const RevokeTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};
}
