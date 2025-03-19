import 'package:flutter/material.dart';
import 'mqtt_service.dart';
import 'package:mqtt_client/mqtt_client.dart';

class SwitchPage extends StatefulWidget {
  const SwitchPage({super.key});

  @override
  State<SwitchPage> createState() => _SwitchPageState();
}

class _SwitchPageState extends State<SwitchPage> {
  final MqttService mqttService = MqttService();
  bool isConnected = false;
  List<bool> lightStates = List<bool>.filled(8, false);
  List<Color> tileColors = List<Color>.filled(8, Colors.grey);

  List<String> lightNames = [
    'Hall_light',
    'Room_light',
    'Living_room_light',
    'Living_room_light',
    'Bathroom_light',
    'Kitchen_light',
    'Kitchen_fan',
    'Bathroom_fan'
  ];

  @override
  void initState() {
    super.initState();

    // Połączenie z brokerem MQTT
    mqttService.connect().then((_) {
      if (mounted) {
        setState(() {
          isConnected = true;
        });

        // Subskrybuj tematy MQTT dla każdego światła
        for (int i = 0; i < lightNames.length; i++) {
          mqttService.subscribe('zigbee2mqtt/${lightNames[i]}', (message) {
            _handleMqttMessage(i, message);
          });
        }
      }
    }).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Błąd połączenia z MQTT: $error")),
        );
      }
    });
  }

  // Obsługa wiadomości MQTT
  void _handleMqttMessage(int lightIndex, String payload) {
    bool isOn = payload.contains('"state":"ON"') || payload.contains('"state_l2":"ON"');

    setState(() {
      lightStates[lightIndex] = isOn;
    });
  }

  // Wysyłanie wiadomości do MQTT
  void toggleLight(int lightIndex) {
    if (mqttService.client != null &&
        mqttService.client!.connectionStatus != null &&
        mqttService.client!.connectionStatus!.state == MqttConnectionState.connected) {
      bool newState = !lightStates[lightIndex];
      bool isSecondState = lightIndex == 3;

      if (!isSecondState) {
        mqttService.publishMessage('zigbee2mqtt/${lightNames[lightIndex]}/set',
            '{"state": "${newState ? "ON" : "OFF"}"}');
      } else {
        mqttService.publishMessage('zigbee2mqtt/${lightNames[lightIndex]}/set',
            '{"state_l2": "${newState ? "ON" : "OFF"}"}');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Brak połączenia z MQTT!")),
      );
    }
  }

  @override
  void dispose() {
    mqttService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 8,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => toggleLight(index),
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: tileColors[index],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      lightStates[index] ? Icons.lightbulb : Icons.lightbulb_outline,
                      size: 40,
                      color: lightStates[index] ? Colors.yellow.shade700 : Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lightNames[index],
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
