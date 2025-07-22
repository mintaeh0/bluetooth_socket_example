import 'package:bluetooth_socket_example/bluetooth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BluetoothView extends StatefulWidget {
  const BluetoothView({super.key});

  @override
  State<BluetoothView> createState() => _BluetoothViewState();
}

class _BluetoothViewState extends State<BluetoothView> {
  @override
  void initState() {
    super.initState();
    final BluetoothViewModel bluetoothViewModel =
        Provider.of<BluetoothViewModel>(context, listen: false);
    bluetoothViewModel.init();
  }

  @override
  Widget build(BuildContext context) {
    final BluetoothViewModel bluetoothViewModel =
        Provider.of<BluetoothViewModel>(context);

    if (bluetoothViewModel.notifyMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bluetoothViewModel.notifyMessage!),
            duration: Duration(seconds: 2),
          ),
        );

        bluetoothViewModel.notifyMessage = null;
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text("Bluetooth Example")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () =>
                      bluetoothViewModel.flutterBlueClassic.turnOn(),
                  icon: Row(
                    children: [
                      Icon(Icons.bluetooth),
                      Text(bluetoothViewModel.currentAdapterState.name),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => bluetoothViewModel.bluetoothScan(),
                  child: Text(bluetoothViewModel.isScanning ? "스캔중..." : "스캔"),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          if (bluetoothViewModel.isScanning) LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: bluetoothViewModel.scanResults.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(
                  "${bluetoothViewModel.scanResults[index].name ?? "???"} (${bluetoothViewModel.scanResults[index].type.name})",
                ),
                subtitle: Text(
                  bluetoothViewModel.scanResults[index].address,
                ),
                trailing: index == bluetoothViewModel.connectingToIndex
                    ? const CircularProgressIndicator()
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("신호강도 : "),
                          bluetoothSignalStrengthText(
                              bluetoothViewModel.scanResults[index].rssi),
                        ],
                      ),
                onTap: () => bluetoothViewModel.fakeBluetoothConnect(index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 신호 강도에 따른 텍스트 표시
Text bluetoothSignalStrengthText(int? rssi) {
  if (rssi == null) {
    return Text("알수없음");
  }

  if (rssi >= -50) {
    return Text(
      "매우양호",
      style: TextStyle(color: Colors.blue),
    );
  } else if (rssi >= -60) {
    return Text(
      "양호",
      style: TextStyle(color: Colors.green),
    );
  } else if (rssi >= -70) {
    return Text(
      "보통",
      style: TextStyle(color: Colors.yellow.shade700),
    );
  } else if (rssi >= -80) {
    return Text(
      "약함",
      style: TextStyle(color: Colors.orange.shade600),
    );
  } else {
    return Text(
      "매우약함",
      style: TextStyle(color: Colors.red),
    );
  }
}
