import 'package:flutter/material.dart';
import 'package:flutter_joybuttons/flutter_joybuttons.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(const JoyButtonsExampleApp());
}

class JoyButtonsExampleApp extends StatelessWidget {
  const JoyButtonsExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('JoyButtons Example'),
        ),
        body: const JoyButtonsExample(),
      ),
    );
  }
}

class JoyButtonsExample extends StatefulWidget {
  const JoyButtonsExample({Key? key}) : super(key: key);

  @override
  _JoyButtonsExampleState createState() => _JoyButtonsExampleState();
}

class _JoyButtonsExampleState extends State<JoyButtonsExample> {
  List<int> _pressed = [];
  double dimension = 45;

  double _sizeOfCenter = 0.4;
  double _numberOfButtons = 3;
  final double _maxButtons = 8;
  final client = MqttServerClient('test.mosquitto.org', 'enworks0001');
  bool _connected = false;
  bool _isPressed = false;

  void _connectToBroker() async {
    try {
      await client.connect();
      setState(() {
        _connected = true;
      });
    } catch (e) {
      print('Connection failed: $e');
      client.disconnect();
    }
  }
  void _onConnected() {
    print('Connected to broker.');
    setState(() {
      _connected = true;
    });
  }

  void _onDisconnected() {
    print('Disconnected from broker.');
    setState(() {
      _connected = false;
    });
  }

  void _disconnectFromBroker() {
    client.disconnect();
    setState(() {
      _connected = false;
    });
  }

  final _names = List.generate(26, (index) => String.fromCharCode(index + 65));
  final _colors = [
    Colors.amber,
    Colors.blue,
    Colors.pink,
    Colors.green,
    Colors.red,
    Colors.lime,
  ];

  List<Widget> getButtons() {
    return List.generate(_numberOfButtons.round(), (index) {
      var name = _names[index % _names.length];
      var color = _colors[index % _colors.length];
      return testButton(name, color);
    });
  }

  JoyButtonsButton testButton(String label, MaterialColor color) {
    return JoyButtonsButton(
      widgetColor: color,
      title: Padding(
        padding: const EdgeInsets.only(top: 3.0),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 32)),
      ),
    );
  }

  List<Widget> getIndicators(int number) {
    return List.generate(_numberOfButtons.round(), (index) {
      var name = _names[index % _names.length];
      var color = _colors[index % _colors.length];
      print("index: $index, name: $name, color: $color");
      return testIndicator(name, index, color);

    });
  }

  Container testIndicator(String label, int index, Color color) {
    return Container(
      alignment: Alignment.center,
      width: dimension,
      height: dimension,
      color: _pressed.contains(index) ? color : Colors.grey.shade200,
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 32)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 3.0, horizontal: 16.0),
                      child: Text("No. of Buttons", style: TextStyle(fontSize: 24)),
                    ),
                    ElevatedButton(
                      onPressed: _connected ? null : _connectToBroker,
                      child: const Text('ConnectButton'),
                    ),
                  ],
                ),
                Slider(
                  min: 1.0,
                  max: _maxButtons,
                  value: _numberOfButtons,
                  divisions: (_maxButtons - 1.0).round(),
                  label: '${_numberOfButtons.round()}',
                  onChanged: (value) {
                    setState(() {
                      _numberOfButtons = value;
                    });
                  },
                ),
              ],
            ),
            Column(
              children: [
                const Padding(
                  padding:EdgeInsets.symmetric(vertical: 3.0, horizontal: 16.0),
                  child: Text("Size of center", style: TextStyle(fontSize: 24)),
                ),
                Slider(
                  min: 0.0,
                  max: 1.0,
                  value: _sizeOfCenter,
                  divisions: 20,
                  label: _sizeOfCenter.toString(),
                  onChanged: (value) {
                    setState(() {
                      _sizeOfCenter = value;
                    });
                  },
                ),
              ],
            ),
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Pressed buttons", style: TextStyle(fontSize: 24)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Wrap(
                    alignment: WrapAlignment.spaceAround,
                    children: [
                      ...getIndicators(_numberOfButtons.round()),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Touch joybuttons widget to see which buttons are reported as pressed",
                      style: TextStyle(fontSize: 24)),
                ),
                JoyButtons(
                  centerButtonOutput: List.generate(_numberOfButtons.round(), (index) => index),
                  centerWidget: JoyButtonsCenter(size: Size(200*_sizeOfCenter, 200*_sizeOfCenter),),
                  buttonWidgets: getButtons(),
                  listener: (details) {
                    setState(() {
                      bool pressed = details.pressed.any((element) => element == true);
                      _pressed = details.pressed;
                      final message = _pressed.join(',');
                      final builder = MqttClientPayloadBuilder();
                      builder.addString(message);
                      final payload = builder.payload!;
                      client.publishMessage('rc_car/directions', MqttQos.atLeastOnce, payload);
                      print(_pressed);
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}