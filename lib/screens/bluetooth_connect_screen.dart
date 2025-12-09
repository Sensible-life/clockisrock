import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/bluetooth_service.dart';

/// Bluetooth 연결 화면
class BluetoothConnectScreen extends StatefulWidget {
  final BluetoothService bluetoothService;

  const BluetoothConnectScreen({
    super.key,
    required this.bluetoothService,
  });

  @override
  State<BluetoothConnectScreen> createState() => _BluetoothConnectScreenState();
}

class _BluetoothConnectScreenState extends State<BluetoothConnectScreen> {
  List<BluetoothDevice> _devices = [];
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  /// Bluetooth 권한 확인 및 요청
  Future<bool> _checkBluetoothPermissions() async {
    // Android 12+ (API 31+)에서는 BLUETOOTH_CONNECT, BLUETOOTH_SCAN 권한 필요
    final permissions = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();

    final connectStatus = permissions[Permission.bluetoothConnect]!;
    final scanStatus = permissions[Permission.bluetoothScan]!;

    if (connectStatus.isDenied || scanStatus.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth 권한이 필요합니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    if (connectStatus.isPermanentlyDenied || scanStatus.isPermanentlyDenied) {
      if (mounted) {
        _showPermissionSettingsDialog();
      }
      return false;
    }

    return true;
  }

  /// 권한 설정 안내 다이얼로그
  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bluetooth 권한 필요'),
        content: const Text(
          'Bluetooth 기기를 검색하려면 권한이 필요합니다.\n'
          '설정에서 Bluetooth 권한을 허용해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('설정 열기'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isScanning = true;
    });

    try {
      // 권한 확인
      final hasPermission = await _checkBluetoothPermissions();

      if (!hasPermission) {
        setState(() {
          _isScanning = false;
        });
        return;
      }

      // 기기 검색
      final devices = await widget.bluetoothService.getDevices();
      setState(() {
        _devices = devices;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('기기 검색 실패: $e')),
        );
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    // 권한 확인
    final hasPermission = await _checkBluetoothPermissions();

    if (!hasPermission) {
      return;
    }

    setState(() {
      _isScanning = true;
    });

    final success = await widget.bluetoothService.connect(device);

    setState(() {
      _isScanning = false;
      if (success) {
        _connectedDevice = device;
      }
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${device.name}에 연결되었습니다')),
        );
        // 연결 성공 시 화면 닫기
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연결 실패')),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    await widget.bluetoothService.disconnect();
    setState(() {
      _connectedDevice = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연결 해제되었습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth 연결'),
        actions: [
          if (widget.bluetoothService.isConnected)
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              onPressed: _disconnect,
              tooltip: '연결 해제',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _loadDevices,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isScanning
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _devices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.bluetooth_disabled,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '페어링된 기기가 없습니다',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadDevices,
                        icon: const Icon(Icons.refresh),
                        label: const Text('다시 검색'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    final isConnected = widget.bluetoothService.isConnected &&
                        _connectedDevice?.address == device.address;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: Icon(
                          isConnected
                              ? Icons.bluetooth_connected
                              : Icons.bluetooth,
                          color: isConnected ? Colors.blue : Colors.grey,
                          size: 36,
                        ),
                        title: Text(
                          device.name ?? '알 수 없는 기기',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          device.address,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: isConnected
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '연결됨',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: () => _connectToDevice(device),
                                child: const Text('연결'),
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}
