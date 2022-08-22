import 'package:animations/animations.dart';
import 'package:conquer_flutter_app/components/FiltersDialog.dart';
import 'package:conquer_flutter_app/globalColors.dart';
import 'package:conquer_flutter_app/pages/InputModal.dart';
import 'package:flutter/material.dart';

class BottomButtons extends StatefulWidget {
  String time;
  String timeType;
  int index;
  final Function loadTodos;
  final Function createTodo;

  BottomButtons({
    Key? key,
    required this.time,
    required this.timeType,
    required this.index,
    required this.loadTodos,
    required this.createTodo,
  }) : super(key: key);

  @override
  State<BottomButtons> createState() => _BottomButtonsState();
}

class _BottomButtonsState extends State<BottomButtons> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      //! bottom buttons
      child: Align(
        alignment: FractionalOffset.bottomRight,
        child: Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 15, 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                tooltip: "Choose label",
                onPressed: () {
                  showGeneralDialog(
                    //! select filter dialog box
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: "Choose filters",
                    pageBuilder: (BuildContext context,
                        Animation<double> animation,
                        Animation<double> secondaryAnimation) {
                      return Container();
                    },
                    transitionBuilder: (ctx, a1, a2, child) {
                      var curve = Curves.easeInOut.transform(a1.value);
                      return FiltersDialog(
                        curve: curve,
                        reloadTodos: widget.loadTodos(),
                        homePage: true,
                        // currentFirst: currentFirst,
                        // ascending: ascending,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  );
                },
                backgroundColor:
                    Color.fromARGB(255, 48, 48, 48).withOpacity(0.9),
                child: const Icon(
                  Icons.filter_list,
                  size: 30,
                  color: Color.fromARGB(255, 206, 206, 206),
                ),
              ),
              const SizedBox(
                width: 35,
              ),
              OpenContainer(
                useRootNavigator: true,
                closedShape: const CircleBorder(),
                closedColor: themePurple.withOpacity(0.9),
                transitionDuration: const Duration(milliseconds: 500),
                closedBuilder: (context, action) {
                  return FloatingActionButton(
                    tooltip: "Add New Task",
                    onPressed: () {
                      action.call();
                    },
                    backgroundColor: themePurple.withOpacity(0.9),
                    child: const Icon(
                      Icons.add,
                      size: 30,
                      color: Color.fromARGB(255, 47, 15, 83),
                    ),
                  );
                },
                openBuilder: (context, action) {
                  return InputModal(
                    action: action,
                    addTodo: widget.createTodo,
                    time: widget.time, //time
                    timeType: widget.timeType,
                    index: widget.index, //index
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}