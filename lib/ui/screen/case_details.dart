import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tms/ui/widgets/custom_expansion_tile.dart' as customExpansionTile;
import 'package:http/http.dart' as http;
import 'package:flutter_tms/api/authService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'common/commonService.dart';

class CaseDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const CaseDetailsScreen({Key? key, required this.task}) : super(key: key);

  @override
  _CaseDetailsScreenState createState() => _CaseDetailsScreenState();
}

class _CaseDetailsScreenState extends State<CaseDetailsScreen> {
  String? _appUrl;
  String? _idt;
  List<Map<String, dynamic>> caseInfo = [];
  bool isLoading = true;
  String? _taskAccessToken;
  int? _selectedCompanyId;
  int? _caseId;
  String? jobName;
  String? jobType;
  String? description;
  String? clientName;
  String? clientType;
  List<Map<String, dynamic>> members = [];

  final AuthService _authService = AuthService();
  final commonService _service = commonService();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadSelectedCompanyIdFromPrefs();
    await _initializeData();
    await instance();
  }

  Future<void> _initializeData() async {
    await _loadAuthToken();

    final caseDetails = widget.task;
    _caseId = caseDetails['id'];
    print("_caseId $_caseId");

    if (_idt != null && _idt!.isNotEmpty) {
      await instance();
    } else {
      print('No valid auth token found.');
    }
  }

  Future<void> _loadAuthToken() async {
    try {
      final taskAccessToken = await _authService.getIdt();
      setState(() {
        _idt = taskAccessToken;
      });
    } catch (e) {
      print('Error loading token: $e');
    }
  }

  Future<void> _loadSelectedCompanyIdFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedCompanyId = prefs.getInt('selected_company_id');

    print('selected_company_id: $selectedCompanyId');

    setState(() {
      _selectedCompanyId = selectedCompanyId;
    });
  }

  Future<void> instance() async {
    final instances = await _service.getSavedInstances(); // This method retrieves all instances.
    for (var instance in instances) {
      final domainUrl = instance['domain_url'];
      print("domainUrl $domainUrl");
      if (domainUrl != null) {
        _appUrl = domainUrl;
        await _fetchCasesInfo(domainUrl);
      }
    }
  }

  Future<void> _fetchCasesInfo(String domainUrl) async {
    final taskAccessToken = await _authService.getIdt();
    setState(() {
      _taskAccessToken = taskAccessToken;
    });
    try {
      final String url =
          '$domainUrl/api/v1/user/company/case/info?companyId=$_selectedCompanyId&caseId=$_caseId';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_taskAccessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('url: cases: $url');
      print('response: cases: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final dynamic caseInfoData = responseData['data']['caseInfo'];
        final dynamic membersData = responseData['data']['members'];

        print("caseInfoData $caseInfoData");
        print("membersData $membersData");

        // Extract values using labels
        final jobNameEntry = caseInfoData.firstWhere(
                (element) => element['label'] == 'Job Name',
            orElse: () => null);
        final jobTypeEntry = caseInfoData.firstWhere(
                (element) => element['label'] == 'Job Type',
            orElse: () => null);
        final descriptionEntry = caseInfoData.firstWhere(
                (element) => element['label'] == 'Job Description',
            orElse: () => null);
        final clientNameEntry = caseInfoData.firstWhere(
                (element) => element['label'] == 'Client Name',
            orElse: () => null);

        setState(() {
          // Set fields based on the labels
          jobName = jobNameEntry != null ? jobNameEntry['value'] : 'N/A';
          jobType = jobTypeEntry != null ? jobTypeEntry['value'] : 'N/A';
          description =
          descriptionEntry != null ? descriptionEntry['value'] : 'N/A';
          clientName = clientNameEntry != null ? clientNameEntry['value'] : 'N/A';
          members = List<Map<String, dynamic>>.from(membersData);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('Failed to load case info');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching case info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height; // Get screen height

    double padding = screenWidth * 0.04;
    double fontSizeTitle = screenWidth * 0.040;
    double avatarSize = screenWidth * 0.05; // Avatar size based on screen width

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: Text(
          "Cases Details",
          style: TextStyle(fontSize: fontSizeTitle, fontWeight: FontWeight.bold),
        ),
        elevation: 6.0,
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Job Name
              Container(
                margin: EdgeInsets.symmetric(vertical: screenHeight * 0.00),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: customExpansionTile.ExpansionTile(
                  title: Row(
                    children: <Widget>[
                      Icon(Icons.work, color: Colors.black),
                      SizedBox(width: screenWidth * 0.02),
                      Text('Job Name', style: TextStyle(color: Colors.black)),
                    ],
                  ),
                  children: <Widget>[
                    Container(
                      alignment: Alignment.topLeft,
                      padding: EdgeInsets.only(left:screenWidth * 0.05,bottom: screenWidth * 0.02 ),
                      child: Text(
                        jobName?.isNotEmpty == true ? jobName! : 'No Job Name available', // Safely handle nullable clientName,
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),


              // Job Type
              Container(
                margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: customExpansionTile.ExpansionTile(
                  title: Row(
                    children: <Widget>[
                      Icon(Icons.business_sharp, color: Colors.black),
                      SizedBox(width: screenWidth * 0.02),
                      Text('Job Type', style: TextStyle(color: Colors.black)),
                    ],
                  ),
                  children: <Widget>[
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(left:screenWidth * 0.05,bottom: screenWidth * 0.02 ),
                      child: Text(
                        jobType?.isNotEmpty == true ? jobType! : 'No Job Type available', // Safely handle nullable clientName,
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),


              // Client Name
              Container(
                margin: EdgeInsets.symmetric(vertical: screenHeight * 0.0001),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: customExpansionTile.ExpansionTile(
                  title: Row(
                    children: <Widget>[
                      Icon(Icons.person, color: Colors.black),
                      SizedBox(width: screenWidth * 0.02),
                      Text('Client Name', style: TextStyle(color: Colors.black)),
                    ],
                  ),
                  children: <Widget>[
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(left:screenWidth * 0.05,bottom: screenWidth * 0.02 ),
                      child: Text(
                          clientName?.isNotEmpty == true ? clientName! : 'No Client Name available', // Safely handle nullable clientName,
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),


              // Description box (expandable) with same width as Name
              Container(
                margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: customExpansionTile.ExpansionTile(
                  title: Row(
                    children: <Widget>[
                      Icon(Icons.description, color: Colors.black),
                      SizedBox(width: screenWidth * 0.02),
                      Text('Description', style: TextStyle(color: Colors.black)),
                    ],
                  ),
                  children: <Widget>[
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(left:screenWidth * 0.05,bottom: screenWidth * 0.02 ),
                      child: Text(
                        description?.isNotEmpty == true ? description! : 'No description available', // Fallback if description is empty
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),

              buildExpandableSection(
                title: 'Members',
                icon: Icons.people,
                contentWidget: members.isNotEmpty
                    ? Row(
                  children: members
                      .map((member) => Padding(
                    padding: EdgeInsets.all(4.0),
                    child: CircleAvatar(
                      radius: avatarSize, // Avatar size
                      backgroundColor: Colors.blue, // Avatar background color
                      child: Text(
                        member['name'][0].toUpperCase(), // First letter of name
                        style: TextStyle(
                          color: Colors.white, // Text color inside the avatar
                          fontWeight: FontWeight.bold,
                          fontSize: fontSizeTitle, // Adjust font size
                        ),
                      ),
                    ),
                  ))
                      .toList(),
                )
                    : Text('No members available.'),  // Pass a widget for members
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildExpandableSection({
    required String title,
    required IconData icon,
    String? content,
    Widget? contentWidget,  // Added contentWidget as an optional parameter
  }) {
    final screenHeight = MediaQuery.of(context).size.height; // Get screen height
    return Container(
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.001),
      // margin: EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: customExpansionTile.ExpansionTile(
        title: Row(
          children: [
            Icon(icon, color: Colors.black),
            SizedBox(width: 8),
            Text(title, style: TextStyle(color: Colors.black)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: contentWidget ??
                Text(content ?? '', style: TextStyle(color: Colors.black87)),  // Default to a Text widget if no contentWidget is provided
          ),
        ],
      ),
    );
  }


  Widget buildMembersSection() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: customExpansionTile.ExpansionTile(
        title: Row(
          children: [
            Icon(Icons.group, color: Colors.black),
            SizedBox(width: 8),
            Text('Members', style: TextStyle(color: Colors.black)),
          ],
        ),
        children: members
            .map((member) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                child: Text(
                  member['name']![0],
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(width: 10),
              Text(member['name'] ?? 'Unknown Member'),
              SizedBox(width: 10),
              Text('(${member['roleName']})'),
            ],
          ),
        ))
            .toList(),
      ),
    );
  }
}


