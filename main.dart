// A single-file Flutter application for the ESP32 smart bottle.
// It visualizes water level and allows control via MQTT.

import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Bottle App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SignInPage(),
        '/home': (context) => const SmartBottleApp(),
      },
    );
  }
}

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Welcome text and app logo
              SvgPicture.string(
                '''
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" class="w-24 h-24 text-blue-500">
                    <path d="M16 10H8" />
                    <path d="M12 2a4 4 0 0 0-4 4v11a5 5 0 0 0 10 0V6a4 4 0 0 0-4-4z" />
                    <path d="M12 17h.01" />
                  </svg>
                ''',
                width: 96,
                height: 96,
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to Smart Bottle',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign in to track your hydration goals and manage your smart bottle.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              // Sign-in button
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to the main app page and remove the sign-in page from the stack
                  Navigator.pushReplacementNamed(context, '/home');
                },
                icon: const Icon(Icons.login),
                label: const Text('Sign In'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SmartBottleApp extends StatefulWidget {
  const SmartBottleApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SmartBottleAppState createState() => _SmartBottleAppState();
}

class _SmartBottleAppState extends State<SmartBottleApp> {
  // MQTT connection and topics
  late MqttServerClient client;
  final String mqttServer = 'broker.hivemq.com';
  final String mqttClientId = 'flutter_app_${DateTime.now().millisecondsSinceEpoch}';
  final String topicWaterLevel = 'smart_bottle/water_level';
  final String topicWaterConsumed = 'smart_bottle/water_consumed';
  final String topicAlertStatus = 'smart_bottle/alert_active';
  final String topicEsp32Status = 'smart_bottle/status';
  final String topicInterval = 'smart_bottle/interval';
  final String topicReset = 'smart_bottle/reset';

  // State variables
  ValueNotifier<int> waterLevelNotifier = ValueNotifier<int>(0);
  ValueNotifier<double> waterConsumedNotifier = ValueNotifier<double>(0.0);
  ValueNotifier<bool> alertActiveNotifier = ValueNotifier<bool>(false);
  ValueNotifier<bool> esp32StatusNotifier = ValueNotifier<bool>(false);
  Timer? _esp32StatusTimer;
  final TextEditingController _intervalController = TextEditingController(text: '60');
  String _connectionStatus = 'Disconnected';

  @override
  void initState() {
    super.initState();
    _setupMqttClient();
    _connect();
  }

  @override
  void dispose() {
    client.disconnect();
    waterLevelNotifier.dispose();
    waterConsumedNotifier.dispose();
    alertActiveNotifier.dispose();
    esp32StatusNotifier.dispose();
    _esp32StatusTimer?.cancel();
    _intervalController.dispose();
    super.dispose();
  }

  void _setupMqttClient() {
    client = MqttServerClient(mqttServer, mqttClientId);
    client.port = 1883;
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onSubscribed = _onSubscribed;
    client.onUnsubscribed = _onUnsubscribed;
    client.pongCallback = _pong;
  }

  void _connect() async {
    setState(() {
      _connectionStatus = 'Connecting...';
    });
    try {
      await client.connect();
    } on Exception catch (e) {
      debugPrint('Exception: $e');
      client.disconnect();
    }
  }

  void _onConnected() {
    debugPrint('Connected to MQTT broker!');
    setState(() {
      _connectionStatus = 'Connected';
    });
    _subscribeToTopics();
  }

  void _onDisconnected() {
    debugPrint('Disconnected from MQTT broker.');
    setState(() {
      _connectionStatus = 'Disconnected';
    });
    // If we lose connection to broker, assume ESP32 is also down.
    _esp32StatusTimer?.cancel();
    esp32StatusNotifier.value = false;
  }

  void _onSubscribed(String topic) {
    debugPrint('Subscribed to topic: $topic');
  }

  void _onUnsubscribed(String? topic) {
    debugPrint('Unsubscribed from topic: $topic');
  }

  void _pong() {
    debugPrint('Ping response received from broker.');
  }

  void _subscribeToTopics() {
    client.subscribe(topicWaterLevel, MqttQos.atMostOnce);
    client.subscribe(topicWaterConsumed, MqttQos.atMostOnce);
    client.subscribe(topicAlertStatus, MqttQos.atMostOnce);
    client.subscribe(topicEsp32Status, MqttQos.atMostOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final String topic = c[0].topic;

      debugPrint('Received message from topic: $topic, payload: $payload');
      
      if (topic == topicWaterLevel) {
        try {
          final double level = double.parse(payload);
          waterLevelNotifier.value = level.round();
        } catch (e) {
          debugPrint('Error parsing water level: $e');
        }
      } else if (topic == topicWaterConsumed) {
        try {
          final double consumed = double.parse(payload);
          waterConsumedNotifier.value = consumed;
        } catch (e) {
          debugPrint('Error parsing water consumed: $e');
        }
      } else if (topic == topicAlertStatus) {
        alertActiveNotifier.value = (payload == 'true');
      } else if (topic == topicEsp32Status) {
        // Update ESP32 status and reset timer
        esp32StatusNotifier.value = true;
        _esp32StatusTimer?.cancel();
        _esp32StatusTimer = Timer(const Duration(seconds: 15), () {
          // If the timer completes, no message has been received in 15 seconds
          esp32StatusNotifier.value = false;
        });
      }
    });
  }

  void _publishInterval(String interval) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(interval);
    client.publishMessage(topicInterval, MqttQos.atMostOnce, builder.payload!);
  }

  void _publishReset() {
    final builder = MqttClientPayloadBuilder();
    builder.addString('reset');
    client.publishMessage(topicReset, MqttQos.atMostOnce, builder.payload!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Bottle'),
        backgroundColor: Colors.blue.shade50,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (client.connectionStatus!.state == MqttConnectionState.disconnected) {
                _connect();
              }
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Connection Status
              ValueListenableBuilder<bool>(
                valueListenable: esp32StatusNotifier,
                builder: (context, isAlive, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isAlive ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isAlive ? 'Bottle Online' : 'Bottle Offline',
                        style: TextStyle(
                          color: isAlive ? Colors.green.shade600 : Colors.red.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
              Text(
                'Broker Status: $_connectionStatus',
                style: TextStyle(
                  color: _connectionStatus == 'Connected' ? Colors.green.shade600 : Colors.red.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // Water Level Visualizer
              ValueListenableBuilder<int>(
                valueListenable: waterLevelNotifier,
                builder: (context, waterLevel, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 150,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue.shade200, width: 4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          width: 150,
                          height: 250 * (waterLevel / 100),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade400,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      Text(
                        '$waterLevel%',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: waterLevel > 50 ? Colors.white : Colors.blue.shade900,
                          shadows: [
                            Shadow(
                              blurRadius: 2.0,
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // Water Consumed and Hydration Alert
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      ValueListenableBuilder<double>(
                        valueListenable: waterConsumedNotifier,
                        builder: (context, waterConsumed, child) {
                          return Text(
                            'Water Consumed: ${waterConsumed.toStringAsFixed(1)} mL',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      ValueListenableBuilder<bool>(
                        valueListenable: alertActiveNotifier,
                        builder: (context, isActive, child) {
                          return Text(
                            isActive ? '⚠️ Time to drink!' : 'Stay Hydrated!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.red.shade600 : Colors.green.shade600,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Controls
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text(
                        'Hydration Interval (minutes)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _intervalController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'e.g., 60',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onSubmitted: (value) {
                          _publishInterval(value);
                          FocusScope.of(context).unfocus();
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Update Interval'),
                        onPressed: () {
                          _publishInterval(_intervalController.text);
                          FocusScope.of(context).unfocus();
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reset Consumed Water'),
                        onPressed: _publishReset,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: Colors.blue.shade100,
                          foregroundColor: Colors.blue.shade900,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
