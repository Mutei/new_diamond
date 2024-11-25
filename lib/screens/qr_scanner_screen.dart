// lib/screens/qr_scanner_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  final String expectedEstateId;

  const QRScannerScreen({Key? key, required this.expectedEstateId})
      : super(key: key);

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isProcessing = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!isProcessing) {
        isProcessing = true;
        _handleScannedData(scanData.code);
      }
    });
  }

  void _handleScannedData(String? data) {
    if (data == null) {
      Navigator.of(context)
          .pop(false); // Pop with false indicating invalid scan
      return;
    }

    print('Scanned QR Code Data: $data');

    try {
      final uri = Uri.parse(data);
      final scannedEstateId = uri.queryParameters['estateId'];

      if (scannedEstateId == null) {
        Navigator.of(context)
            .pop(false); // Pop with false indicating invalid scan
        return;
      }

      if (scannedEstateId.trim() == widget.expectedEstateId.trim()) {
        Navigator.of(context).pop(true); // Pop with true indicating valid scan
      } else {
        Navigator.of(context)
            .pop(false); // Pop with false indicating invalid scan
      }
    } catch (e) {
      print('Error parsing QR Code data: $e');
      Navigator.of(context)
          .pop(false); // Pop with false indicating invalid scan
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
        overlay: QrScannerOverlayShape(
          borderColor: Theme.of(context).primaryColor,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: MediaQuery.of(context).size.width * 0.8,
        ),
      ),
    );
  }
}
