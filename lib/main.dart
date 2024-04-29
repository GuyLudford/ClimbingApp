import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
// For rootBundle
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'statstest',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

List _climbers = [];

var climberID = 0; //Get climberID from login information in long term.

class MyAppState extends ChangeNotifier {
// Fetch content from the json file
  Future<void> readJson() async {
    final String response =
        await rootBundle.loadString('assets/climber_data.json');
    final data = await json.decode(response);
    _climbers = data["Climbers"];

    notifyListeners();
  }

  String getHardestClimb(int climberID) {
    //Return the hardest climb for the climber total ever.
    if (climberID >= 0 && climberID < _climbers.length) {
      final climber = _climbers[climberID];
      final sessions = climber["sessions:"];
      String hardestClimb = '';

      sessions.forEach((key, value) {
        final routes = value["routes"];
        routes.forEach((routeKey, routeValue) {
          final grade = routeValue["Grade"];
          if (hardestClimb.isEmpty || grade.compareTo(hardestClimb) > 0) {
            hardestClimb = grade;
          }
        });
      });

      return hardestClimb;
    } else {
      return 'Invalid climber ID';
    }
  }

  String getNumGyms(int climberID) {
    if (climberID >= 0 && climberID < _climbers.length) {
      final climber = _climbers[climberID];
      final sessions = climber["sessions:"];
      final Set<String> uniqueGyms = {};

      sessions.forEach((key, value) {
        final gymID = value["GymID"];
        uniqueGyms.add(gymID);
      });

      return uniqueGyms.length.toString();
    } else {
      return 'Invalid climber ID';
    }
  }

  String getNumClimbslastSession(int climberID) {
    if (climberID >= 0 && climberID < _climbers.length) {
      final climber = _climbers[climberID];
      final sessions = climber["sessions:"];
      int totalClimbs = 0;

      sessions.forEach((key, value) {
        final routes = value["routes"];
        routes.forEach((routeKey, routeValue) {
          final numClimbs = int.tryParse(routeValue["attempts"]) ?? 0;
          totalClimbs += numClimbs;
        });
      });

      return totalClimbs.toString();
    } else {
      return 'Invalid climber ID';
    }
  }

  String getNumSessionMonth(int climberID) {
    if (climberID >= 0 && climberID < _climbers.length) {
      final climber = _climbers[climberID];
      final sessions = climber["sessions:"];
      final currentDate = DateTime.now();
      int numSessions = 0;

      sessions.forEach((key, value) {
        final sessionDateStr = value["Date"];
        final sessionYear = int.parse(sessionDateStr.substring(6)) + 2000;
        final sessionDate = DateTime(
          sessionYear,
          int.parse(sessionDateStr.substring(3, 5)),
          int.parse(sessionDateStr.substring(0, 2)),
        );

        if (currentDate.difference(sessionDate).inDays <= 30) {
          numSessions++;
        }
      });

      return numSessions.toString();
    } else {
      return 'Invalid climber ID';
    }
  }

  Map<String, dynamic> getSessionData(int sessionID, int climberID) {
    if (climberID >= 0 && climberID < _climbers.length) {
      final climber = _climbers[climberID];
      final sessions = climber["sessions:"];
      final session = sessions[sessionID.toString()];

      //final session = climber["sessions"][sessionID.toString()];
      //if (session == null) {
      // return {}; // Return an empty map if session not found
      //}

      final date = session["Date"];
      final gymID = session["GymID"];
      final routes = session["routes"];

      // Calculate average grade
      final numRoutes = routes.length;
      final totalGrade = routes.values.fold(
          0, (sum, route) => sum + int.parse(route["Grade"].substring(1)));
      final averageGrade = 'v${(totalGrade / numRoutes).toStringAsFixed(0)}';

      // Find hardest grade
      final hardestGrade = routes.values
          .map((route) => route["Grade"])
          .reduce((a, b) => a.compareTo(b) > 0 ? a : b);

      return {
        'date': date,
        'gymName': gymID,
        'numClimbs': numRoutes,
        'averageGrade': averageGrade,
        'hardestGrade': hardestGrade,
        'sessionID': sessionID,
      };
    } else {
      return {
        'date': null,
        'gymName': null,
        'numClimbs': null,
        'averageGrade': null,
        'hardestGrade': null,
        'sessionID': null,
      };
    }
  }

  int getLastSession(int climberID) {
    if (climberID >= 0 && climberID < _climbers.length) {
      final climber = _climbers[climberID];
      final sessions = climber["sessions:"];
      final sessionKeys = sessions.keys.map(int.parse).toList();
      if (sessionKeys.isNotEmpty) {
        return sessionKeys.last; // Return the most recent session ID
      }
    }
    return -1; // Return -1 if climber not found or no sessions
  }

  List<DateTime> getSessionDates(int climberID) {
    if (climberID >= 0 && climberID < _climbers.length) {
      final climber = _climbers[climberID];
      final sessions = climber["sessions:"];
      final sessionDates = sessions.values
          .map((session) {
            final dateString = session["Date"];
            final dateParts = dateString.split('/');
            if (dateParts.length == 3) {
              final day = int.parse(dateParts[0]);
              final month = int.parse(dateParts[1]);
              final year = int.parse(dateParts[2]);
              return DateTime(year, month, day);
            }
            return null;
          })
          .whereType<DateTime>()
          .toList();

      return sessionDates;
    }

    return []; // Return an empty list if climber not found
  }

  List<ChartData> GetSessionAvGrade(int climberID) {
    final List<ChartData> chartData = [];

    if (climberID >= 0 && climberID < _climbers.length) {
      final climber = _climbers[climberID];
      final sessions = climber["sessions:"];

      sessions.forEach((sessionID, session) {
        final routes = session["routes"];
        final numRoutes = routes.length;
        final totalGrade = routes.values.fold(
            0, (sum, route) => sum + int.parse(route["Grade"].substring(1)));
        final averageGrade =
            (totalGrade / numRoutes); // Calculate average grade

        chartData.add(ChartData(int.parse(sessionID), averageGrade));
      });
    }

    return chartData;
  }

  List<ChartData> GetSessionBestGrade(int climberID) {
    final List<ChartData> chartData = [];

    if (climberID >= 0 && climberID < _climbers.length) {
      final climber = _climbers[climberID];
      final sessions = climber["sessions:"];

      sessions.forEach((sessionID, session) {
        final routes = session["routes"];
        final bestGrade = routes.values
            .map((route) => double.parse(route["Grade"].substring(1)))
            .reduce((a, b) => a > b ? a : b); // Find best grade

        chartData.add(ChartData(int.parse(sessionID), bestGrade));
      });
    }

    return chartData;
  }

  List<stackedChartData> getRouteSuccessChartData(
      int climberID, int sessionID) {
    //final List<stackedChartData> chartData = [];
    final Map<String, stackedChartData> gradeMap = {};
    if (sessionID != -1) {
      final sessionRouteData = getSessionRouteData(climberID, sessionID);
      for (final data in sessionRouteData) {
        final grade = data.grade;
        final successes = data.successes;
        final attempts = data.attempts - successes;
        

        if (gradeMap.containsKey(grade)) {
          gradeMap[grade]!.attempts += attempts;
          gradeMap[grade]!.successes += successes;
        } else {
         gradeMap[grade] = stackedChartData(grade, attempts, successes);
        }
      }

            // Order the list by numeric grade (ascending)
      final sortedList = gradeMap.values.toList()
    ..sort((a, b) {
      final numericA = int.tryParse(a.grade.replaceAll(RegExp(r'[^0-9]'), ''));
      final numericB = int.tryParse(b.grade.replaceAll(RegExp(r'[^0-9]'), ''));
      if (numericA!= null){
      return numericA.compareTo(numericB as num);
      } else{
        return -1;
      }
    });

    return sortedList;
    } else {
      final allSessions = climberID >= 0 && climberID < _climbers.length
          ? _climbers[climberID]["sessions:"]
          : null;

      if (allSessions != null) {
        allSessions.forEach((sessionID, session) {
          final routes = session["routes"];
          routes.forEach((routeID, route) {
            final grade = route["Grade"];
            final successes = int.parse(route["successes"]);
            final attempts = int.parse(route["attempts"]) - successes;
            

            if (gradeMap.containsKey(grade)) {
              gradeMap[grade]!.attempts += attempts;
              gradeMap[grade]!.successes += successes;
            } else {

              gradeMap[grade] = stackedChartData(grade, attempts, successes);
            }
          });
        });
      }

      // Order the list by numeric grade (ascending)
  final sortedList = gradeMap.values.toList()
    ..sort((a, b) {
      final numericA = int.tryParse(a.grade.replaceAll(RegExp(r'[^0-9]'), ''));
      final numericB = int.tryParse(b.grade.replaceAll(RegExp(r'[^0-9]'), ''));
      if (numericA!= null){
      return numericA.compareTo(numericB as num);
      } else{
        return -1;
      }
    });


  return sortedList;
    }
  }

  List<RouteData> getSessionRouteData(int climberID, int sessionID) {
    final List<RouteData> routeData = [];

    if (climberID >= 0 && climberID < _climbers.length) {
      final climber = _climbers[climberID];
      final sessions = climber["sessions:"];

      final session = sessions[sessionID.toString()];
      if (session != null) {
        final routes = session["routes"];
        routes.forEach((routeID, route) {
          final grade = route["Grade"];
          final attempts = int.parse(route["attempts"]);
          final successes = int.parse(route["successes"]);
          routeData.add(RouteData(grade, attempts, successes));
        });
      }
    }

    return routeData;
  }

  List<SessionData> getAllSessionsData(int climberID) {
  final List<SessionData> allSessionsData = [];

  if (climberID >= 0 && climberID < _climbers.length) {
    final climber = _climbers[climberID];
    final sessions = climber["sessions:"];
    sessions.forEach((sessionID, session) {
      final sessionData = getSessionData(int.parse(sessionID), climberID);
      allSessionsData.add(SessionData(
        date: sessionData['date'],
        gymName: sessionData['gymName'],
        numClimbs: sessionData['numClimbs'],
        averageGrade: sessionData['averageGrade'],
        hardestGrade: sessionData['hardestGrade'],
        sessionID: sessionData['sessionID'],
      ));
    });
  }

  return allSessionsData;
}

  List<SessionData> getPrevSessionData() {
    //return last three sessions worth of data
     final List<SessionData> previousSessionsData = [];

  if (climberID >= 0 && climberID < _climbers.length) {
    final climber = _climbers[climberID];
    final sessions = climber["sessions:"];
    final sessionIDs = sessions.keys.map(int.parse).toList();

    print(sessionIDs);

    var recentSessionIDs = sessionIDs.reversed.take(4);
    //final recentSessionIDs = recentSessionIDs1.removeAt(2);
    recentSessionIDs = List.from(recentSessionIDs);
    recentSessionIDs.removeAt(0);

    for (final sessionID in recentSessionIDs) {
      final sessionData = getSessionData(sessionID, climberID);
      previousSessionsData.add(SessionData(
        date: sessionData['date'],
        gymName: sessionData['gymName'],
        numClimbs: sessionData['numClimbs'],
        averageGrade: sessionData['averageGrade'],
        hardestGrade: sessionData['hardestGrade'],
        sessionID: sessionData['sessionID'],
      ));
    }
  }

  return previousSessionsData;
}
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var appState = context.watch<MyAppState>();

    return Scaffold(
      backgroundColor: theme.colorScheme.primaryContainer,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Display the button if _climbers is empty
              if (_climbers.isEmpty)
                ElevatedButton(
                  onPressed: () {
                    appState.readJson();
                  },
                  child: const Text('Load Data'),
                )
              else
                // Display the StatsDisplay when _climbers is not empty
                const StatsDisplay(),
            ],
          ),
        ),
      ),
    );
  }
}

class StatsDisplay extends StatelessWidget {
  const StatsDisplay({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onBackground,
    );
    var appState = context.watch<MyAppState>();

    var lastSession = appState.getLastSession(climberID);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 24, // Increase font size for emphasis
                  fontWeight: FontWeight.bold, // Make it bold
                  color: theme.primaryColor, // Use the primary color
                ),
              ),
            ),
            const SizedBox(height: 16), // Add spacing between sections

            Card(
              color: theme.canvasColor,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text(
                      'Hardest Climb: ${appState.getHardestClimb(climberID)}',
                      style: style.copyWith(
                          fontSize: 18), // Slightly smaller font size
                    ),
                    Text(
                      'Number of Gyms: ${appState.getNumGyms(climberID)}',
                      style: style.copyWith(fontSize: 18),
                    ),
                    //Divider(color: theme.dividerColor), // Add a horizontal line

                    Text(
                      'Climbs Last Session: ${appState.getNumClimbslastSession(climberID)}',
                      style: style.copyWith(fontSize: 18),
                    ),
                    Text(
                      'Last 4 Weeks: ${appState.getNumSessionMonth(climberID)} Sessions',
                      style: style.copyWith(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            Divider(color: theme.dividerColor),
            DualLineChartsWidget(
              chartData1: appState.GetSessionAvGrade(climberID),
              chartData2: appState.GetSessionBestGrade(climberID),
            ),
            Divider(color: theme.dividerColor), // Another horizontal line
            Center(
              child: Text(
                'Route Overview:',
                style: TextStyle(
                  fontSize: 20, // Slightly larger font size
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ),
            gradingChart(
                chartData: appState.getRouteSuccessChartData(climberID, -1)),
            Divider(color: theme.dividerColor),
            Center(
              child: Text(
                'Last Session:',
                style: TextStyle(
                  fontSize: 20, // Slightly larger font size
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ),
            SessionCard(
                date: appState.getSessionData(lastSession, climberID)['date'],
                gymName:
                    appState.getSessionData(lastSession, climberID)['gymName'],
                numClimbs: appState.getSessionData(
                    lastSession, climberID)['numClimbs'],
                averageGrade: appState.getSessionData(
                    lastSession, climberID)['averageGrade'],
                hardestGrade: appState.getSessionData(
                    lastSession, climberID)['hardestGrade'],
                sessionID: appState.getSessionData(
                    lastSession, climberID)['sessionID']),
            SessionsSection(sessions: appState.getPrevSessionData()),
          ],
        ),
      ),
    );
  }
}

class ClimberContent extends StatelessWidget {
  final Map<String, dynamic> climber;
  final int index;

  const ClimberContent({
    super.key,
    required this.climber,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Text(climber["ID"]);
  }
}

class SessionCard extends StatefulWidget {
  final String date;
  final String gymName;
  final int numClimbs;
  final String averageGrade;
  final String hardestGrade;
  final int sessionID;

  const SessionCard({
    required this.date,
    required this.gymName,
    required this.numClimbs,
    required this.averageGrade,
    required this.hardestGrade,
    required this.sessionID,
    Key? key,
  }) : super(key: key);

  @override
  _SessionCardState createState() => _SessionCardState();
}

class _SessionCardState extends State<SessionCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: () {
          setState(() {
            isExpanded = !isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.date,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.gymName,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyText1!.color,
                ),
              ),
              if (isExpanded) ...[
                Divider(color: theme.dividerColor),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Number of Climbs: ${widget.numClimbs}',
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.textTheme.bodyText2!.color,
                            ),
                          ),
                          Text(
                            'Average Grade: ${widget.averageGrade}',
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.textTheme.bodyText2!.color,
                            ),
                          ),
                          Text(
                            'Hardest Grade: ${widget.hardestGrade}',
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.textTheme.bodyText2!.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SessionPage(sessionData: widget),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: theme.primaryColor, // Text color
                          padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 24), // Adjust height and width
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(8), // Rounded corners
                          ),
                        ),
                        child: const Text('View Session Details'),
                      ),
                    ),
                  ],
                ),
              ],
              //SizedBox(height: 8),
              if (!isExpanded)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isExpanded = true;
                        });
                      },
                      child: Text(
                        'Expand...',
                        style: TextStyle(
                          color: theme.hintColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SessionPage extends StatelessWidget {
  final SessionCard sessionData;

  const SessionPage({required this.sessionData});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        title: const Text('Session Details'),
        backgroundColor: Theme.of(context)
            .colorScheme
            .primaryContainer, // Set your desired background color
        centerTitle: true,
      ),
      body: ListView(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            'Date: ${sessionData.date}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gym Name: ${sessionData.gymName}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Number of Climbs: ${sessionData.numClimbs}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Average Grade Climbed: ${sessionData.averageGrade}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Hardest Grade Climbed: ${sessionData.hardestGrade}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  gradingChart(
                      chartData: appState.getRouteSuccessChartData(
                          climberID, sessionData.sessionID)),
                  const SizedBox(height: 16),
                  // Add the route breakdown (list of cards) here
                  RouteBreakdown(
                      routeDataList: appState.getSessionRouteData(
                          climberID, sessionData.sessionID)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class gradingChart extends StatelessWidget {
  final List<stackedChartData> chartData;

  const gradingChart({
    required this.chartData,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Routes Climbed",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.circle,
                                color: Colors.redAccent,
                                size: 12,
                              ),
                              const SizedBox(
                                  width:
                                      4), // Add spacing between icon and text
                              Text(
                                "Attempts",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyText2!
                                      .color,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.circle,
                                color: Colors.greenAccent,
                                size: 12,
                              ),
                              const SizedBox(
                                  width:
                                      4), // Add spacing between icon and text
                              Text(
                                "Successes",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyText2!
                                      .color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              borderWidth: 0,
              plotAreaBorderWidth: 0,
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                axisLine: AxisLine(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    width: 0),
                majorGridLines: MajorGridLines(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    width: 0),
                borderWidth: 0,
              ),
              primaryYAxis: const NumericAxis(
                isVisible: false,
              ),
              series: <CartesianSeries>[
                StackedBarSeries<stackedChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (stackedChartData data, _) => data.grade,
                    yValueMapper: (stackedChartData data, _) => data.attempts,
                    color: Colors.redAccent,
                    dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        labelIntersectAction: LabelIntersectAction.shift,
                        labelAlignment: ChartDataLabelAlignment.top),
                    borderRadius: const BorderRadius.only(
                        topLeft: (Radius.circular(10)),
                        bottomLeft: (Radius.circular(10)))),
                StackedBarSeries<stackedChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (stackedChartData data, _) => data.grade,
                    yValueMapper: (stackedChartData data, _) => data.successes,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelIntersectAction: LabelIntersectAction.shift,
                      labelAlignment: ChartDataLabelAlignment.bottom,
                    ),
                    color: Colors.greenAccent,
                    borderRadius: const BorderRadius.only(
                        topRight: (Radius.circular(10)),
                        bottomRight: (Radius.circular(10)))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class stackedChartData {
  final String grade;
  int attempts;
  int successes;
  //Successes excluding Attempts
  stackedChartData(this.grade, this.attempts, this.successes);
}

class RouteData {
  final String grade;
  final int attempts;
  final int successes;

  RouteData(this.grade, this.attempts, this.successes);
}

class RouteBreakdown extends StatelessWidget {
  final List<RouteData> routeDataList;

  const RouteBreakdown({required this.routeDataList});

  @override
  Widget build(BuildContext context) {
    // Group routes by grade
    final Map<String, List<RouteData>> groupedRoutes = {};
    for (final route in routeDataList) {
      if (!groupedRoutes.containsKey(route.grade)) {
        groupedRoutes[route.grade] = [];
      }
      groupedRoutes[route.grade]!.add(route);
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Route Breakdown',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            for (final entry in groupedRoutes.entries)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Grade ${entry.key} (${entry.value.length} climbs)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  for (var i = 0; i < entry.value.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        entry.value.length > 1
                            ? 'Route ${i + 1}: Attempts: ${entry.value[i].attempts}, Successes: ${entry.value[i].successes}'
                            : 'Attempts: ${entry.value[i].attempts}, Successes: ${entry.value[i].successes}',
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class SessionsSection extends StatelessWidget {
  final List<SessionData> sessions;

  SessionsSection({required this.sessions});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final theme = Theme.of(context);

    // Function to build session cards
    List<Widget> _buildSessionCards() {
      if (sessions.isEmpty) {
        return [
          Text(
            'No Previous Sessions!',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSecondary,
            ),
          ) // Display message when no sessions
        ];
      }

      return sessions.map((session) {
        return SessionCard(
          date: session.date,
          gymName: session.gymName,
          numClimbs: session.numClimbs,
          averageGrade: session.averageGrade,
          hardestGrade: session.hardestGrade,
          sessionID: session.sessionID,
        );
      }).toList();
    }

    return Card(
      color: theme.colorScheme.secondary,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Previous Sessions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSecondary,
              ),
            ),
          ),
          ..._buildSessionCards(), // Use the generated session cards
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => allSessionsPage(
                    allSessions: appState.getAllSessionsData(climberID),
                  ),
                ),
              );
            },
            child: const Text('More Sessions'),
          ),
        ],
      ),
    );
  }
}

class allSessionsPage extends StatefulWidget {
  final List<SessionData> allSessions;

  const allSessionsPage({
    required this.allSessions,
    Key? key,
  }) : super(key: key);

  @override
  _allSessionsPageState createState() => _allSessionsPageState(allSessions);
}

class _allSessionsPageState extends State<allSessionsPage> {
  List<int> selectedYears = [DateTime.now().year];
  List<int> selectedMonths = [DateTime.now().month];
  late int totalMonths;
  late int totalYears;
  final List<SessionData> allSessions;
  _allSessionsPageState(this.allSessions);

  @override
  void initState() {
    super.initState();
    // Set the default state to select all years and months
    selectedYears = _getAvailableYears(allSessions);
    selectedMonths = _getAvailableMonths(allSessions);
    totalMonths = _getAvailableMonths(allSessions).length;
    totalYears = _getAvailableYears(allSessions).length;
  }

  List<SessionData> get filteredSessions {
  return allSessions.where((session) {
    final dateParts = session.date.split('/'); // Assuming the date format is "01/04/24"
    if (dateParts.length == 3) {
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);
      final sessionDate = DateTime(year, month, day);
      return selectedYears.contains(sessionDate.year) &&
          selectedMonths.contains(sessionDate.month);
    }
    return false; // Invalid date format
  }).toList();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        title: const Text('All Sessions'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedYears = _getAvailableYears(allSessions);
                    totalYears = selectedYears.length;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    selectedYears.length == totalYears
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                  ),
                  foregroundColor: MaterialStateProperty.all<Color>(
                    selectedYears.length == totalYears
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
                child: const Text('ALL'),
              ),
              for (final year in _getAvailableYears(allSessions))
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (selectedYears.contains(year)) {
                        selectedYears.remove(year);
                      } else {
                        selectedYears.add(year);
                      }
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      selectedYears.contains(year)
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.secondary,
                    ),
                    foregroundColor: MaterialStateProperty.all<Color>(
                      selectedYears.contains(year)
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                  child: Text(year.toString()),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedMonths = _getAvailableMonths(allSessions);
                    totalMonths = selectedMonths.length;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    selectedMonths.length == totalMonths
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                  ),
                  foregroundColor: MaterialStateProperty.all<Color>(
                    selectedMonths.length == totalMonths
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
                child: const Text('All'),
              ),
              for (final month in _getAvailableMonths(allSessions))
                ElevatedButton(
                  onPressed: () {
                    setState(
                      () {
                        if (selectedMonths.contains(month)) {
                          selectedMonths.remove(month);
                        } else {
                          selectedMonths.add(month);
                        }
                      },
                    );
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      selectedMonths.contains(month)
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.secondary,
                    ),
                    foregroundColor: MaterialStateProperty.all<Color>(
                      selectedMonths.contains(month)
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                  child: Text(_getMonthAbbreviation(month)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filteredSessions.isEmpty
                ? const Center(
                    child: Text(
                      'No Sessions Found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredSessions.length,
                    itemBuilder: (context, index) {
                      final session = filteredSessions[index];
                      return SessionCard(
                        date: session.date,
                        gymName: session.gymName,
                        numClimbs: session.numClimbs,
                        averageGrade: session.averageGrade,
                        hardestGrade: session.hardestGrade,
                        sessionID: session.sessionID,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

List<int> _getAvailableYears(List<SessionData> allSessions) {
  final Set<int> years = {};

  for (final session in allSessions) {
    final dateString = session.date;
    final dateParts = dateString.split('/');
    if (dateParts.length == 3) {
      final year = int.parse(dateParts[2]);
      years.add(year);
    }
  }

  return years.toSet().toList();
}

List<int> _getAvailableMonths(List<SessionData> allSessions) {
  final Set<int> months = {};

  for (final session in allSessions) {
    final dateString = session.date;
    final dateParts = dateString.split('/');
    if (dateParts.length == 3) {
      final month = int.parse(dateParts[1]);
      months.add(month);
    }
  }

  return months.toSet().toList();
}

  String _getMonthAbbreviation(int month) {
    return DateFormat.MMM().format(DateTime(2021, month));
  }
}

class SessionData {
  final String date;
  final String gymName;
  final int numClimbs;
  final String averageGrade;
  final String hardestGrade;
  final int sessionID;

  SessionData({
    required this.date,
    required this.gymName,
    required this.numClimbs,
    required this.averageGrade,
    required this.hardestGrade,
    required this.sessionID,
  });
}

class SessionsCalendar extends StatelessWidget {
  final List<DateTime> sessionDates; // Replace with actual session dates

  const SessionsCalendar({
    required this.sessionDates,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TableCalendar(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: DateTime.now(),
      selectedDayPredicate: (day) => sessionDates.contains(day),
      calendarFormat: CalendarFormat.month,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: theme.primaryColor,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: theme.highlightColor,
          shape: BoxShape.circle,
        ),
        //markersMaxAmount: 1,
      ),
    );
  }
}

class MyLineChartWidget extends StatelessWidget {
  final List<ChartData> chartData; // Your list of y-values
  final String title;
  final String xAxis;
  final String yAxis;

  MyLineChartWidget({
    required this.chartData,
    required this.title,
    required this.xAxis,
    required this.yAxis,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Container(
                    width: 400, // Customize the width
                    height: 300, // Customize the height
                    child: SfCartesianChart(
                      primaryXAxis: NumericAxis(title: AxisTitle(text: yAxis)),
                      primaryYAxis: NumericAxis(title: AxisTitle(text: xAxis)),
                      series: <CartesianSeries>[
                        LineSeries<ChartData, int>(
                          dataSource: chartData,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 300,
          height: 200,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                child: SfCartesianChart(
                  primaryXAxis: NumericAxis(title: AxisTitle(text: yAxis)),
                  primaryYAxis: NumericAxis(title: AxisTitle(text: xAxis)),
                  series: <CartesianSeries>[
                    LineSeries<ChartData, int>(
                      dataSource: chartData,
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.y,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DualLineChartsWidget extends StatelessWidget {
  final List<ChartData> chartData1; // Your first list of y-values
  final List<ChartData> chartData2; // Your second list of y-values

  DualLineChartsWidget({
    required this.chartData1,
    required this.chartData2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Grades Per Session",
          style: TextStyle(
            fontSize: 20, // Increase font size for emphasis
            fontWeight: FontWeight.bold, // Make it bold
            color: Theme.of(context).primaryColor, // Use the primary color
          ),
        ),
        Row(
          children: [
            Expanded(
              child: MyLineChartWidget(
                chartData: chartData1,
                title: 'Av. Grade per Session',
                xAxis: 'Av. V-Grade',
                yAxis: 'Session',
              ),
            ),
            Expanded(
              child: MyLineChartWidget(
                chartData: chartData2,
                title: 'Highest Grade per Session',
                xAxis: 'Best V-Grade',
                yAxis: 'Session',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ChartData {
  ChartData(this.x, this.y);
  final int x;
  final double y;
}
