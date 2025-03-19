import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final String broker = '192.168.0.15'; // Adres Raspberry Pi z MQTT
  final int port = 1883; // Domyślny port MQTT
  MqttServerClient? client; // Zmieniamy na nullable

  Future<void> connect() async {
    client = MqttServerClient(broker, 'flutter_client');
    client!.port = port;
    client!.logging(on: true); // Włącz logi MQTT
    client!.logging(on: true); // Włącz logi MQTT
    client!.keepAlivePeriod = 20;
    client!.onDisconnected = () => print("MQTT Rozłączono");

    try {
      print("Próba połączenia z MQTT...");
      await client!.connect();
      print("Połączono z MQTT!");
    } catch (e) {
      print('Błąd połączenia z MQTT: $e');
      client!.disconnect();
    }
  }

  void subscribe(String topic, Function(String) onMessage) {
    client?.subscribe(topic, MqttQos.atMostOnce);
    client?.updates
        ?.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
      final MqttPublishMessage recMessage =
      messages![0].payload as MqttPublishMessage;
      final String message =
      MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);
      onMessage(message);
    });
  }

  void unsubscribe(String topic) {
    if (client != null) {
      client!.unsubscribe(topic);
    } else {
      print("MQTT client jest null, nie można odsubskrybować.");
    }
  }

  void publishMessage(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client?.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
  }

  void _onDisconnected() {
    print("MQTT Rozłączono");
  }

  void dispose() {
    if (client != null) {
      client!.disconnect();
      client = null;
    }
  }
}
