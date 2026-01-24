import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart' as esc_pos;
import 'package:image/image.dart' as img_lib; 
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class ImagePreview extends StatefulWidget {
  final String? imagePath;
  final double gamma;

  const ImagePreview({
    super.key,
    this.imagePath,
    this.gamma = 1.0,
  });

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  
  bool isConnected = false;
  String connectedMac = "";


  Future<void> _requestBluetoothPermissions() async {
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    bool allGranted = statuses.values.every((s) => s.isGranted || s.isLimited);
    if (!allGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bluetooth permissions are required for printing.')),
      );
    }
  }
Future<void> _printImage() async {
  if (widget.imagePath == null || !isConnected) return;

  final profile = await esc_pos.CapabilityProfile.load();
  final generator = esc_pos.Generator(esc_pos.PaperSize.mm80, profile);
  List<int> bytes = [];

  final file = File(widget.imagePath!);
  final Uint8List fileBytes = await file.readAsBytes();
  final img_lib.Image? image = img_lib.decodeImage(fileBytes);

  if (image != null) {
    final resized = img_lib.copyResize(image, width: 576); // 80mm
    bytes += generator.image(resized);
    bytes += generator.feed(2);
    bytes += generator.cut();
  }

  final bool result = await PrintBluetoothThermal.writeBytes(bytes);
  if (result && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Printing started!')),
    );
  }
}

Future<void> _handlePrint() async {
  await _requestBluetoothPermissions();

  if (isConnected) {
    await _printImage();
    return;
  }

  // Get paired printers
  final List<BluetoothInfo> paired = await PrintBluetoothThermal.pairedBluetooths;

  if (paired.isEmpty) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No paired printers found. Pair one in Bluetooth settings.')),
      );
    }
    return;
  }

  // Auto-connect to first (or show dialog to choose)
  final BluetoothInfo printer = paired.first;
  final bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: printer.macAdress);

  setState(() => isConnected = connected);

  if (connected) {
    connectedMac = printer.macAdress;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bluetooth printer connected successfully!')),
      );
    }
    await _printImage();
  } else if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connection failed, try again!')),
    );
  }
}

// In dispose()
@override
void dispose() {
  if (isConnected) PrintBluetoothThermal.disconnect;
  super.dispose();
}
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen mirrored + gamma-corrected image
          if (widget.imagePath != null)
            Center(
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(_createGammaMatrix(widget.gamma)),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..scale(-1.0, 1.0),
                  child: Image.file(
                    File(widget.imagePath!),
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            )
          else
            const Center(
              child: Text('No image captured', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),

          // Back button
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildActionButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // Share button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildActionButton(
                  icon: Icons.share_rounded,
                  onPressed: () {
                    if (widget.imagePath != null) {
                      Share.shareXFiles([XFile(widget.imagePath!)]);
                    }
                  },
                ),
              ),
            ),
          ),

          // Print button – Green = connected, Red = not connected
          SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildActionButton(
                  icon: Icons.print_rounded,
                  onPressed: _handlePrint,
                  backgroundColor: isConnected
                      ? Color.fromARGB(172, 76, 175, 80)
                      : Color.fromARGB(172, 255, 0, 0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return Material(
      color: backgroundColor ?? Color.fromARGB(172, 0, 0, 0),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  List<double> _createGammaMatrix(double gamma) {
    double invGamma = 1.0 / gamma;
    return [
      invGamma, 0, 0, 0, 0,
      0, invGamma, 0, 0, 0,
      0, 0, invGamma, 0, 0,
      0, 0, 0, 1.0, 0,
    ];
  }
}