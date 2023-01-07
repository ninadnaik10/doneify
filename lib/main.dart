import 'dart:developer';
import 'dart:ffi';
import 'dart:io';
import 'package:conquer_flutter_app/components/EachTodo.dart';
import 'package:conquer_flutter_app/globalColors.dart';
import 'package:conquer_flutter_app/impClasses.dart';
import 'package:conquer_flutter_app/pages/Day.dart';
import 'package:conquer_flutter_app/pages/InputModal.dart';
import 'package:conquer_flutter_app/pages/Todos.dart';
import 'package:conquer_flutter_app/states/initStates.dart';
import 'package:conquer_flutter_app/states/labelDAO.dart';
import 'package:conquer_flutter_app/states/selectedFilters.dart';
import 'package:conquer_flutter_app/states/startTodos.dart';
import 'package:conquer_flutter_app/states/todoDAO.dart';
import 'package:conquer_flutter_app/timeFuncs.dart';
import 'package:flutter/material.dart';
import 'package:conquer_flutter_app/pages/Home.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:home_widget/home_widget.dart';
import 'package:sembast/sembast.dart';

final channel = MethodChannel('alarm_method_channel');
void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // HomeWidget.registerBackgroundCallback(
  //     backgroundCallback); //replace this with method channel
  runApp(const MyApp());
}

Future registerDB() async {
  await GetItRegister().initializeGlobalStates();
  LabelDAO labelsDB = GetIt.I.get();
  SelectedFilters selectedFilters = GetIt.I.get();
  StartTodos startTodos = GetIt.I.get();

  //don't fuck up this order
  await selectedFilters.fetchFiltersFromStorage();
  await labelsDB.readLabelsFromStorage();
  await startTodos.loadTodos();
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void handleKotlinEvents() async {
    channel.setMethodCallHandler((call) async {
      debugPrint(
          "call received method ${call.method} argument ${call.arguments}");
      if (call.method == 'task_done') {
        await registerDB();
        debugPrint("loaded stuff");
        TodoDAO todosdb = GetIt.I.get();
        Todo? todo = await todosdb.getTodo(int.parse(call.arguments));
        debugPrint("fetched todo $todo");
        todo!.finished = true;
        await todosdb.updateTodo(todo);
        await editAlarms(todo.id, true);

        setState(() {});
      }
      return Future<dynamic>.value();
    });
  }

  @override
  void initState() {
    handleKotlinEvents();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: "EuclidCircular",
      ),
      onGenerateRoute: (RouteSettings settings) {
        String? entirePath = settings.name;
        return MaterialPageRoute(
          builder: (context) => MainContainer(entirePath: entirePath ?? "/"),
        );
      },
    );
  }
}

class MainContainer extends StatefulWidget {
  String entirePath;
  MainContainer({super.key, required this.entirePath});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  String? path;
  String? timeType;
  int? todoId;

  @override
  void initState() {
    debugPrint("entire path ${widget.entirePath}");
    path = widget.entirePath.split("?")[0];

    if (path == "/createInputModal") {
      timeType = widget.entirePath.split("?")[1];
    } else if (path == "/editInputModal") {
      todoId = int.parse(widget.entirePath.split("?")[1]);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        body: Center(
            child: FutureBuilder(
                future: registerDB(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    TodoDAO todosdb = GetIt.I.get();
                    switch (path) {
                      case '/createInputModal':
                        return WillPopScope(
                          onWillPop: () async {
                            debugPrint("going back");
                            SystemChannels.platform
                                .invokeMethod<void>('SystemNavigator.pop');
                            return true;
                          },
                          child: InputModal(
                            goBack: () {
                              SystemChannels.platform.invokeMethod<void>(
                                  'SystemNavigator.pop'); // debugPrint("entire path $entirePath");
                            },
                            timeType: timeType!,
                            time: formattedTime(timeType!, DateTime.now()),
                            onCreate: (Todo todo) async {
                              await todosdb.createTodo(todo);
                              setState(() {});
                            },
                          ),
                        );
                      case "/editInputModal":
                        // debugPrint(
                        //     "todoId $todoId time $time timeType $timeType");
                        return WillPopScope(
                          onWillPop: () async {
                            debugPrint("going back");
                            SystemChannels.platform
                                .invokeMethod<void>('SystemNavigator.pop');
                            return true;
                          },
                          child: InputModal(
                            goBack: () {
                              SystemChannels.platform
                                  .invokeMethod<void>('SystemNavigator.pop');
                            },
                            todoId: todoId!,
                            onEdit: (Todo todo) async {
                              await todosdb.updateTodo(todo);
                              setState(() {});
                            },
                            onDelete: () async {
                              todosdb.deleteTodo(todoId!);
                              setState(() {});
                              SystemChannels.platform
                                  .invokeMethod<void>('SystemNavigator.pop');
                            },
                          ),
                        );
                      case "/":
                        return HomePage(key: UniqueKey());
                      default:
                        debugPrint("default contianer");
                        return HomePage(
                            // key: UniqueKey()
                            );
                    }
                  } else {
                    return Container(
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                })),
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
