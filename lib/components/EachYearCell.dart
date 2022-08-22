import 'package:conquer_flutter_app/components/EachWeekCell.dart';
import 'package:conquer_flutter_app/globalColors.dart';
import 'package:conquer_flutter_app/pages/Day.dart';
import 'package:conquer_flutter_app/pages/Week.dart';
import 'package:conquer_flutter_app/pages/Year.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class EachYearCell extends StatefulWidget {
  DateTime date;
  List<String> unfinishedYears;
  DateRangePickerView? currentView;

  EachYearCell({
    Key? key,
    required this.date,
    required this.unfinishedYears,
    required this.currentView,
  }) : super(key: key);

  @override
  State<EachYearCell> createState() => _EachYearCellState();
}

class _EachYearCellState extends State<EachYearCell> {
  @override
  Widget build(BuildContext context) {
    return Container(
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.all(Radius.circular(30)),
      //   color: DateTime.now().month == widget.date.month &&
      //           DateTime.now().year == widget.date.year
      //       ? themePurple
      //       : Colors.transparent,
      // ),
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          // Align(
          //   alignment: AlignmentDirectional.topStart, // <-- SEE HERE
          //   child: Container(
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              color: DateTime.now().year == widget.date.year
                  ? themePurple
                  : Colors.transparent,
            ),
            width: 90,
            height: 50,
          ),
          // ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.date.year.toString(),
                style: DateTime.now().year == widget.date.year
                    ? TextStyle(
                        color: widget.unfinishedYears
                                .contains(formattedYear(widget.date))
                            ? Color.fromARGB(255, 170, 0, 0)
                            : Color.fromARGB(255, 47, 15, 83),
                        fontSize: 15,
                        fontFamily: 'EuclidCircular',
                        fontWeight: FontWeight.w600,
                      )
                    : TextStyle(
                        color: widget.unfinishedYears
                                .contains(formattedYear(widget.date))
                            ? Color.fromARGB(255, 255, 105, 105)
                            : Color.fromARGB(255, 255, 255, 255),
                        fontSize: 15,
                        fontFamily: 'EuclidCircular',
                        fontWeight: FontWeight.w400,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
