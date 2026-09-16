import "dart:async";
import "package:flutter/material.dart";
import "package:vdoninja_sdk/vdoninja_sdk.dart";

void main() {
  runApp(const VDONinjaTestApp());
}

class VDONinjaTestApp extends StatelessWidget {
  const VDONinjaTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "VDO.Ninja SDK Integration Test",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C5CE7),
        brightness: Brightness.dark,
        fontFamily: "Inter",
      ),
      home: const IntegrationTestPage(),
    );
  }
}

/// Represents a single logged event row.
class EventLogEntry {
  final DateTime timestamp;
  final String eventType;
  final String summary;
  final Map<String, dynamic>? details;

  EventLogEntry({required this.eventType, required this.summary, this.details})
    : timestamp = DateTime.now();
}

class IntegrationTestPage extends StatefulWidget {
  const IntegrationTestPage({super.key});

  @override
  State<IntegrationTestPage> createState() => _IntegrationTestPageState();
}

class _IntegrationTestPageState extends State<IntegrationTestPage> {
  final _hostController = TextEditingController(text: "wss://wss.vdo.ninja");
  final _roomController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();

  VDONinjaSDK? _sdk;
  bool _sdkInitialized = false;
  bool _connecting = false;
  bool _connected = false;
  String? _statusMessage;
  final List<EventLogEntry> _eventLog = [];
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _initializeSDK();
  }

  Future<void> _initializeSDK() async {
    try {
      await VDONinjaSDK.initialize();
      setState(() {
        _sdkInitialized = true;
        _addLog("system", "SDK initialized successfully");
      });
    } catch (e) {
      setState(() {
        _addLog("error", "SDK initialization failed: $e");
      });
    }
  }

  void _addLog(
    String eventType,
    String summary, [
    Map<String, dynamic>? details,
  ]) {
    _eventLog.insert(
      0,
      EventLogEntry(eventType: eventType, summary: summary, details: details),
    );
    // Keep max 500 entries
    if (_eventLog.length > 500) {
      _eventLog.removeLast();
    }
  }

  Future<void> _connect() async {
    if (!_sdkInitialized) {
      setState(() => _addLog("error", "SDK not yet initialized"));
      return;
    }

    final host = _hostController.text.trim();
    final room = _roomController.text.trim();
    final password = _passwordController.text.trim();

    if (room.isEmpty) {
      setState(() => _addLog("error", "Room name is required"));
      return;
    }

    setState(() {
      _connecting = true;
      _statusMessage = "Connecting...";
      _addLog("system", "Creating SDK instance...", {
        "host": host,
        "room": room,
        "password": password.isNotEmpty ? "***" : "(none)",
      });
    });

    try {
      _sdk = VDONinjaSDK(
        host: host.isNotEmpty ? host : null,
        room: room,
        password: password.isNotEmpty ? .string(password) : .disable,
        debug: true,
      );

      _subscribeToEvents();

      setState(() => _addLog("system", "Calling autoConnect..."));

      // final controller = await _sdk!.autoConnect(
      //   room: room,
      //   password: password.isNotEmpty
      //       ? VDONinjaPassword.string(password)
      //       : null,
      //   //mode: "half",
      //   view: {"audio": false, "video": false, "label": "dock"},
      // );
      await _sdk!.connect();
      await _sdk!.joinRoom();
      //await _sdk!.announce(streamID: "octostream-app");
      await _sdk!.view(room, audio: false, video: false, label: "dock");

      setState(() {
        _connecting = false;
        _connected = true;
        _statusMessage = "Connected (streamID: ${_sdk!.streamID})";
        _addLog("system", "autoConnect succeeded", {
          "streamID": _sdk!.streamID,
        });
      });
    } catch (e) {
      setState(() {
        _connecting = false;
        _statusMessage = "Connection failed";
        _addLog("error", "Connection failed: $e");
      });
    }
  }

  void _subscribeToEvents() {
    final sdk = _sdk!;

    _subscriptions.add(
      sdk.onConnected.listen((_) {
        setState(() => _addLog("connected", "Connected to signaling server"));
      }),
    );

    _subscriptions.add(
      sdk.onDisconnected.listen((_) {
        setState(() {
          _connected = false;
          _addLog("disconnected", "Disconnected from signaling server");
        });
      }),
    );

    _subscriptions.add(
      sdk.onReconnecting.listen((data) {
        setState(() => _addLog("reconnecting", "Reconnecting...", data));
      }),
    );

    _subscriptions.add(
      sdk.onReconnected.listen((_) {
        setState(() => _addLog("reconnected", "Reconnected to signaling"));
      }),
    );

    _subscriptions.add(
      sdk.onReconnectFailed.listen((_) {
        setState(() => _addLog("error", "All reconnection attempts failed"));
      }),
    );

    _subscriptions.add(
      sdk.onRoomJoined.listen((data) {
        setState(() => _addLog("roomJoined", "Room joined", data));
      }),
    );

    _subscriptions.add(
      sdk.onRoomLeft.listen((data) {
        setState(() => _addLog("roomLeft", "Room left", data));
      }),
    );

    _subscriptions.add(
      sdk.onPublishing.listen((data) {
        setState(() => _addLog("publishing", "Publishing started", data));
      }),
    );

    _subscriptions.add(
      sdk.onViewingStopped.listen((data) {
        setState(() => _addLog("viewingStopped", "Viewing stopped", data));
      }),
    );

    _subscriptions.add(
      sdk.onTrack.listen((event) {
        setState(
          () => _addLog("track", event.toString(), {
            "uuid": event.uuid,
            "streamID": event.streamID,
          }),
        );
      }),
    );

    _subscriptions.add(
      sdk.onDataReceived.listen((event) {
        setState(
          () => _addLog("dataReceived", event.toString(), {
            "uuid": event.uuid,
            "streamID": event.streamID,
            "data": event.data?.toString(),
          }),
        );
      }),
    );

    _subscriptions.add(
      sdk.onPeerConnected.listen((data) {
        setState(() => _addLog("peerConnected", "Peer connected", data));
      }),
    );

    _subscriptions.add(
      sdk.onPeerLatency.listen((event) {
        setState(
          () => _addLog("peerLatency", event.toString(), {
            "uuid": event.uuid,
            "latency": event.latency,
          }),
        );
      }),
    );

    _subscriptions.add(
      sdk.onPeerInfo.listen((event) {
        setState(
          () => _addLog("peerInfo", event.toString(), {
            "uuid": event.uuid,
            "info": event.info,
          }),
        );
      }),
    );

    _subscriptions.add(
      sdk.onRemoteVideoMuteState.listen((event) {
        setState(
          () => _addLog("remoteVideoMuteState", event.toString(), {
            "uuid": event.uuid,
            "muted": event.muted,
            "connectionType": event.connectionType,
          }),
        );
      }),
    );

    _subscriptions.add(
      sdk.onError.listen((event) {
        setState(
          () => _addLog("error", event.toString(), {
            "message": event.message,
            "details": event.details?.toString(),
          }),
        );
      }),
    );
  }

  void _disconnect() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    _sdk?.disconnect();
    setState(() {
      _connected = false;
      _connecting = false;
      _statusMessage = "Disconnected";
      _addLog("system", "Manually disconnected");
      _sdk = null;
    });
  }

  void _clearLog() {
    setState(() => _eventLog.clear());
  }

  @override
  void dispose() {
    _disconnect();
    _hostController.dispose();
    _roomController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Color _colorForEventType(String type) {
    return switch (type) {
      "system" => const Color(0xFF74B9FF),
      "connected" || "reconnected" => const Color(0xFF00CEC9),
      "disconnected" || "reconnecting" => const Color(0xFFFDCB6E),
      "roomJoined" => const Color(0xFF55EFC4),
      "roomLeft" => const Color(0xFFFAB1A0),
      "track" => const Color(0xFFA29BFE),
      "dataReceived" => const Color(0xFF81ECEC),
      "peerConnected" => const Color(0xFF55EFC4),
      "peerLatency" => const Color(0xFFDFE6E9),
      "peerInfo" => const Color(0xFFB2BEC3),
      "publishing" => const Color(0xFF6C5CE7),
      "viewingStopped" => const Color(0xFFE17055),
      "remoteVideoMuteState" => const Color(0xFFFD79A8),
      "error" => const Color(0xFFFF7675),
      _ => const Color(0xFFDFE6E9),
    };
  }

  IconData _iconForEventType(String type) {
    return switch (type) {
      "system" => Icons.settings,
      "connected" || "reconnected" => Icons.wifi,
      "disconnected" => Icons.wifi_off,
      "reconnecting" => Icons.sync,
      "roomJoined" => Icons.meeting_room,
      "roomLeft" => Icons.no_meeting_room,
      "track" => Icons.videocam,
      "dataReceived" => Icons.data_object,
      "peerConnected" => Icons.person_add,
      "peerLatency" => Icons.speed,
      "peerInfo" => Icons.info_outline,
      "publishing" => Icons.publish,
      "viewingStopped" => Icons.visibility_off,
      "remoteVideoMuteState" => Icons.videocam_off,
      "error" => Icons.error_outline,
      _ => Icons.circle,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0A1A),
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.stream,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "VDO.Ninja SDK — Integration Test",
                      key: Key("app-title"),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    _StatusBadge(
                      connected: _connected,
                      connecting: _connecting,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Row(
                  children: [
                    // Left Panel — Connection Form
                    SizedBox(
                      width: 360,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Form header
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                              ),
                              child: const Text(
                                "Connection",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  color: Color(0xFFA29BFE),
                                ),
                              ),
                            ),

                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildTextField(
                                      key: const Key("host-field"),
                                      controller: _hostController,
                                      label: "Host",
                                      hint: "wss://wss.vdo.ninja",
                                      icon: Icons.dns_outlined,
                                      enabled: !_connected && !_connecting,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      key: const Key("room-field"),
                                      controller: _roomController,
                                      label: "Room",
                                      hint: "Enter room name",
                                      icon: Icons.meeting_room_outlined,
                                      enabled: !_connected && !_connecting,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      key: const Key("password-field"),
                                      controller: _passwordController,
                                      label: "Password",
                                      hint: "Optional",
                                      icon: Icons.lock_outline,
                                      obscure: true,
                                      enabled: !_connected && !_connecting,
                                    ),
                                    const SizedBox(height: 24),
                                    if (!_connected)
                                      _buildGradientButton(
                                        key: const Key("connect-btn"),
                                        label: _connecting
                                            ? "Connecting..."
                                            : "Connect",
                                        onPressed: _connecting
                                            ? null
                                            : _connect,
                                        gradient: const [
                                          Color(0xFF6C5CE7),
                                          Color(0xFFA29BFE),
                                        ],
                                        icon: _connecting
                                            ? null
                                            : Icons.power_settings_new,
                                      )
                                    else
                                      _buildGradientButton(
                                        key: const Key("disconnect-btn"),
                                        label: "Disconnect",
                                        onPressed: _disconnect,
                                        gradient: const [
                                          Color(0xFFE17055),
                                          Color(0xFFFF7675),
                                        ],
                                        icon: Icons.power_off,
                                      ),
                                    if (_statusMessage != null) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.04,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          _statusMessage!,
                                          key: const Key("status-message"),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white.withValues(
                                              alpha: 0.6,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            // SDK state info
                            if (_sdk != null)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.06,
                                      ),
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildStateRow(
                                      "Connected",
                                      _sdk!.isConnected,
                                    ),
                                    _buildStateRow(
                                      "Room Joined",
                                      _sdk!.isRoomJoined,
                                    ),
                                    _buildStateRow(
                                      "Publishing",
                                      _sdk!.isPublishing,
                                    ),
                                    if (_sdk!.room != null)
                                      _buildInfoRow("Room", _sdk!.room!),
                                    if (_sdk!.streamID != null)
                                      _buildInfoRow(
                                        "Stream ID",
                                        _sdk!.streamID!,
                                      ),
                                    if (_sdk!.uuid != null)
                                      _buildInfoRow("UUID", _sdk!.uuid!),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Right Panel — Event Log
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Log header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    "Event Log",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                      color: Color(0xFFA29BFE),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF6C5CE7,
                                      ).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      "${_eventLog.length}",
                                      key: const Key("event-count"),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFA29BFE),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    key: const Key("clear-log-btn"),
                                    onPressed: _eventLog.isEmpty
                                        ? null
                                        : _clearLog,
                                    icon: const Icon(Icons.clear_all, size: 16),
                                    label: const Text(
                                      "Clear",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Log entries
                            Expanded(
                              child: _eventLog.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.inbox_outlined,
                                            size: 48,
                                            color: Colors.white.withValues(
                                              alpha: 0.15,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            "No events yet",
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.3,
                                              ),
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Connect to a room to start receiving data",
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.15,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      key: const Key("event-log-list"),
                                      controller: _scrollController,
                                      itemCount: _eventLog.length,
                                      padding: const EdgeInsets.all(8),
                                      itemBuilder: (context, index) {
                                        final entry = _eventLog[index];
                                        return _EventLogRow(
                                          key: Key("event-row-$index"),
                                          entry: entry,
                                          color: _colorForEventType(
                                            entry.eventType,
                                          ),
                                          icon: _iconForEventType(
                                            entry.eventType,
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: key,
          controller: controller,
          obscureText: obscure,
          enabled: enabled,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, size: 18),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF6C5CE7),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton({
    required Key key,
    required String label,
    required VoidCallback? onPressed,
    required List<Color> gradient,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: onPressed != null ? LinearGradient(colors: gradient) : null,
        color: onPressed == null ? Colors.grey.shade800 : null,
        borderRadius: BorderRadius.circular(10),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        key: key,
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? const Color(0xFF00CEC9) : const Color(0xFFFF7675),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const Spacer(),
          Text(
            value ? "Yes" : "No",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: value
                  ? const Color(0xFF00CEC9)
                  : Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFFA29BFE),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool connected;
  final bool connecting;

  const _StatusBadge({required this.connected, required this.connecting});

  @override
  Widget build(BuildContext context) {
    final (Color color, String text) = connected
        ? (const Color(0xFF00CEC9), "Connected")
        : connecting
        ? (const Color(0xFFFDCB6E), "Connecting...")
        : (Colors.white.withValues(alpha: 0.3), "Disconnected");

    return Container(
      key: const Key("status-badge"),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventLogRow extends StatefulWidget {
  final EventLogEntry entry;
  final Color color;
  final IconData icon;

  const _EventLogRow({
    super.key,
    required this.entry,
    required this.color,
    required this.icon,
  });

  @override
  State<_EventLogRow> createState() => _EventLogRowState();
}

class _EventLogRowState extends State<_EventLogRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final hasDetails = entry.details != null && entry.details!.isNotEmpty;
    final timeStr =
        "${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}.${entry.timestamp.millisecond.toString().padLeft(3, '0')}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasDetails
              ? () => setState(() => _expanded = !_expanded)
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.color.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.icon, size: 14, color: widget.color),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        entry.eventType,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: widget.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.summary,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: "monospace",
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    if (hasDetails) ...[
                      const SizedBox(width: 4),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ],
                  ],
                ),
                if (_expanded && hasDetails)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: entry.details!.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${e.key}: ",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: "monospace",
                                  color: widget.color.withValues(alpha: 0.7),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "${e.value}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: "monospace",
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
