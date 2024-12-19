class ApiConfig {
  // Base URL for your API
  static const String authBaseUrl = "http://192.168.0.100:94/api/v1";
  static const String taskBaseUrl = "http://192.168.0.100:90/api/v1";

  // Authentication-related endpoints
  static const String loginEndpoint = "$authBaseUrl/login";
  static const String instanceEndpoint = "$authBaseUrl/instances";

  static const String companies = "/api/v1/user/companies";
  static const String companyCases = "/api/v1/user/company/cases";
  static const String companyCaseTypes = "/api/v1/user/company/casetypes";
  static const String casePanels = "/api/v1/user/company/case/panels";
  static const String casePanelTaskInfo = "/api/v1/user/company/case/panel/task/info";
  static const String casePanelInfo = "/api/v1/user/company/case/panel/info";
  static const String panelTaskInfo = "/api/v1/user/company/case/panel/task/info/save";
  static const String caseTasks = "/api/v1/user/company/case/tasks";
  static const String panelTaskAdd = "/api/v1/user/company/case/panel/task/add";
  // static const String additionalDetails = "/api/v1/user/company/case/panel/task/add";

}
