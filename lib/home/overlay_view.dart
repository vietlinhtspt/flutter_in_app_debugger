import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../networks/inspector_view.dart';
import '../networks/models/network_event.dart';

class FlutterInAppDebuggerView extends StatefulWidget {
  FlutterInAppDebuggerView() : super(key: FlutterInAppDebuggerView.globalKey);

  static GlobalKey<_FlutterInAppDebuggerViewState> globalKey = GlobalKey();

  @override
  State<FlutterInAppDebuggerView> createState() =>
      _FlutterInAppDebuggerViewState();
}

class _FlutterInAppDebuggerViewState extends State<FlutterInAppDebuggerView>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late OverlayEntry _overlayEntry;
  final _settingIconSize = 40.0;
  Offset? _settingOffset;
  final _requests = <NetworkEvent>[];
  final _requestsStream = StreamController<NetworkEvent>.broadcast();

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));

    _animation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(
          0.2,
          1.0,
          curve: Curves.ease,
        )));

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _showOverLay();
    });
  }

  NetworkEvent addNetworkRequest({required RequestOptions request}) {
    final networkEvent = NetworkEvent(request: request);
    _requests.insert(0, networkEvent);
    _requestsStream.add(networkEvent);
    return networkEvent;
  }

  NetworkEvent? addNetworkResponse({required Response response}) {
    final networkEventIndex = _requests.indexWhere((element) =>
        element.request.hashCode == response.requestOptions.hashCode);
    if (networkEventIndex != -1) {
      final networkEvent = _requests[networkEventIndex];
      networkEvent.response = response;
      _requestsStream.add(networkEvent);
      return networkEvent;
    } else {
      debugPrint('not found request');
      return null;
    }
  }

  NetworkEvent? addNetworkError({required DioError dioError}) {
    final networkEventIndex = _requests.indexWhere((element) =>
        element.request.hashCode == dioError.requestOptions.hashCode);
    if (networkEventIndex != -1) {
      final networkEvent = _requests[networkEventIndex];
      networkEvent.error = dioError;
      _requestsStream.add(networkEvent);
      return networkEvent;
    } else {
      debugPrint('not found request');
      return null;
    }
  }

  void _showOverLay() async {
    final viewInsert = MediaQuery.of(context).padding;
    _settingOffset = Offset(
      viewInsert.left + 16,
      viewInsert.top + 16,
    );
    final overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _settingIconSize,
        height: _settingIconSize,
        top: _settingOffset?.dy,
        left: _settingOffset?.dx,
        child: ScaleTransition(
          scale: _animation,
          child: GestureDetector(
            onPanUpdate: (details) {
              _settingOffset = Offset(
                (_settingOffset?.dx ?? 0) + details.delta.dx,
                (_settingOffset?.dy ?? 0) + details.delta.dy,
              );
              overlayState.setState(() {});
            },
            child: FloatingActionButton(
              onPressed: () async {
                _overlayEntry.remove();
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingScreen(
                      networkRequest: _requests,
                    ),
                  ),
                );
                await _animationController.forward();
                overlayState.insert(_overlayEntry);
              },
              backgroundColor: Colors.grey,
              mini: true,
              child: const Icon(
                Icons.settings,
              ),
            ),
          ),
        ),
      ),
    );
    _animationController.addListener(() {
      overlayState.setState(() {});
    });
    await _animationController.forward();
    overlayState.insert(_overlayEntry);

    // await Future.delayed(const Duration(seconds: 5))
    //     .whenComplete(() => animationController!.reverse())
    //     .whenComplete(() => overlayEntry!.remove());
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}