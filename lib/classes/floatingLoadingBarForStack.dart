import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:portrait/streams/syncingStream.dart';

class FloatingLoadingBarForStack extends StatefulWidget {
  final SyncingStream syncingStream;

  const FloatingLoadingBarForStack({Key? key, required this.syncingStream})
      : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      _FloatingLoadingBarForStackState(syncingStream);
}

class _FloatingLoadingBarForStackState
    extends State<FloatingLoadingBarForStack> {
  final SyncingStream syncingStream;

  _FloatingLoadingBarForStackState(this.syncingStream);

  bool showSyncingBar = false;
  Widget bottomBar = Container(key: ValueKey<int>(0));
  late StreamSubscription<String> stream;

  @override
  void initState() {
    _listenStream();
    super.initState();
  }

  @override
  void dispose() {
    stream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: bottomBar,
    );
  }

  _listenStream() {
    stream = syncingStream.streamControllerStream.listen((event) {
      if (event == 'start') {
        bottomBar = _SyncingContainer(
            buildContext: context, syncingStream: syncingStream);
      } else if (event == 'stop') {
        bottomBar = Container();
      }
      setState(() {});
    });
  }
}

class _SyncingContainer extends StatefulWidget {
  final BuildContext buildContext;
  final SyncingStream syncingStream;

  const _SyncingContainer(
      {Key? key, required this.buildContext, required this.syncingStream})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _SyncingContainerState(buildContext);
}

class _SyncingContainerState extends State<_SyncingContainer> {
  final BuildContext buildContext;

  _SyncingContainerState(this.buildContext);

  String text = 'Syncing';
  late StreamSubscription<String> stream;

  @override
  void initState() {
    stream = widget.syncingStream.streamControllerStream.listen((event) {
      setState(() {
        if (event != 'start' && event != 'stop') {
          text = event;
        }
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    stream.cancel();
    super.dispose();
  }

  @override
  Widget build(buildContext) {
    return Container(
      key: ValueKey<int>(1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(child: Container()),
          Container(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 30,
                    color: Colors.blueAccent.withOpacity(0.1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(text),
                        Container(
                            margin: EdgeInsets.only(left: 16, right: 16),
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
