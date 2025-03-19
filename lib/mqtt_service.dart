import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final String broker = '192.168.0.15'; // Adres Raspberry Pi z MQTT
  final int port = 1883; // Domyślny port MQTT

  // Zmieniamy na nullable, aby móc nim zarządzać w dispose()
  MqttServerClient? client;

  // Mapa: topic -> callback, który ma być wołany dla danego tematu
  final Map<String, Function(String)> _callbacks = {};

  Future<void> connect() async {
    client = MqttServerClient(broker, 'flutter_client');
    client!.port = port;
    client!.logging(on: true); // Włącz logi MQTT
    client!.keepAlivePeriod = 20;
    client!.onDisconnected = _onDisconnected;

    try {
      print("Próba połączenia z MQTT...");
      await client!.connect();
      print("Połączono z MQTT!");

      // -- TYLKO JEDEN LISTENER --
      client!.updates?.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
        // Zakładamy, że `messages` nigdy nie będzie puste:
        final recMessage = messages![0];
        final publishMessage = recMessage.payload as MqttPublishMessage;
        final String payload =
        MqttPublishPayload.bytesToStringAsString(publishMessage.payload.message);

        final String topic = recMessage.topic;
        // Sprawdzamy, czy w mapie mamy callback dla tego topicu
        if (_callbacks.containsKey(topic)) {
          _callbacks[topic]!(payload);
        } else {
          // Jeżeli nikt nie subskrybuje tego tematu, to np. log:
          print("Otrzymano wiadomość z nieoczekiwanego topicu: $topic");
        }
      });
    } catch (e) {
      print('Błąd połączenia z MQTT: $e');
      client!.disconnect();
    }
  }

  /// Subskrypcja danego tematu - zapisujemy callback w mapie.
  void subscribe(String topic, Function(String) onMessage) {
    client?.subscribe(topic, MqttQos.atMostOnce);
    _callbacks[topic] = onMessage;
  }

  /// Odsubskrybowanie i usunięcie callbacka z mapy.
  void unsubscribe(String topic) {
    if (client != null) {
      client!.unsubscribe(topic);
      _callbacks.remove(topic);
    } else {
      print("MQTT client jest null, nie można odsubskrybować.");
    }
  }

  /// Publikowanie wiadomości (np. włącz/wyłącz światło).
  void publishMessage(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client?.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
  }

  void _onDisconnected() {
    print("MQTT Rozłączono");
  }

  /// Rozłączamy się (np. wywoływane w dispose w widoku).
  void dispose() {
    client?.disconnect();
    client = null;
  }
}
