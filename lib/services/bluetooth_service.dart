import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// Bluetooth 통신 서비스 (HC-06)
class BluetoothService {
  BluetoothConnection? _connection;
  final StreamController<String> _messageController = StreamController<String>.broadcast();

  /// 아두이노로부터 받은 메시지 스트림
  Stream<String> get messageStream => _messageController.stream;

  /// 연결 상태
  bool get isConnected => _connection != null && _connection!.isConnected;

  /// Bluetooth 기기 검색
  Future<List<BluetoothDevice>> getDevices() async {
    try {
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      return devices;
    } catch (e) {
      print('Error getting Bluetooth devices: $e');
      return [];
    }
  }

  /// 아두이노(HC-06)에 연결
  Future<bool> connect(BluetoothDevice device) async {
    try {
      // 이미 연결된 경우 연결 해제
      if (_connection != null) {
        await disconnect();
      }

      _connection = await BluetoothConnection.toAddress(device.address);
      print('Connected to ${device.name}');

      // 데이터 수신 리스너
      _connection!.input!.listen(
        _onDataReceived,
        onDone: () {
          print('Bluetooth connection closed');
          _connection = null;
        },
        onError: (error) {
          print('Bluetooth connection error: $error');
          _connection = null;
        },
      );

      // 연결 확인 (PING)
      await sendCommand('PING');

      return true;
    } catch (e) {
      print('Error connecting to Bluetooth: $e');
      _connection = null;
      return false;
    }
  }

  /// 연결 해제
  Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
      print('Bluetooth disconnected');
    }
  }

  /// 아두이노로 명령 전송
  Future<void> sendCommand(String command) async {
    if (_connection == null || !_connection!.isConnected) {
      print('Bluetooth not connected');
      return;
    }

    try {
      _connection!.output.add(Uint8List.fromList(utf8.encode('$command\n')));
      await _connection!.output.allSent;
      print('Sent command: $command');
    } catch (e) {
      print('Error sending command: $e');
    }
  }

  /// LED 색상 전송
  Future<void> sendLedColor(int r, int g, int b) async {
    await sendCommand('LED:$r,$g,$b');
  }

  /// LED 끄기
  Future<void> clearLed() async {
    await sendCommand('CLEAR');
  }

  /// 데이터 수신 처리
  void _onDataReceived(Uint8List data) {
    try {
      final message = utf8.decode(data).trim();
      if (message.isNotEmpty) {
        print('Received: $message');
        _messageController.add(message);
      }
    } catch (e) {
      print('Error decoding message: $e');
    }
  }

  /// 리소스 정리
  void dispose() {
    disconnect();
    _messageController.close();
  }
}
