import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FloatingLoadingBarForStack extends StatefulWidget {
  final Stream syncingStream;

  const FloatingLoadingBarForStack({Key? key, required this.syncingStream})
      : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      _FloatingLoadingBarForStackState(syncingStream);
}

class _FloatingLoadingBarForStackState
    extends State<FloatingLoadingBarForStack> {
  final Stream syncingStream;

  _FloatingLoadingBarForStackState(this.syncingStream);

  bool showSyncingBar = false;
  Widget bottomBar = Container(key: ValueKey<int>(0));

  @override
  void initState() {
    _listenStream();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: bottomBar,
    );
  }

  syncingContainer() {
    String text = 'Syncing';

    newText(String newText) {
      text = newText;
      setState(() {});
    }

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

  _listenStream() {
    syncingStream.listen((event) {
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
  final Stream syncingStream;

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

  @override
  void initState() {
    widget.syncingStream.listen((event) {
      setState(() {
        if(event != 'start' && event != 'stop'){
          text = event;
        }
      });
    });
    super.initState();
  }

  @override
  void dispose() {
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
