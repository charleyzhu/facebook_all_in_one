class AccessToken {
  final int? expires;
  final String? userId, token;

  final List<String>? declinedPermissions;
  final List<String>? grantedPermissions;

  AccessToken({
    this.declinedPermissions,
    this.grantedPermissions,
    this.userId,
    this.expires,
    this.token,
  });

  factory AccessToken.fromJson(Map<String, dynamic> json) {
    return AccessToken(
      userId: json['userId'] as String,
      expires: json['expires'] as int,
      token: json['token'] as String,
      declinedPermissions: json['declinedPermissions'] != null ? List<String>.from(json['declinedPermissions']) : [],
      grantedPermissions: json['grantedPermissions'] != null ? List<String>.from(json['grantedPermissions']) : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'expires': this.expires,
        'userId': this.userId,
        'token': this.token,
        'grantedPermissions': this.grantedPermissions,
        'declinedPermissions': this.declinedPermissions,
      };
}
