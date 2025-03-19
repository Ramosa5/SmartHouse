import 'package:flutter/material.dart';
import 'mqtt_service.dart';  // Upewnij się, że masz odpowiednią implementację MQTT
import 'package:mqtt_client/mqtt_client.dart';

class TemperaturePage extends StatefulWidget {
  const TemperaturePage({super.key});

  @override
  _TemperaturePageState createState() => _TemperaturePageState();
}

class _TemperaturePageState extends State<TemperaturePage> {
  final TextEditingController roomTempController = TextEditingController();
  final TextEditingController livingRoomTempController = TextEditingController();

  final MqttService mqttService = MqttService();
  bool isConnected = false;

  @override
  void initState() {
    super.initState();

    mqttService.connect().then((_) {
      if (mounted) {
        setState(() {
          isConnected = true;
        });
      }
    }).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Błąd połączenia z MQTT: $error")),
        );
      }
    });
  }

  void updateTemperature(String thermostat, String temp) {
    double? temperature = double.tryParse(temp);
    if (temperature == null || temperature < 5 || temperature > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Temperatura musi być między 5 a 30°C!")),
      );
      return;
    }

    if (mqttService.client != null &&
        mqttService.client!.connectionStatus != null &&
        mqttService.client!.connectionStatus!.state == MqttConnectionState.connected) {
      mqttService.publishMessage(
          'zigbee2mqtt/$thermostat/set',
          '{"occupied_heating_setpoint": $temp}'
      );
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildTemperatureInput("Room_thermostat", roomTempController, "Temp Room °C"),
            buildTemperatureInput("Living_room_thermostat", livingRoomTempController, "Temp Living Room °C"),
          ],
        ),
      ),
    );
  }

  Widget buildTemperatureInput(String thermostat, TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.thermostat, size: 40),
          const SizedBox(width: 20),
          SizedBox(
            width: 150,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              String temp = controller.text;
              if (temp.isNotEmpty) {
                updateTemperature(thermostat, temp);
              }
            },
          ),
        ],
      ),
    );
  }
}
