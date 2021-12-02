import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:local_auth/local_auth.dart';

import 'dart:async';


class GetFingerPrint extends StatefulWidget {

  final BluetoothDevice arduino;

  const GetFingerPrint({this.arduino});

  @override
  _GetFingerPrintState createState() => new _GetFingerPrintState();
}

class _GetFingerPrintState extends State<GetFingerPrint> {

  ///Authentification vars
  final LocalAuthentication auth = LocalAuthentication();
  _SupportState _supportState = _SupportState.unknown;
  bool _canCheckBiometrics;
  List<BiometricType> _availableBiometrics;
  String _authorized = 'Not Authorized';
  bool _isAuthenticating = false;

  ///Blurtooth var
  BluetoothConnection connection;
  bool isConnecting = true;

  bool get isConnected => connection != null && connection.isConnected;
  bool isDisconnected = false;


  @override
  void initState() {
    super.initState();

    //test if device support finger print
    auth.isDeviceSupported().then(
          (isSupported) =>
          setState(() =>
          _supportState = isSupported
              ? _SupportState.supported
              : _SupportState.unsupported),
    );

    BluetoothConnection.toAddress(widget.arduino.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnected = false;
      });

      connection.input.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnected) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  ///check whether the device support biometrics
  Future<void> _checkBiometrics() async {
    bool canCheckBiometrics;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      canCheckBiometrics = false;
      print(e);
    }
    if (!mounted) return;

    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
    });
  }

  ///get a list of available biometrics on the device
  Future<void> _getAvailableBiometrics() async {
    List<BiometricType> availableBiometrics;
    try {
      availableBiometrics = await auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      availableBiometrics = <BiometricType>[];
      print(e);
    }
    if (!mounted) return;

    setState(() {
      _availableBiometrics = availableBiometrics;
    });
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _authorized = 'Authenticating';
      });
      authenticated = await auth.authenticate(
          localizedReason: 'Let OS determine authentication method',
          useErrorDialogs: true,
          stickyAuth: true);
      setState(() {
        _isAuthenticating = false;
      });
    } on PlatformException catch (e) {
      print(e);
      setState(() {
        _isAuthenticating = false;
        _authorized = "Error - ${e.message}";
      });
      return;
    }
    if (!mounted) return;

    setState(
            () =>
        _authorized = authenticated ? 'Authorized' : 'Not Authorized');
  }

  ///use finger prints
  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _authorized = 'Authenticating';
      });
      authenticated = await auth.authenticate(
        localizedReason:
        'Scan your fingerprint (or face or whatever) to authenticate',
        useErrorDialogs: true,
        stickyAuth: true,
        biometricOnly: true,

      );
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Authenticating';
      });
    } on PlatformException catch (e) {
      print(e);
      setState(() {
        _isAuthenticating = false;
        _authorized = "Error - ${e.message}";
      });
      return;
    }
    if (!mounted) return;

    final String message = authenticated ? 'Authorized' : 'Not Authorized';
    setState(() {
      _authorized = message;
    });
  }

  void _cancelAuthentication() async {
    await auth.stopAuthentication();
    setState(() => _isAuthenticating = false);
  }


  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnected = true;
      connection.dispose();
      connection = null;
    }

    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: (isConnecting
            ? Text('Connecting chat to ' + widget.arduino.name + '...')
            : isConnected
            ? Text('Connected to ' + widget.arduino.name)
            : Text('Connection lost to ' + widget.arduino.name))
      ),
      body: SafeArea(
        child: Center(
              child:
              isConnected
              ? Column(

                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.all(7.0),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.black26,
                        )
                    ),
                    child: Text(
                        'Click the button to scan your finger prints',
                        textAlign: TextAlign.center,
                        style: TextStyle(

                          fontSize: 30,
                        )
                    ),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  OutlinedButton(

                    onPressed: () =>
                    {
                      _checkBiometrics(),

                      print("sucess" + _authorized + " " +
                          _availableBiometrics.toString() +
                          _canCheckBiometrics.toString()),
                      _authenticate(),

                      if(_supportState == _SupportState.supported){
                        (_canCheckBiometrics) ?

                        ///if the device have biometrics

                        (_isAuthenticating)
                            ? ElevatedButton(
                          onPressed: _cancelAuthentication,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("Cancel Authentication"),
                              Icon(Icons.cancel),
                            ],
                          ),
                        )
                            : Column(
                          children: [

                            ElevatedButton(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_isAuthenticating
                                      ? 'Cancel'
                                      : 'Authenticate: biometrics only'),
                                  Icon(Icons.fingerprint),
                                ],
                              ),
                              onPressed: isConnected
                                ?() {
                                _authenticateWithBiometrics;
                                _authArduino();
                              }
                              : null
                            ),
                          ],
                        )
                            :

                        ///if the device do not have biometrics yet

                        showDialog(context: context,
                          builder: (context) =>
                              AlertDialog(
                                title: Text("Biometrics are not supported"),
                                content: Text(
                                    'Your device does not support face/touch ID'),
                                actions: [],
                              ),
                        ),
                      }

                      else
                        if(_supportState == _SupportState.unsupported ||
                            _supportState == _SupportState.unknown &&
                                !_canCheckBiometrics){

                          showDialog(context: context,
                              builder: (context) =>
                                  AlertDialog(
                                    title: Text("Biometrics are not available"),
                                    content: Text(
                                        'Please configure biometrics before re-trying'),
                                    actions: [
                                    ],
                                  )
                          ),

                        },


                      //setState((){}),
                    }, //onPressed


                    child: Text(
                        'Get print',
                        style: TextStyle(
                          color: Colors.black,
                        )
                    ),
                  ),
                ],
              )
              : Text(
                'Connection lost, go back to previous page and try again'
              ),

            ),
          ),
        );
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
  }

  void _authArduino() async{
    connection.output.add(utf8.encode("authentification"));
    await connection.output.allSent;
  }

}

enum _SupportState {
  unknown,
  supported,
  unsupported,
}
