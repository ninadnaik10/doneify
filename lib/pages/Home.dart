import 'dart:convert';

import 'package:doneify/globalColors.dart';
import 'package:doneify/impClasses.dart';
import 'package:doneify/states/authState.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:get_it_mixin/get_it_mixin.dart';
import 'package:doneify/pages/LongTerm.dart';
import 'package:doneify/pages/Month.dart';
import 'package:doneify/pages/Week.dart';
import 'package:doneify/pages/Year.dart';
import 'package:doneify/pages/Day.dart';
import 'package:doneify/pages/Settings.dart';
import 'package:doneify/icons/time_type_icons.dart';
import 'package:doneify/navigatorKeys.dart';
import 'package:doneify/states/labelDAO.dart';
import 'package:doneify/states/selectedFilters.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

IO.Socket? socket;

void initSocket(String token) {
  debugPrint("connection token is $token");

  socket?.auth = {"auth_token": token};
  socket?.connect();
  socket?.onConnect((_) {
    print('Connection established');
  });

  socket?.on('todo_operation', (data) {
    //this works only for create, have to make changes to server to make it work for update and delete
    // debugPrint("new todo ${todo}");
    // Todo todoObj = Todo.fromMap(json.decode(todo));
    // debugPrint(todoObj.taskName);
    debugPrint("real time data is $data");
  });
  socket?.onDisconnect((_) => print('Connection Disconnection'));
  socket?.onConnectError((err) => print(err));
  socket?.onError((err) => print(err));
}

class HomePage extends StatefulWidget with GetItStatefulWidgetMixin {
  // String? launchFromWidgetTimeType;
  // String? launchFromWidgetCommand;
  HomePage({
    Key? key,
    // required this.launchFromWidgetTimeType,
    // required this.launchFromWidgetCommand,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with GetItStateMixin {
  int currentPage = 0;
  var timeTypeMap = {
    'Day': 0,
    'Week': 1,
    "Month": 2,
    "Year": 3,
    "Long Term": 4
  };

  @override
  void initState() {
    super.initState();
    debugPrint("home rendered");

    socket = IO.io(serverUrl, <String, dynamic>{
      'autoConnect': false,
      'transports': ['websocket'],
    });

    // debugPrint("In Home ${widget.launchFromWidgetTimeType}");
    // if (widget.launchFromWidgetTimeType == null) {
    //   currentPage = 5;
    // } else {
    //   currentPage = timeTypeMap[widget.launchFromWidgetTimeType]!;
    // }
    // currentPage = timeType != null ? timeTypeMap[timeType]! : 0;
  }

  @override
  Widget build(BuildContext context) {
    User? user = watchX((AuthState auth) => auth.user);
    if (user != null) {
      initSocket(user.token);
    } else {
      socket?.disconnect();
    }

    return WillPopScope(
      onWillPop: () async {
        if (navigatorKeys[currentPage].currentState!.canPop()) {
          navigatorKeys[currentPage]
              .currentState!
              .pop(navigatorKeys[currentPage].currentContext);
        }
        return false;
        //below code does navigate me back to the home page if I am on day page, but when I enter the app again and go to todos page, it navigates to homescreen if I press back button.
        // else {
        //   SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
        // }
      },
      child: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xff404049),
                Color(0xff09090E),
              ],
            ),
          ),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: IndexedStack(
              index: currentPage,
              children: [
                DayNavigator(),
                WeekNavigator(),
                MonthNavigator(),
                YearNavigator(),
                LongTermPage(),
                SettingsNavigator()
              ],
            ),
            backgroundColor: Colors.transparent,
            bottomNavigationBar: GNav(
              tabBorderRadius: 25,
              gap: 5, // the tab button gap between icon and text
              color: const Color(0xff9A9A9A),
              activeColor: themeDarkPurple, // selected icon and text color
              tabBackgroundColor:
                  themePurple.withOpacity(0.9), // selected tab background color
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 15), // navigation bar padding

              tabs: const [
                GButton(
                  icon: TimeTypeIcons.day,
                  text: "Day",
                ),
                GButton(
                  icon: TimeTypeIcons.week,
                  text: "Week",
                ),
                GButton(
                  icon: TimeTypeIcons.month,
                  text: "Month",
                ),
                GButton(
                  icon: TimeTypeIcons.year,
                  text: "Year",
                ),
                GButton(
                  icon: TimeTypeIcons.longterm,
                  text: "Long Term",
                ),
                GButton(
                  icon: Icons.settings,
                  text: "Settings",
                ),
              ],
              selectedIndex: currentPage,
              onTabChange: (index) {
                setState(() {
                  currentPage = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
