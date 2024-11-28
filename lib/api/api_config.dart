class ApiConfig {
  // Base URL for your API
  static const String authBaseUrl = "http://192.168.0.100:94/api/v1";
  static const String taskBaseUrl = "http://192.168.0.100:90/api/v1";

  // Authentication-related endpoints
  static const String loginEndpoint = "$authBaseUrl/login";
  static const String instanceEndpoint = "$authBaseUrl/instances";

  static const String companyEndpoint = "$taskBaseUrl/user/companies";
}
