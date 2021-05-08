import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox<String>('todos');
  await Hive.openBox<String>('dones');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Todo',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: Todo());
  }
}

class Todo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Todos"), actions: [
        IconButton(
            icon: Icon(Icons.done_all), onPressed: () => showDone(context))
      ]),
      body: todoList(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final todo = Hive.box<String>("todos");
          todo.add("New todo item");
        },
        tooltip: "New todo item",
        child: Icon(Icons.add),
      ),
    );
  }

  Widget todoList(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: Hive.box<String>("todos").listenable(),
        builder: (context, todos, widget) {
          return ListView.separated(
              padding: EdgeInsets.all(16.0),
              separatorBuilder: (context, index) => Divider(),
              itemCount: todos.length,
              itemBuilder: (context, index) => todoItem(context, index, todos));
        });
  }

  Widget todoItem(BuildContext context, int index, Box<String> todos) {
    final item = todos.getAt(index);
    return Dismissible(
        child: todoTile(context, item, index, todos),
        key: ValueKey(item),
        background: DoneBackground(),
        secondaryBackground: DeleteBackground(),
        onDismissed: (direction) {
          todos.deleteAt(index);
          if (direction == DismissDirection.startToEnd) {
            final dones = Hive.box<String>("dones");
            dones.add(item);
          }
        });
  }

  Widget todoTile(
      BuildContext context, String item, int index, Box<String> todos) {
    final controller = TextEditingController(text: item);
    return ListTile(
      title: TextField(
        controller: controller,
        decoration: InputDecoration(
            border: InputBorder.none, hintText: "Todo description"),
        onTap: () {
          controller.selection = TextSelection(
              baseOffset: 0, extentOffset: controller.value.text.length);
        },
        onSubmitted: (value) => todos.putAt(index, value),
      ),
      trailing: IconButton(
          icon: Icon(Icons.done),
          highlightColor: Colors.green,
          onPressed: () {
            final item = todos.getAt(index);
            todos.deleteAt(index);
            final dones = Hive.box<String>("dones");
            dones.add(item);
          }),
    );
  }

  void showDone(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) {
      return DoneScreen();
    }));
  }
}

class DoneScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Done")), body: doneList(context));
  }

  Widget doneList(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: Hive.box<String>("dones").listenable(),
        builder: (context, dones, child) {
          return ListView.separated(
              padding: EdgeInsets.all(16.0),
              separatorBuilder: (context, index) => Divider(),
              itemCount: dones.length,
              itemBuilder: (context, index) => doneTile(context, index, dones));
        });
  }

  Widget doneTile(BuildContext context, int index, Box<String> dones) {
    return ListTile(
        title: Text(dones.getAt(index)),
        trailing: Icon(Icons.undo),
        onTap: () {
          final item = dones.getAt(index);
          dones.deleteAt(index);
          final todos = Hive.box<String>("todos");
          todos.add(item);
        });
  }
}

class DoneBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.greenAccent,
        alignment: AlignmentDirectional.centerStart,
        child:
            Padding(padding: EdgeInsets.all(10.0), child: Icon(Icons.check)));
  }
}

class DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.redAccent,
        alignment: AlignmentDirectional.centerEnd,
        child:
            Padding(padding: EdgeInsets.all(10.0), child: Icon(Icons.delete)));
  }
}
