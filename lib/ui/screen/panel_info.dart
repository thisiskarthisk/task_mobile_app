import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tms/ui/widgets/custom_expansion_tile.dart' as customExpansionTile;
import 'package:http/http.dart' as http;
import 'package:flutter_tms/api/authService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'common/commonService.dart';


class PanelInfoScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const PanelInfoScreen({Key? key, required this.task}) : super(key: key);

  @override
  _PanelInfoScreenState createState() => _PanelInfoScreenState();
}

class _PanelInfoScreenState extends State<PanelInfoScreen> {
  final TextEditingController _taskNameController = TextEditingController();
  bool isPanelLoading = true; // To track loading state
  Map<String, dynamic>? panelInfo; // To store panel details
  String? _idt;
  int? _panelId;
  int? _caseId;
  int? _selectedCompanyId;
  String? _appUrl;

  final AuthService _authService = AuthService();
  final commonService _service = commonService();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _initializeData();
    await instance();
  }

  Future<void> instance() async {
    final instances = await _service.getSavedInstances(); // This method retrieves all instances.
    for (var instance in instances) {
      final domainUrl = instance['domain_url'];
      if (domainUrl != null) {
        _appUrl = domainUrl;
        await fetchPanelDetails(domainUrl);
      }
    }
  }


  Future<void> _loadSelectedCompanyIdFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedCompanyId = prefs.getInt('selected_company_id');
    setState(() {
      _selectedCompanyId = selectedCompanyId;
    });
  }


  Future<void> _initializeData() async {
    await _loadAuthToken();

    final panelDetails = widget.task;
    _panelId = panelDetails['panelId'];

    final caseDetails = widget.task;
    _caseId = caseDetails['casesId'];

    if (_idt != null && _idt!.isNotEmpty) {
      _loadSelectedCompanyIdFromPrefs();
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


  Future<void> fetchPanelDetails(String domainUrl) async {
    try {
      // Fetch the access token
      final taskAccessToken = await _authService.getIdt();
      setState(() {
        _idt = taskAccessToken;
      });

      // Build the URL
      final String url = '$_appUrl/api/v1/user/company/case/panel/info?&companyId=$_selectedCompanyId&caseId=$_caseId&panelId=$_panelId';

      // Send the API request
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_idt',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      // Parse the response
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success']) {
          // Extract panel details
          final dynamic panelInfoData = responseData['data']['panelInfo'];
          setState(() {
            panelInfo = panelInfoData;
            isPanelLoading = false;
          });

          // Print the panel details to the console
          print('Panel Name: ${panelInfoData['name']}');
          print('Panel Description: ${panelInfoData['description']}');
          print('Panel Members: ${panelInfoData['members']}');
        } else {
          print('Error: ${responseData['message']}');
        }
      } else {
        print('Failed to fetch panel details. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching panel details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final screenWidth = MediaQuery.of(context).size.width; // Get screen width
    final screenHeight = MediaQuery.of(context).size.height; // Get screen height

    // Adjust font size and padding based on screen width
    double padding = screenWidth * 0.04; // Dynamic padding
    double fontSizeTitle = screenWidth * 0.040; // Dynamic font size for titles
    double avatarSize = screenWidth * 0.05; // Avatar size based on screen width

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: Text(
          "Panel Details",
          style: TextStyle(fontSize: fontSizeTitle, fontWeight: FontWeight.bold),
        ),
        elevation: 6.0, // Shadow effect
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(padding), // Responsive padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name box (non-expandable)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(screenWidth * 0.04), // Responsive padding
                  margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_rounded, color: Colors.black,size:  screenWidth * 0.05,),
                          SizedBox(width: screenWidth * 0.02), // Adjustable spacing
                          Text(
                            'Name',
                            style: TextStyle(
                              fontSize: fontSizeTitle, // Adjust text size
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.01),

                      Align(
                        alignment: Alignment.centerLeft, // Align the text to the right side
                        child: Padding(
                          padding: EdgeInsets.only(left: screenWidth * 0.02), // Add a little padding to the right
                          child: Text(
                            panelInfo?['name'] ?? 'NA', // Display name, or 'NA' if null
                            style: TextStyle(
                              fontSize: fontSizeTitle,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis, // Ensure text doesn't overflow
                          ),
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
                        padding: EdgeInsets.all(padding),
                        child: Text(
                          panelInfo?['description'] ?? 'No description available.',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),

                //Member Details
                buildExpandableSection(
                  title: 'Members',
                  icon: Icons.people,
                  contentWidget: panelInfo?['members'] != null && panelInfo!['members'].isNotEmpty
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Wrap(
                        children: List<Widget>.generate(
                          panelInfo!['members'].length,
                              (index) {
                            final member = panelInfo!['members'][index];
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 2.0), // Space between avatars
                              child: Container(
                                // Wrap the CircleAvatar inside a container for additional styling if needed
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50), // Optional, adds border radius around the avatar
                                  border: Border.all(color: Colors.blue, width:1), // Optional border around the avatar
                                ),
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
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                      : Center(
                    child: Text(
                      'No members available.',
                      style: TextStyle(fontSize: fontSizeTitle * 0.8),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper function to build each expandable section
  Widget buildExpandableSection({
    required String title,
    required IconData icon,
    String? content,
    Widget? contentWidget,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
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
                Text(content ?? '', style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
