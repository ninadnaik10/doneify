import 'dart:convert';

import 'package:doneify/impClasses.dart';
import 'package:doneify/ip.dart';
import 'package:doneify/pages/home.dart';
import 'package:doneify/states/alarmDAO.dart';
import 'package:doneify/states/authState.dart';
import 'package:doneify/states/labelDAO.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:home_widget/home_widget.dart';
import 'package:sembast/sembast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TodoDAO {
  final Database _db = GetIt.I.get();

  final StoreRef _store = intMapStoreFactory.store("todos");
  static const platform = MethodChannel('alarm_method_channel');

  Future syncOnlineDB() async {
    AuthState auth = GetIt.I.get();
    TodoDAO todosdb = GetIt.I.get();
    LabelDAO labelsdb = GetIt.I.get();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? lastOfflineUpdated = prefs.getInt('lastOfflineUpdated');
    // debugPrint("offline db was updated at $lastOfflineUpdated");
    debugPrint("user is ${auth.user.value!.token}");

    if (auth.user.value != null) {
      var response = await http.get(
        Uri.parse("$serverUrl/todos/$lastOfflineUpdated"),
        headers: {
          "Content-Type": "application/json",
          "authorization": auth.user.value!.token
        },
      );
      // debugPrint("todos reponse is ${response.body}");
      Map body = json.decode(response.body);
      if (body["message"] != "offline db up to date") {
        List newLabelList = body["labels"];
        List deletedLabelList = body["deletedLabels"];
        debugPrint("all labels are: $newLabelList");

        for (Map each in newLabelList) {
          debugPrint("each label is $each");
          Label label = Label.fromMap(each);
          Label? labelFromDB = labelsdb.getLabelById(label.id);
          if (labelFromDB == null) {
            debugPrint("gotta create ${label.name}");
            labelsdb.addLabel(label, true);
          } else {
            debugPrint("gotta update ${label.name}");
            labelsdb.editLabel(label, true);
          }
        }
        for (Map each in deletedLabelList) {
          int id = each["_id"];
          debugPrint("gotta delete $id");
          labelsdb.deleteLabel(id, true);
          // Todo todo = Todo.fromMap(each);
          // newTodos.add(todo);
        }

        List newTodoList = body["todos"];
        List deletedTodoList = body["deletedTodos"];
        debugPrint("all todos are: $newTodoList");
        // debugPrint("deleted todos are: $deletedTodoMap");

        // List<Todo> newTodos = [];
        for (Map each in newTodoList) {
          debugPrint("each todo is $each");
          Todo todo = Todo.fromMap(each);
          Todo? todoFromDb = await todosdb.getTodo(todo.id);
          if (todoFromDb == null) {
            debugPrint("gotta create ${todo.taskName}");
            await todosdb.createTodo(todo, true);
          } else {
            debugPrint("gotta update ${todo.taskName}");
            await todosdb.updateTodo(todo, true);
          }
        }
        for (Map each in deletedTodoList) {
          int id = each["_id"];
          debugPrint("gotta delete $id");
          await todosdb.deleteTodo(id, true);
          // Todo todo = Todo.fromMap(each);
          // newTodos.add(todo);
        }
        // debugPrint("todos reponse ${todos}");
      }
    }
  }

  Future createTodo(Todo todo, bool receivedFromServer) async {
    var finder = Finder(
      filter: Filter.equals(
        'time',
        todo.time,
      ),
      sortOrders: [
        SortOrder("index"),
      ],
    );
    final allTodos = await getAllTodos(finder);
    todo.index = receivedFromServer ? todo.index : allTodos.length;
    // }
    await _store.record(todo.id).put(_db, todo.toMap());
    debugPrint("created todo ${todo.taskName} ${todo.index}");

    Map newTodo = {
      "id": todo.id.toString(),
      "taskName": todo.taskName,
      "taskDesc": todo.taskDesc,
      "finished": todo.finished,
      "labelName": todo.labelName,
      "timeStamp": todo.timeStamp,
      "time": todo.time,
      "timeType": todo.timeType,
      "index": todo.index,
    };
    try {
      // debugPrint("creating todo for system ${todo.id}");
      platform.invokeMethod("createTodo", newTodo);
    } on PlatformException catch (e) {
      debugPrint("some fuckup happended while creating todo: $e");
    }

    if (!receivedFromServer) {
      socket?.emitWithAck("create_todo", json.encode(newTodo), ack: (response) {
        debugPrint("ack from server $response");
      });
    }

    HomeWidget.updateWidget(
      name: 'WidgetProvider',
      iOSName: 'WidgetProvider',
    );

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('lastOfflineUpdated', todo.timeStamp);
  }

  Future<Todo?> getTodo(int key) async {
    // debugPrint("tryna fetch a todo id: $key");
    final snapshot = await _store.record(key).getSnapshot(_db);
    Map<String, dynamic>? map = snapshot?.value as Map<String, dynamic>?;
    return Future<Todo?>.value(
        snapshot != null && map != null ? Todo.fromMap(map) : null);
  }

  Future<List<Todo>> getAllTodos(Finder finder) async {
    final snapshots = await _store.find(_db, finder: finder);

    List<Map<String, dynamic>> maps = snapshots
        .map((snapshot) => snapshot.value as Map<String, dynamic>)
        .toList();
    return maps.map((map) => Todo.fromMap(map)).toList(growable: true);
  }

  Future updateTodo(Todo todo, bool receivedFromServer) async {
    // debugPrint("updating todo id: ${todo.id}");
    Todo? prevTodo = await getTodo(todo.id);
    if (prevTodo!.time != todo.time && !receivedFromServer) {
      var finder = Finder(
        filter: Filter.equals(
          'time',
          prevTodo.time,
        ),
      );
      List<Todo> prevTodos = await getAllTodos(finder);
      prevTodos.forEach((element) {
        if (element.index > prevTodo.index) {
          element.index--;
          updateTodo(element, receivedFromServer);
        }
      });
      finder = Finder(
        filter: Filter.equals(
          'time',
          todo.time,
        ),
      );
      final presentTodos = await getAllTodos(finder);
      todo.index = presentTodos.length;
    }
    await _store.record(todo.id).put(_db, todo.toMap(), merge: true);
    debugPrint("updated todo ${todo.taskName} ${todo.index}");

    Map updatedTodo = {
      "id": todo.id.toString(),
      "taskName": todo.taskName,
      "taskDesc": todo.taskDesc,
      "finished": todo.finished,
      "labelName": todo.labelName,
      "timeStamp": todo.timeStamp,
      "time": todo.time,
      "timeType": todo.timeType,
      "index": todo.index,
    };
    try {
      // debugPrint("updating todo for system ${todo.id}");
      platform.invokeMethod("updateTodo", updatedTodo);
    } on PlatformException catch (e) {
      debugPrint("some fuckup happended while updating todo: $e");
    }

    AuthState auth = GetIt.I.get();
    if (!receivedFromServer) {
      socket?.emitWithAck(
        "update_todo",
        json.encode(updatedTodo),
        ack: (response) {
          debugPrint("ack from server $response");
        },
      );
    }

    HomeWidget.updateWidget(
      name: 'WidgetProvider',
      iOSName: 'WidgetProvider',
    );

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('lastOfflineUpdated', todo.timeStamp);
  }

  Future deleteTodo(int todoId, bool receivedFromServer) async {
    Todo? todo = await getTodo(todoId);
    // debugPrint("deleting todo id: $todoId");
    var finder = Finder(
      filter: Filter.equals(
        'time',
        todo!.time,
      ),
    );
    await _store.record(todoId).delete(_db);

    AlarmDAO alarmsdb = GetIt.I.get();
    List<Alarm> toDeleteAlarms = await alarmsdb.getAlarms(todoId);
    toDeleteAlarms.forEach((alarm) {
      alarmsdb.deleteAlarm(alarm.alarmId);
    });
    // debugPrint("working flawlessly till after alarms");

    try {
      // debugPrint("deleting todo for system ${todo.id}");
      platform.invokeMethod("deleteTodo", {
        "id": todo.id.toString(),
      });
    } on PlatformException catch (e) {
      debugPrint("some fuckup happended while deleting todo: $e");
    }

    if (!receivedFromServer) {
      final presentTodos = await getAllTodos(finder);
      presentTodos.forEach((element) async {
        if (element.index > todo.index) {
          element.index--;
          await updateTodo(element, receivedFromServer);
        }
      });
      socket?.emitWithAck(
        "delete_todo",
        json.encode({
          "id": todo.id.toString(),
          "timeStamp": DateTime.now().millisecondsSinceEpoch,
        }),
        ack: (response) {
          debugPrint("ack from server $response");
        },
      );
    }

    HomeWidget.updateWidget(
      name: 'WidgetProvider',
      iOSName: 'WidgetProvider',
    );

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('lastOfflineUpdated', todo.timeStamp);
  }

  Future rearrangeTodos(int oldIndex, int newIndex, String time) async {
    var finder = Finder(
      filter: Filter.equals(
        'time',
        time,
      ),
    );
    final todos = await getAllTodos(finder);
    if (newIndex > oldIndex) {
      todos.forEach((element) async {
        if (element.index == oldIndex) {
          element.index = newIndex;
          await updateTodo(element, false);
        } else if (element.index > oldIndex && element.index <= newIndex) {
          element.index -= 1;
          await updateTodo(element, false);
        }
      });
    } else if (oldIndex > newIndex) {
      todos.forEach((element) async {
        if (element.index == oldIndex) {
          element.index = newIndex;
          await updateTodo(element, false);
        } else if (element.index < oldIndex && element.index >= newIndex) {
          element.index += 1;
          await updateTodo(element, false);
        }
      });
    }
  }
}
