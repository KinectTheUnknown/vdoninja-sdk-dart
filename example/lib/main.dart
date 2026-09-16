import "package:flutter/material.dart";
import "package:vdoninja_sdk/vdoninja_sdk.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await VDONinjaSDK.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "VDO.Ninja SDK Example",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: "VDO.Ninja SDK Example"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final VDONinjaSDK sdk;
  bool _isConnected = false;
  bool _isPublishing = false;
  String _status = "Disconnected";

  @override
  void initState() {
    super.initState();
    sdk = VDONinjaSDK(
      room: "example_room_${DateTime.now().millisecondsSinceEpoch}",
      debug: true,
    );

    sdk.onConnected.listen((_) {
      setState(() {
        _isConnected = true;
        _status = "Connected";
      });
    });

    sdk.onDisconnected.listen((_) {
      setState(() {
        _isConnected = false;
        _status = "Disconnected";
      });
    });

    sdk.onPublishing.listen((event) {
      setState(() {
        _isPublishing = true;
        _status = "Publishing stream ID: ${sdk.streamID}";
      });
    });
  }

  void _connect() async {
    try {
      await sdk.joinRoom();
    } catch (e) {
      setState(() {
        _status = "Error joining room: $e";
      });
    }
  }

  void _disconnect() {
    sdk.disconnect();
    setState(() {
      _isConnected = false;
      _isPublishing = false;
      _status = "Disconnected";
    });
  }

  void _publish() async {
    try {
      // In a real app, you would pass a valid web.MediaStream here.
      // This is just a stub example to show the API flow.
      await sdk.announce();
      setState(() {
        _isPublishing = true;
        _status = "Announcing (Data Only)";
      });
    } catch (e) {
      setState(() {
        _status = "Error publishing: $e";
      });
    }
  }

  void _stopPublishing() {
    sdk.stopPublishing();
    setState(() {
      _isPublishing = false;
      _status = "Stopped Publishing";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Status: $_status"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isConnected ? _disconnect : _connect,
              child: Text(_isConnected ? "Disconnect" : "Connect"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: (_isConnected && !_isPublishing) ? _publish : null,
              child: const Text("Publish (Announce)"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isPublishing ? _stopPublishing : null,
              child: const Text("Stop Publishing"),
            ),
          ],
        ),
      ),
    );
  }
}
