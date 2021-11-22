import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Socket socket;
  TextEditingController host;
  TextEditingController port;
  TextEditingController data;

  List<String> datas;

  StreamSubscription dataSubscription;

  @override
  void initState() {
    super.initState();
    socket = null;
    host = TextEditingController(text: "192.168.43.21");
    port = TextEditingController(text: "5000");
    data = TextEditingController(text: "");
    datas = [];
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }

  void sendMessage(Socket socket, String message) {
    socket.write(message);
  }

  void subscribe() {
    dataSubscription = socket.listen((data) {
      String temp = String.fromCharCodes(data);
      String res = temp.substring(2);
      int idx = datas.indexOf(res);
      if (idx == -1) {
        setState(() => datas = [res, ...datas]);
      } else
        setState(() {
          final String temp = datas.removeAt(idx);
          datas = [temp, ...datas];
        });
    });
  }

  void connect() async {
    try {
      socket = await Socket.connect(host.text, int.tryParse(port.text));
      print(
          "Connected to: ${socket.remoteAddress.address}:${socket.remotePort}");
    } catch (e) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(e.toString()),
          ),
        );
    }
    subscribe();
    setState(() {});
    onRead();
  }

  void disconnect() async {
    setState(() {
      dataSubscription.cancel();
      socket.destroy();
      socket.flush();
      socket.close();
      socket = null;
    });
  }

  void onSelect(int idx) {
    setState(() {
      final String temp = datas[idx];
      datas[idx] = datas[0];
      datas[0] = temp;
      // datas = [temp, ...datas];
    });
    sendMessage(socket, "w>" + datas[0]);
  }

  void onRead() {
    sendMessage(socket, "r");
  }

  void clear() {
    setState(() {
      datas = [datas[0]];
    });
  }

  void delete(int idx) {
    setState(() {
      datas.removeAt(idx);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      extendBody: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        brightness: Brightness.dark,
        backgroundColor: socket == null ? Colors.redAccent : Colors.green,
        toolbarHeight: 20,
        centerTitle: true,
        title: Text(
          socket == null
              ? "Not connected"
              : "Connected to: ${socket.remoteAddress.address}:${socket.remotePort}",
          style: Theme.of(context).textTheme.overline,
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        notchMargin: 40,
        shape: CircularNotchedRectangle(),
        color: Colors.blue,
        child: IconTheme(
          data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
          child: Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {},
              ),
              Spacer(),
              // IconButton(
              //   icon: const Icon(Icons.search),
              //   onPressed: () {},
              // ),
              if (socket != null)
                IconButton(
                  icon: const Icon(Icons.power_off),
                  onPressed: disconnect,
                ),
            ],
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (socket == null) ...[
              Padding(
                padding: const EdgeInsets.all(30),
                child: TextField(
                  controller: host,
                  decoration: InputDecoration(labelText: "host"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(30),
                child: TextField(
                  controller: port,
                  decoration: InputDecoration(labelText: "port"),
                ),
              ),
            ] else ...[
              Expanded(
                child: RefreshIndicator(
                  displacement: 10,
                  triggerMode: RefreshIndicatorTriggerMode.anywhere,
                  onRefresh: () {
                    onRead();
                    HapticFeedback.heavyImpact();
                    return Future.delayed(Duration.zero);
                  },
                  child: ListView(
                    children: ListTile.divideTiles(
                      color: Colors.grey,
                      context: context,
                      tiles: List.generate(datas.length, (index) {
                        return Dismissible(
                          confirmDismiss: (dir) async {
                            if (index != 0) if (dir ==
                                DismissDirection.endToStart) return true;
                            return false;
                          },
                          key: Key(datas[index]),
                          behavior: HitTestBehavior.translucent,
                          onDismissed: (direction) {
                            delete(index);
                            // ScaffoldMessenger.of(context)
                            //   ..removeCurrentSnackBar()
                            //   ..showSnackBar(
                            //     SnackBar(
                            //       action: SnackBarAction(
                            //           label: "Undo", onPressed: () {}),
                            //       behavior: SnackBarBehavior.floating,
                            //       content: Text('Removed'),
                            //     ),
                            //   );
                          },
                          child: ListTile(
                            dense: true,
                            // visualDensity: VisualDensity.compact,
                            tileColor:
                                index == 0 ? Colors.lightBlue[100] : null,
                            onTap: () => onSelect(index),
                            title: Text(
                              datas[index]
                                  .replaceAll(RegExp('\\s\\s'), "")
                                  .trim(),
                              style: GoogleFonts.robotoMono(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }),
                    ).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: socket == null ? Icon(Icons.power) : Icon(Icons.delete),
        onPressed: socket == null ? connect : clear,
      ),
    );
  }
}
