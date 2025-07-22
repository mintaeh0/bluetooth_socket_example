import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothViewModel extends ChangeNotifier {
  String? notifyMessage; // 에러 메시지

  FlutterBlueClassic flutterBlueClassic = FlutterBlueClassic(); // 블루투스 연결 인스턴스

  BluetoothAdapterState currentAdapterState =
      BluetoothAdapterState.unknown; // 기기 블루투스 상태

  final List<BluetoothDevice> scanResults = []; // 스캔된 장치 목록

  bool isScanning = false; // 블루투스 스캔 중 여부
  int? connectingToIndex; // 현재 연결 시도 중인 장치 인덱스

  // 데이터 스트림 구독 변수
  StreamSubscription? bluetoothAdapterStateSubscription; // 기기 블루투스 상태
  StreamSubscription? bluetoothScannedDeviceSubscription; // 스캔 장치 결과
  StreamSubscription? bluetoothScanningStateSubscription; // 스캔 시도 중 여부
  StreamSubscription? bluetoothDataReceiveSubscription; // 블루투스 수신 데이터 스트림
  StreamSubscription? socketSubscription; // 소켓 데이터 스트림

  // 소켓 통신
  Socket? socket;

  // 블루투스 연결
  BluetoothConnection? bluetoothConnection;

  // 에러 메시지 초기화
  void clearErrorMessage() {
    notifyMessage = null;
    notifyListeners();
  }

  // 권한 설정
  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
  }

  // 초기 설정 함수
  Future<void> init() async {
    BluetoothAdapterState adapterState = currentAdapterState;

    await _requestPermissions(); // 권한 요청

    try {
      adapterState =
          await flutterBlueClassic.adapterStateNow; // 기기 현재 블루투스 상태 업데이트

      // 현재 기기 블루투스 상태 구독
      bluetoothAdapterStateSubscription =
          flutterBlueClassic.adapterState.listen((
        current,
      ) {
        currentAdapterState = current;
        notifyListeners();
      });

      // 스캔 결과 업데이트
      bluetoothScannedDeviceSubscription =
          flutterBlueClassic.scanResults.listen((device) {
        if (!scanResults.contains(device)) {
          scanResults.add(device);
        }
        notifyListeners();
      });

      // 스캔 상태 구독
      bluetoothScanningStateSubscription =
          flutterBlueClassic.isScanning.listen((
        isScanningBool,
      ) {
        isScanning = isScanningBool;
        notifyListeners();
      });
    } catch (e) {
      log("$e");
    }

    // if (!context.mounted) return;

    currentAdapterState = adapterState;
    notifyListeners();
  }

  // 연결 시도 항목 업데이트
  void setConnectingIndex(int? value) {
    connectingToIndex = value;
    notifyListeners();
  }

  // 블루투스 스캔
  void bluetoothScan() {
    if (isScanning) {
      flutterBlueClassic.stopScan();
    } else {
      scanResults.clear();
      flutterBlueClassic.startScan();
    }
  }

  // 가짜 블루투스 연결 함수
  Future<void> fakeBluetoothConnect(int index) async {
    setConnectingIndex(index);
    notifyListeners();

    await Future.delayed(Duration(seconds: 2));

    notifyMessage = "가짜 블루투스 연결 성공";
    setConnectingIndex(null);
    notifyListeners();
  }

  // 블루투스 연결
  Future<void> connectToDevice(int index) async {
    setConnectingIndex(index); // 연결 시도 중 인덱스 업데이트
    try {
      bluetoothConnection = await flutterBlueClassic
          .connect(scanResults[index].address); // 주소를 이용하여 연결 시도

      // 연결 시도가 끝나면 인덱스 초기화
      setConnectingIndex(null);

      // 연결 성공 시
      if (bluetoothConnection != null) {
        if (bluetoothConnection!.isConnected) {
          // 블루투스 데이터 수신 스트림 구독
          bluetoothDataReceiveSubscription = bluetoothConnection!.input?.listen(
            (data) {
              final String receiveData = utf8.decode(data); // 필요 시 데이터 인코딩

              // 연결된 소켓으로 데이터 전송
              if (socket != null) {
                socket!.write(receiveData);
              }
            },
          );
        }
      }
    } catch (e) {
      setConnectingIndex(null);
      bluetoothConnection?.dispose();
      notifyMessage = "블루투스 연결 실패: $e";
      notifyListeners();
    }
  }

  // 소켓 설정 및 구독
  Future<void> setSocketSubscription() async {
    final host = 'test.host.com';
    final port = 8080;
    final mountPoint = 'mountPoint';
    final username = 'userName';
    final password = 'password';

    final auth = base64Encode(utf8.encode('$username:$password'));

    final request = 'GET /$mountPoint HTTP/1.1\r\n'
        'Host: $host:$port\r\n'
        'User-Agent: Dev Client/1.0\r\n'
        'Authorization: Basic $auth\r\n'
        'Connection: close\r\n\r\n';

    try {
      socket = await Socket.connect(host, port);

      socket!.write(request); // 초기 요청 전송

      // 소켓 데이터 수신 스트림 구독
      socketSubscription = socket!.listen((data) {
        // 연결된 블루투스 장치로 데이터 전송
        if (bluetoothConnection != null) {
          bluetoothConnection!.output.add(data);
        }
      });

      // 에러 처리
      socket!.handleError((error) {});

      // 연결 종료 처리
      socket!.done.then((_) {});
    } catch (e) {
      notifyMessage = "소켓 연결 실패: $e";
      notifyListeners();
    }
  }

  // dispose 함수
  @override
  void dispose() {
    bluetoothAdapterStateSubscription!.cancel();
    bluetoothScannedDeviceSubscription!.cancel();
    bluetoothScanningStateSubscription!.cancel();

    if (bluetoothConnection != null) {
      bluetoothConnection!.close();
      bluetoothConnection!.dispose();
    }
    flutterBlueClassic.stopScan();
    super.dispose();
  }
}
