import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:portrait/classes/textStyle.dart';

class PresentationsList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PresentationsListState();
}

class _PresentationsListState extends State<PresentationsList> {
  List presentationsList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Container(
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(12),
                    child: Center(
                      child: PortraitTextStyle()
                          .topText('Presentations lists', Colors.blueAccent),
                    ),
                  ),
                ),
              ],
            ),
            presentationsList.isEmpty
                ? Expanded(
                    child: Center(
                    child: Container(
                      child: _newPresentationButton(),
                    ),
                  ))
                : Container(),
            _body(),
          ],
        ),
      )),
    );
  }

  _body() {
    print(presentationsList.isEmpty);
    return presentationsList.isEmpty ? Container() : Container();
  }

  _newPresentationButton() {
    return Container(
      height: 175,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            primary: Colors.lightBlue, shape: CircleBorder()),
        onPressed: () async {
          /*showDialog(
              barrierDismissible: false,
              context: context,
              builder: (BuildContext context) {
                return NewListDialog(
                    alertTitle: 'Criar nova lista',
                    answer: (answer) {
                      _addItemToList(answer);
                    });
              });*/
        },
        child: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('New presentation', style: TextStyle(fontSize: 20)),
            SizedBox(height: 8),
            Icon(Icons.play_circle_outline),
          ],
        )),
      ),
    );
  }
}
