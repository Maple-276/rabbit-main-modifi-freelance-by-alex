/// Model for handling authentication API responses
class AuthResponseModel {
  final bool success;
  final String? message;
  final String? token;
  final String? tempToken;
  final int? userId;
  final Map<String, dynamic>? data;
  
  /// Creates an API response model with required success flag and optional fields
  AuthResponseModel({
    required this.success,
    this.message,
    this.token,
    this.tempToken,
    this.userId,
    this.data,
  });
  
  /// Creates an AuthResponseModel from JSON data
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      success: json['success'] ?? false,
      message: json['message'],
      token: json['token'],
      tempToken: json['temp_token'],
      userId: json['user_id'],
      data: json['data'],
    );
  }
  
  /// Converts the model to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'token': token,
      'temp_token': tempToken,
      'user_id': userId,
      'data': data,
    };
  }
} 