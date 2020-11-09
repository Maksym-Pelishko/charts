import 'package:flutter/material.dart';

import 'pan_and_zoom_behavior.dart';

class DefaultZoomWidget extends StatelessWidget {
  final ChangeZoomFunction changeZoomFunction;

  DefaultZoomWidget(this.changeZoomFunction);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
            width: 30,
            child: IconButton(
              icon: Icon(Icons.zoom_out),
              onPressed: () => changeZoomFunction(false),
            )),
        SizedBox(
            width: 30,
            child: IconButton(
              icon: Icon(Icons.zoom_in),
              onPressed: () => changeZoomFunction(true),
            )),
      ],
    );
  }
}
