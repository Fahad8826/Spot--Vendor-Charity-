// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class ShopAnalyticsDashboard extends StatefulWidget {
//   const ShopAnalyticsDashboard({super.key});

//   @override
//   State<ShopAnalyticsDashboard> createState() => _ShopAnalyticsDashboardState();
// }

// class AnalyticsData {
//   final DateTime date;
//   final int views;
//   final int mapClicks;

//   AnalyticsData(this.date, this.views, this.mapClicks);
// }

// class _ShopAnalyticsDashboardState extends State<ShopAnalyticsDashboard> {
//   final CollectionReference reportCollection =
//       FirebaseFirestore.instance.collection('shop_analytics_daily');

//   final String? userId = FirebaseAuth.instance.currentUser?.uid;

//   DateTime? _startDate;
//   DateTime? _endDate;

//   bool showViews = true;
//   bool showMapClicks = true;

//   Future<void> _selectDateRange(BuildContext context) async {
//     final DateTimeRange? picked = await showDateRangePicker(
//       context: context,
//       firstDate: DateTime(2023, 1),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null) {
//       setState(() {
//         _startDate = picked.start;
//         _endDate = picked.end;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFF053E51), Color(0xFF2E8B57)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: userId == null
//             ? const Center(
//                 child: Text("No user logged in",
//                     style: TextStyle(color: Colors.white)))
//             : Column(
//                 children: [
//                   const SizedBox(height: 50),
//                   Expanded(
//                     child: StreamBuilder(
//                       stream: reportCollection
//                           .where('vendorId', isEqualTo: userId)
//                           .snapshots(),
//                       builder: (context, AsyncSnapshot snapshot) {
//                         if (snapshot.hasData && snapshot.data.docs.isNotEmpty) {
//                           final List<AnalyticsData> chartData = snapshot
//                               .data.docs
//                               .map<AnalyticsData>((DocumentSnapshot doc) {
//                             return AnalyticsData(
//                               (doc['timestamp'] as Timestamp).toDate(),
//                               doc['views'],
//                               doc['mapClicks'],
//                             );
//                           }).where((data) {
//                             if (_startDate == null || _endDate == null)
//                               return true;
//                             return data.date.isAfter(_startDate!) &&
//                                 data.date.isBefore(_endDate!);
//                           }).toList();

//                           return Column(
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   // Bar Chart (Left-Top Aligned)
//                                   Card(
//                                     elevation: 12,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(20),
//                                     ),
//                                     color: Colors.white.withOpacity(0.9),
//                                     child: SizedBox(
//                                       height: 250,
//                                       width: 320,
//                                       child: Padding(
//                                         padding: const EdgeInsets.all(16.0),
//                                         child: BarChart(
//                                           BarChartData(
//                                             barGroups: _getBarGroups(chartData),
//                                             titlesData: FlTitlesData(
//                                               leftTitles: AxisTitles(
//                                                 sideTitles: SideTitles(
//                                                   showTitles: true,
//                                                   reservedSize: 30,
//                                                   getTitlesWidget:
//                                                       (value, meta) {
//                                                     return Text(
//                                                       "${value.toInt()}",
//                                                       style:
//                                                           GoogleFonts.poppins(
//                                                         fontWeight:
//                                                             FontWeight.w500,
//                                                         fontSize: 12,
//                                                         color: Colors.black87,
//                                                       ),
//                                                     );
//                                                   },
//                                                 ),
//                                               ),
//                                               bottomTitles: AxisTitles(
//                                                 sideTitles: SideTitles(
//                                                   showTitles: true,
//                                                   getTitlesWidget:
//                                                       (value, meta) {
//                                                     if (value.toInt() >=
//                                                         chartData.length) {
//                                                       return const SizedBox();
//                                                     }
//                                                     return Padding(
//                                                       padding:
//                                                           const EdgeInsets.only(
//                                                               top: 5),
//                                                       child: Text(
//                                                         DateFormat('MMM dd')
//                                                             .format(chartData[
//                                                                     value
//                                                                         .toInt()]
//                                                                 .date),
//                                                         style:
//                                                             GoogleFonts.poppins(
//                                                                 fontSize: 10,
//                                                                 fontWeight:
//                                                                     FontWeight
//                                                                         .w500),
//                                                       ),
//                                                     );
//                                                   },
//                                                 ),
//                                               ),
//                                             ),
//                                             borderData:
//                                                 FlBorderData(show: false),
//                                             gridData: FlGridData(show: false),
//                                             barTouchData: BarTouchData(
//                                               touchTooltipData:
//                                                   BarTouchTooltipData(
//                                                 tooltipRoundedRadius: 8,
//                                                 getTooltipItem: (group,
//                                                     groupIndex, rod, rodIndex) {
//                                                   return BarTooltipItem(
//                                                     "${rod.toY.toInt()}",
//                                                     GoogleFonts.poppins(
//                                                       fontWeight:
//                                                           FontWeight.bold,
//                                                       fontSize: 14,
//                                                       color: Colors.white,
//                                                     ),
//                                                   );
//                                                 },
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),

//                               const SizedBox(height: 20),

//                               // Date Picker Below the Graph
//                               ElevatedButton(
//                                 onPressed: () => _selectDateRange(context),
//                                 style: ElevatedButton.styleFrom(
//                                   padding: const EdgeInsets.symmetric(
//                                       vertical: 14, horizontal: 24),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   backgroundColor: Colors.transparent,
//                                   shadowColor: Colors.transparent,
//                                 ).copyWith(
//                                   backgroundColor:
//                                       MaterialStateProperty.resolveWith(
//                                     (states) => Colors.transparent,
//                                   ),
//                                 ),
//                                 child: Ink(
//                                   decoration: BoxDecoration(
//                                     gradient: const LinearGradient(
//                                       colors: [Colors.blueAccent, Colors.cyan],
//                                       begin: Alignment.topLeft,
//                                       end: Alignment.bottomRight,
//                                     ),
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Container(
//                                     padding: const EdgeInsets.symmetric(
//                                         vertical: 14, horizontal: 24),
//                                     child: Text(
//                                       "Select Date Range",
//                                       style: GoogleFonts.poppins(
//                                           fontSize: 16, color: Colors.white),
//                                     ),
//                                   ),
//                                 ),
//                               ),

//                               if (_startDate != null && _endDate != null)
//                                 Padding(
//                                   padding: const EdgeInsets.only(top: 10),
//                                   child: Text(
//                                     "${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd').format(_endDate!)}",
//                                     style: GoogleFonts.poppins(
//                                         fontWeight: FontWeight.w500,
//                                         color: Colors.white),
//                                   ),
//                                 ),
//                             ],
//                           );
//                         } else if (snapshot.hasData) {
//                           return const Center(
//                               child: Text('No data available.',
//                                   style: TextStyle(color: Colors.white)));
//                         }
//                         return const Center(
//                             child:
//                                 CircularProgressIndicator(color: Colors.white));
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//       ),
//     );
//   }

//   List<BarChartGroupData> _getBarGroups(List<AnalyticsData> chartData) {
//     return List.generate(chartData.length, (index) {
//       return BarChartGroupData(
//         x: index,
//         barRods: [
//           if (showViews)
//             BarChartRodData(
//               toY: chartData[index].views.toDouble(),
//               width: 8,
//               borderRadius: BorderRadius.circular(6),
//               gradient: const LinearGradient(
//                 colors: [Colors.blue, Colors.cyanAccent],
//                 begin: Alignment.bottomCenter,
//                 end: Alignment.topCenter,
//               ),
//             ),
//           if (showMapClicks)
//             BarChartRodData(
//               toY: chartData[index].mapClicks.toDouble(),
//               width: 8,
//               borderRadius: BorderRadius.circular(6),
//               gradient: const LinearGradient(
//                 colors: [Colors.red, Colors.pinkAccent],
//                 begin: Alignment.bottomCenter,
//                 end: Alignment.topCenter,
//               ),
//             ),
//         ],
//       );
//     });
//   }
// }
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spot/vendor/screens/vendorProfilepage.dart';

class ShopAnalyticsDashboard extends StatefulWidget {
  const ShopAnalyticsDashboard({super.key});

  @override
  State<ShopAnalyticsDashboard> createState() => _ShopAnalyticsDashboardState();
}

class AnalyticsData {
  final DateTime date;
  final int views;
  final int mapClicks;

  AnalyticsData(this.date, this.views, this.mapClicks);
}

class _ShopAnalyticsDashboardState extends State<ShopAnalyticsDashboard> {
  final CollectionReference reportCollection =
      FirebaseFirestore.instance.collection('shop_analytics_daily');

  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  DateTime? _startDate;
  DateTime? _endDate;

  bool showViews = true;
  bool showMapClicks = true;

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VendorProfilePage(),
                    ));
              },
              icon: Icon(
                Icons.person,
                color: Colors.white,
                size: 40,
              ))
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF053E51), Color(0xFF2E8B57)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: userId == null
            ? const Center(
                child: Text("No user logged in",
                    style: TextStyle(color: Colors.white)))
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    const SizedBox(height: 50),

                    // Buttons for Views & Map Clicks
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _toggleButton(
                            "Views", showViews, Colors.blue, Colors.cyan, () {
                          setState(() {
                            showViews = !showViews;
                          });
                        }),
                        const SizedBox(width: 10),
                        _toggleButton("Map Clicks", showMapClicks, Colors.red,
                            Colors.pinkAccent, () {
                          setState(() {
                            showMapClicks = !showMapClicks;
                          });
                        }),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Expanded(
                      child: StreamBuilder(
                        stream: reportCollection
                            .where('vendorId', isEqualTo: userId)
                            .snapshots(),
                        builder: (context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData &&
                              snapshot.data.docs.isNotEmpty) {
                            final List<AnalyticsData> chartData = snapshot
                                .data.docs
                                .map<AnalyticsData>((DocumentSnapshot doc) {
                              return AnalyticsData(
                                (doc['timestamp'] as Timestamp).toDate(),
                                doc['views'],
                                doc['mapClicks'],
                              );
                            }).where((data) {
                              if (_startDate == null || _endDate == null)
                                return true;
                              return data.date.isAfter(_startDate!) &&
                                  data.date.isBefore(_endDate!);
                            }).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Bar Chart (Top-Left Positioned)
                                Align(
                                  alignment: Alignment.center,
                                  child: Card(
                                    elevation: 12,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    color: Colors.white.withOpacity(0.9),
                                    child: SizedBox(
                                      height: 250,
                                      width: 320,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: BarChart(
                                          BarChartData(
                                            barGroups: _getBarGroups(chartData),
                                            titlesData: FlTitlesData(
                                              leftTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  getTitlesWidget:
                                                      (value, meta) {
                                                    return Text(
                                                      "${value.toInt()}",
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 12,
                                                        color: Colors.black87,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  getTitlesWidget:
                                                      (value, meta) {
                                                    if (value.toInt() >=
                                                        chartData.length) {
                                                      return const SizedBox();
                                                    }
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 5),
                                                      child: Text(
                                                        DateFormat('M/d ')
                                                            .format(chartData[
                                                                    value
                                                                        .toInt()]
                                                                .date),
                                                        style:
                                                            GoogleFonts.poppins(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            borderData:
                                                FlBorderData(show: false),
                                            gridData: FlGridData(show: false),
                                            barTouchData: BarTouchData(
                                              touchTooltipData:
                                                  BarTouchTooltipData(
                                                tooltipRoundedRadius: 8,
                                                getTooltipItem: (group,
                                                    groupIndex, rod, rodIndex) {
                                                  return BarTooltipItem(
                                                    "${rod.toY.toInt()}",
                                                    GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Colors.white,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Date Picker Below the Graph
                                ElevatedButton(
                                  onPressed: () => _selectDateRange(context),
                                  style: _buttonStyle(
                                      Colors.blueAccent, Colors.cyan),
                                  child: Text(
                                    "Select Date Range",
                                    style: GoogleFonts.poppins(
                                        fontSize: 16, color: Colors.white),
                                  ),
                                ),

                                if (_startDate != null && _endDate != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      "${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd').format(_endDate!)}",
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white),
                                    ),
                                  ),
                              ],
                            );
                          } else if (snapshot.hasData) {
                            return const Center(
                                child: Text('No data available.',
                                    style: TextStyle(color: Colors.white)));
                          }
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white));
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // Function to create toggle buttons
  Widget _toggleButton(String text, bool isActive, Color startColor,
      Color endColor, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: _buttonStyle(startColor, endColor),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
      ),
    );
  }

  // Button Style with Gradient
  ButtonStyle _buttonStyle(Color startColor, Color endColor) {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
    )
        .copyWith(
          backgroundColor: MaterialStateProperty.resolveWith(
            (states) => Colors.transparent,
          ),
        )
        .merge(
          ButtonStyle(
            overlayColor:
                MaterialStateProperty.all(Colors.white.withOpacity(0.2)),
          ),
        );
  }

  List<BarChartGroupData> _getBarGroups(List<AnalyticsData> chartData) {
    return List.generate(chartData.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          if (showViews)
            BarChartRodData(
              borderRadius: BorderRadius.circular(1),
              toY: chartData[index].views.toDouble(),
              width: 8,
              gradient: const LinearGradient(
                  colors: [Color.fromARGB(255, 35, 94, 142), Colors.cyan]),
            ),
          if (showMapClicks)
            BarChartRodData(
              borderRadius: BorderRadius.circular(1),
              toY: chartData[index].mapClicks.toDouble(),
              width: 8,
              gradient: const LinearGradient(colors: [
                Color.fromARGB(255, 199, 50, 39),
                Colors.pinkAccent
              ]),
            ),
        ],
      );
    });
  }
}
