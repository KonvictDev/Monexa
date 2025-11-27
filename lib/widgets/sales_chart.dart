import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../model/expense.dart';
import '../model/order.dart';
import '../utils/constants.dart'; // <-- 1. CHANGE THIS IMPORT


/// A stateful widget that displays an interactive sales and expense chart.
///
/// It handles its own "No Data" state, line chart data processing,
/// and user interactions for zoom and pan.
class SalesChartWidget extends StatefulWidget {
  // ... (rest of the file is identical) ...
// ... (omitted for brevity) ...
  final List<Order> orders;
  final List<Expense> expenses;
  final DateTime startDate;
  final DateTime endDate;
  final DateFilter filter;

  const SalesChartWidget({
    super.key,
    required this.orders,
    required this.expenses,
    required this.startDate,
    required this.endDate,
    required this.filter,
  });

  @override
  State<SalesChartWidget> createState() => _SalesChartWidgetState();
}

class _SalesChartWidgetState extends State<SalesChartWidget> {
  @override
  Widget build(BuildContext context) {
    // --- 1. HANDLE "NO DATA" STATE INTERNALLY ---
    if (widget.orders.isEmpty && widget.expenses.isEmpty) {
      return Container(
        // The error was here: `color: Colors.red,` was conflicting with the color inside `decoration`.
        // Removed `color: Colors.red`
        height: 300,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, // The desired background color is here
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 8,
            ),
          ],
        ),
        child: const Text("No sales or expense data found for this period."),
      );
    }

    // --- 2. ALL LOGIC FROM _buildSalesChart() MOVED HERE ---
    final bool isSingleDayView = widget.endDate.difference(widget.startDate).inDays < 1;

    String chartTitle;
    FlTitlesData titlesData;
    List<FlSpot> revenueSpots; // Renamed
    List<FlSpot> expenseSpots; // New
    double minX, maxX;
    Map<int, String>? xAxisLabels;

    final leftTitles = AxisTitles(sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 40,
      getTitlesWidget: (value, meta) => Text(
        '₹${value.toInt()}',
        style: const TextStyle(fontSize: 10),
      ),
    ));

    if (isSingleDayView) {
      // --- 2.A. HOURLY LOGIC ---
      if (widget.filter == DateFilter.today) chartTitle = "Today's Activity by Hour";
      else if (widget.filter == DateFilter.yesterday) chartTitle = "Yesterday's Activity by Hour";
      else chartTitle = "Activity by Hour (${DateFormat('MMM dd').format(widget.startDate)})";

      // Group sales by hour (0-23)
      final salesByHour = <int, double>{};
      final expensesByHour = <int, double>{}; // New
      for (int i = 0; i < 24; i++) {
        salesByHour[i] = 0.0;
        expensesByHour[i] = 0.0;
      }

      for (var order in widget.orders) {
        final hour = order.orderDate.hour;
        salesByHour[hour] = (salesByHour[hour] ?? 0.0) + order.totalAmount;
      }
      for (var expense in widget.expenses) { // New
        final hour = expense.date.hour;
        expensesByHour[hour] = (expensesByHour[hour] ?? 0.0) + expense.amount;
      }

      revenueSpots = salesByHour.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
      expenseSpots = expensesByHour.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(); // New
      minX = 0;
      maxX = 23;

      // Create *default* titles for hours
      titlesData = FlTitlesData(
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: leftTitles,
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          interval: 6, // Default interval: 12AM, 6AM, 12PM, 6PM
          getTitlesWidget: (value, meta) {
            String text;
            switch (value.toInt()) {
              case 0: text = '12AM'; break;
              case 6: text = '6AM'; break;
              case 12: text = '12PM'; break;
              case 18: text = '6PM'; break;
              default: return const SizedBox();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(text, style: const TextStyle(fontSize: 10)),
            );
          },
        )),
      );

    } else {
      // --- 2.B. DAILY LOGIC (for multi-day filters) ---

      final salesByDay = <DateTime, double>{};
      final expensesByDay = <DateTime, double>{}; // New
      xAxisLabels = <int, String>{};

      final int daysInRange = widget.endDate.difference(widget.startDate).inDays + 1;

      // Initialize all days in the range to 0.0
      for (var i = 0; i < daysInRange; i++) {
        final date = widget.startDate.add(Duration(days: i));
        final dayKey = DateTime(date.year, date.month, date.day);
        salesByDay[dayKey] = 0.0;
        expensesByDay[dayKey] = 0.0; // New
      }

      // Populate sales data
      for (var order in widget.orders) {
        final dayKey = DateTime(order.orderDate.year, order.orderDate.month, order.orderDate.day);
        if (salesByDay.containsKey(dayKey)) {
          salesByDay[dayKey] = salesByDay[dayKey]! + order.totalAmount;
        }
      }
      // Populate expense data
      for (var expense in widget.expenses) { // New
        final dayKey = DateTime(expense.date.year, expense.date.month, expense.date.day);
        if (expensesByDay.containsKey(dayKey)) {
          expensesByDay[dayKey] = expensesByDay[dayKey]! + expense.amount;
        }
      }

      // Sort sales and convert to FlSpots
      final sortedSales = salesByDay.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
      // Sort expenses and convert to FlSpots
      final sortedExpenses = expensesByDay.entries.toList()..sort((a, b) => a.key.compareTo(b.key)); // New

      revenueSpots = [];
      expenseSpots = []; // New

      final bool useShortFormat = daysInRange <= 7;
      for (int i = 0; i < sortedSales.length; i++) {
        revenueSpots.add(FlSpot(i.toDouble(), sortedSales[i].value));
        expenseSpots.add(FlSpot(i.toDouble(), sortedExpenses[i].value)); // New
        xAxisLabels[i] = DateFormat(useShortFormat ? 'EEE' : 'MMM dd').format(sortedSales[i].key);
      }

      minX = 0;
      maxX = (revenueSpots.isEmpty ? 0 : revenueSpots.length - 1).toDouble();

      // Set Title
      if (widget.filter == DateFilter.last7Days) chartTitle = "Trend (7 Days)";
      else if (widget.filter == DateFilter.last30Days) chartTitle = "Trend (30 Days)";
      else chartTitle = "Revenue vs Expense Trend";

      // Set *default* Titles
      titlesData = FlTitlesData(
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles:false)),
        leftTitles: leftTitles,
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          // Dynamic interval to avoid cluttered labels
          interval: daysInRange <= 8 ? 1 : (daysInRange / 6).roundToDouble(),
          getTitlesWidget: (value, meta) {
            final label = xAxisLabels![value.toInt()];
            if (label == null) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(label, style: const TextStyle(fontSize: 10)),
            );
          },
        )),
      );
    }

    // --- 3. Create the Chart Data ---
    final LineChartData data = LineChartData(
      minX: minX,
      maxX: maxX,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.shade200,
          strokeWidth: 1,
        ),
      ),
      titlesData: titlesData,
      borderData: FlBorderData(show: false),
      // --- 8. ADD TWO LINES TO CHART ---
      lineBarsData: [
        // Revenue Line
        LineChartBarData(
          spots: revenueSpots,
          isCurved: true,
          color: Theme.of(context).colorScheme.primary,
          barWidth: 4,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
        ),
        // Expense Line
        LineChartBarData(
          spots: expenseSpots,
          isCurved: true,
          color: Colors.red.shade400,
          barWidth: 2,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.red.withOpacity(0.2),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(),
        handleBuiltInTouches: true,
      ),
    );

    // --- 4. Return the new Interactive Widget ---
    return _InteractiveSalesChart(
      // key is provided by the parent widget
      title: chartTitle,
      chartData: data,
      isSingleDayView: isSingleDayView,
      dailyXAxisLabels: xAxisLabels,
    );
  }
}

// --- WIDGET FOR ZOOM/PAN (WITH DYNAMIC LABELS) ---
// This is now a private widget within sales_chart_widget.dart
class _InteractiveSalesChart extends StatefulWidget {
  final String title;
  final LineChartData chartData;
  final bool isSingleDayView;
  final Map<int, String>? dailyXAxisLabels;

  const _InteractiveSalesChart({
    // key is passed down from the parent
    super.key,
    required this.title,
    required this.chartData,
    required this.isSingleDayView,
    this.dailyXAxisLabels,
  });

  @override
  State<_InteractiveSalesChart> createState() => _InteractiveSalesChartState();
}

class _InteractiveSalesChartState extends State<_InteractiveSalesChart> {
  // Store the current horizontal (X-axis) zoom/pan state
  late double _minX;
  late double _maxX;

  // Store the state from onScaleStart
  late double _baseMinX;
  late double _baseMaxX;
  late double _baseFocalX; // Store the initial touch point

  @override
  void initState() {
    super.initState();
    _resetZoom();
  }

  // When the parent widget passes a new chartData (due to filter change),
  // this is called. We reset the zoom.
  @override
  void didUpdateWidget(covariant _InteractiveSalesChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset if the base data has changed
    if (oldWidget.chartData.minX != widget.chartData.minX ||
        oldWidget.chartData.maxX != widget.chartData.maxX) {
      _resetZoom();
    }
  }

  void _resetZoom() {
    _minX = widget.chartData.minX;
    _maxX = widget.chartData.maxX;
  }

  @override
  Widget build(BuildContext context) {

    // --- DYNAMIC TITLES LOGIC ---
    FlTitlesData dynamicTitlesData = widget.chartData.titlesData;
    final double currentXRange = _maxX - _minX;

    if (widget.isSingleDayView) {
      // --- Hourly Dynamic Titles ---
      double interval;
      if (currentXRange <= 6) {
        interval = 1; // Show every hour
      } else if (currentXRange <= 12) {
        interval = 2; // Show every 2 hours
      } else if (currentXRange <= 18) {
        interval = 4; // Show every 4 hours
      } else {
        interval = 6; // Default: 12AM, 6AM, 12PM, 6PM
      }

      dynamicTitlesData = dynamicTitlesData.copyWith(
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          interval: interval,
          getTitlesWidget: (value, meta) {
            final int hour = value.toInt();
            if (value < _minX || value > _maxX) return const SizedBox();
            String text;
            if (hour == 0) text = '12AM';
            else if (hour < 12) text = '${hour}AM';
            else if (hour == 12) text = '12PM';
            else text = '${hour - 12}PM';
            if (value != hour.toDouble()) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(text, style: const TextStyle(fontSize: 10)),
            );
          },
        )),
      );

    } else if (widget.dailyXAxisLabels != null) {
      // --- Daily Dynamic Titles ---
      final Map<int, String> labels = widget.dailyXAxisLabels!;
      double interval;

      if (currentXRange <= 7) {
        interval = 1; // Show every day
      } else if (currentXRange <= 14) {
        interval = 2; // Show every 2 days
      } else {
        interval = (currentXRange / 6).roundToDouble();
      }
      if (interval < 1) interval = 1;

      dynamicTitlesData = dynamicTitlesData.copyWith(
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          interval: interval,
          getTitlesWidget: (value, meta) {
            final int index = value.toInt();
            if (value < _minX || value > _maxX) return const SizedBox();
            final label = labels[index];
            if (label == null) return const SizedBox();
            if (value != index.toDouble()) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(label, style: const TextStyle(fontSize: 10)),
            );
          },
        )),
      );
    }
    // --- END DYNAMIC TITLES LOGIC ---

    // Create a new chart data object based on our current zoom state
    final LineChartData currentChartData = widget.chartData.copyWith(
      minX: _minX,
      maxX: _maxX,
      minY: null, // Let fl_chart auto-scale the Y-axis
      maxY: null, // Let fl_chart auto-scale the Y-axis
      titlesData: dynamicTitlesData,
      lineTouchData: widget.chartData.lineTouchData.copyWith(
        handleBuiltInTouches: false,
      ),
      clipData: FlClipData.all(),
    );

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Chart Title & Reset Button ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_out_map),
                onPressed: () => setState(_resetZoom),
                tooltip: 'Reset Zoom',
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            ],
          ),
          const SizedBox(height: 12),
          // --- Chart with Gesture Detector ---
          Expanded(
            child: GestureDetector(
              onScaleStart: (details) {
                // Save the current state when the gesture begins
                _baseMinX = _minX;
                _baseMaxX = _maxX;
                _baseFocalX = details.focalPoint.dx; // Store starting focal point
              },
              onScaleUpdate: (details) {
                final double hScale = details.horizontalScale;
                final double oldXRange = _baseMaxX - _baseMinX;
                final double newXRange = oldXRange / hScale;
                if (newXRange > (widget.chartData.maxX - widget.chartData.minX)) {
                  setState(_resetZoom);
                  return;
                }
                if (newXRange < 1) {
                  return;
                }
                final double totalPanPixels = details.focalPoint.dx - _baseFocalX;
                final double totalPanChart = -(totalPanPixels / context.size!.width) * oldXRange;
                final double scaleChange = (newXRange - oldXRange) / 2;
                double newMinX = _baseMinX - scaleChange + totalPanChart;
                double newMaxX = _baseMaxX + scaleChange + totalPanChart;
                if (newMinX < widget.chartData.minX) {
                  final delta = widget.chartData.minX - newMinX;
                  newMinX += delta;
                  newMaxX += delta;
                }
                if (newMaxX > widget.chartData.maxX) {
                  final delta = newMaxX - widget.chartData.maxX;
                  newMinX -= delta;
                  newMaxX -= delta;
                }
                setState(() {
                  _minX = newMinX;
                  _maxX = newMaxX;
                });
              },
              child: LineChart(
                currentChartData,
              ),
            ),
          ),
        ],
      ),
    );
  }
}