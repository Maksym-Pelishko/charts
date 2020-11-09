// Copyright 2018 the Charts project authors. Please see the AUTHORS file
// for details.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:math';
import 'dart:ui' show Offset;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:charts_common/common.dart' as common
    show BehaviorPosition, InsideJustification, OutsideJustification;

import 'behaviors/chart_behavior.dart' show BuildableBehavior;

/// Layout delegate that layout chart widget with [BuildableBehavior] widgets.
class WidgetLayoutDelegate extends MultiChildLayoutDelegate {
  /// ID of the common chart widget.
  final String chartID;

  /// Directionality of the widget.
  final isRTL;

  /// ID and [BuildableBehavior] of the widgets for calculating offset.
  final Map<String, BuildableBehavior> idAndBehavior;

  WidgetLayoutDelegate(this.chartID, this.idAndBehavior, this.isRTL);

  @override
  void performLayout(Size size) {
    // Size available for behaviours.
    var chartTopPadding = 0.0;
    var chartBottomPadding = 0.0;
    var chartLeftPadding = 0.0;
    var chartRightPadding = 0.0;

    Map<String, Size> behaviorSizes = Map();
    for (String behaviorID in idAndBehavior.keys)
      if (behaviorID != null) {
        if (hasChild(behaviorID)) {
          final leftPosition = isRTL
              ? common.BehaviorPosition.end
              : common.BehaviorPosition.start;
          final rightPosition = isRTL
              ? common.BehaviorPosition.start
              : common.BehaviorPosition.end;
          final behaviorPosition = idAndBehavior[behaviorID].position;

          var behaviorSize =
              layoutChild(behaviorID, new BoxConstraints.loose(size));
          behaviorSizes[behaviorID] = behaviorSize;
          if (behaviorPosition == common.BehaviorPosition.top) {
            chartTopPadding = max(behaviorSize.height, chartTopPadding);
          } else if (behaviorPosition == common.BehaviorPosition.bottom) {
            chartBottomPadding = max(behaviorSize.height, chartBottomPadding);
          } else if (behaviorPosition == leftPosition) {
            chartLeftPadding = max(behaviorSize.width, chartLeftPadding);
          } else if (behaviorPosition == rightPosition) {
            chartRightPadding = max(behaviorSize.width, chartRightPadding);
          }
        }
      }

    // Layout chart.
    final chartSize = new Size(
        size.width - chartLeftPadding - chartRightPadding,
        size.height - chartTopPadding - chartBottomPadding);
    if (hasChild(chartID)) {
      layoutChild(chartID, new BoxConstraints.tight(chartSize));
      positionChild(chartID, new Offset(chartLeftPadding, chartTopPadding));
    }

    // Position buildable behavior.
    for (String behaviorID in idAndBehavior.keys) {
      if (behaviorID != null) {
        // TODO: Unable to relayout with new smaller width.
        // In the delegate, all children are required to have layout called
        // exactly once.
        final behaviorOffset = _getBehaviorOffset(idAndBehavior[behaviorID],
            behaviorSize: behaviorSizes[behaviorID],
            chartSize: chartSize,
            isRTL: isRTL);

        positionChild(behaviorID, behaviorOffset);
      }
    }
  }

  @override
  bool shouldRelayout(MultiChildLayoutDelegate oldDelegate) {
    // TODO: Deep equality check because the instance will not be
    // the same on each build, even if the buildable behavior has not changed.
    return idAndBehavior != (oldDelegate as WidgetLayoutDelegate).idAndBehavior;
  }

  // Calculate buildable behavior's offset.
  Offset _getBehaviorOffset(BuildableBehavior behavior,
      {Size behaviorSize, Size chartSize, bool isRTL}) {
    Offset behaviorOffset;

    final behaviorPosition = behavior.position;
    final outsideJustification = behavior.outsideJustification;
    final insideJustification = behavior.insideJustification;

    if (behaviorPosition == common.BehaviorPosition.top ||
        behaviorPosition == common.BehaviorPosition.bottom) {
      final heightOffset = behaviorPosition == common.BehaviorPosition.bottom
          ? chartSize.height
          : 0.0;

      final horizontalJustification =
          getOutsideJustification(outsideJustification, isRTL);

      switch (horizontalJustification) {
        case _HorizontalJustification.leftDrawArea:
          behaviorOffset =
              new Offset(behavior.drawAreaBounds.left.toDouble(), heightOffset);
          break;
        case _HorizontalJustification.left:
          behaviorOffset = new Offset(0.0, heightOffset);
          break;
        case _HorizontalJustification.rightDrawArea:
          behaviorOffset = new Offset(
              behavior.drawAreaBounds.right - behaviorSize.width, heightOffset);
          break;
        case _HorizontalJustification.right:
          behaviorOffset =
              new Offset(chartSize.width - behaviorSize.width, heightOffset);
          break;
        case _HorizontalJustification.middleDrawArea:
          behaviorOffset = new Offset(
              (chartSize.width - behaviorSize.width) / 2, heightOffset);
          break;
        case _HorizontalJustification.middle:
          behaviorOffset = new Offset(
              (behavior.drawAreaBounds.width - behaviorSize.width) / 2,
              heightOffset);
          break;
      }
    } else if (behaviorPosition == common.BehaviorPosition.start ||
        behaviorPosition == common.BehaviorPosition.end) {
      final widthOffset =
          (isRTL && behaviorPosition == common.BehaviorPosition.start) ||
                  (!isRTL && behaviorPosition == common.BehaviorPosition.end)
              ? chartSize.width
              : 0.0;

      switch (outsideJustification) {
        case common.OutsideJustification.startDrawArea:
        case common.OutsideJustification.middleDrawArea:
          behaviorOffset =
              new Offset(widthOffset, behavior.drawAreaBounds.top.toDouble());
          break;
        case common.OutsideJustification.start:
        case common.OutsideJustification.middle:
          behaviorOffset = new Offset(widthOffset, 0.0);
          break;
        case common.OutsideJustification.endDrawArea:
          behaviorOffset = new Offset(widthOffset,
              behavior.drawAreaBounds.bottom - behaviorSize.height);
          break;
        case common.OutsideJustification.end:
          behaviorOffset =
              new Offset(widthOffset, chartSize.height - behaviorSize.height);
          break;
      }
    } else if (behaviorPosition == common.BehaviorPosition.inside) {
      var rightOffset = new Offset(chartSize.width - behaviorSize.width, 0.0);

      switch (insideJustification) {
        case common.InsideJustification.topStart:
          behaviorOffset = isRTL ? rightOffset : Offset.zero;
          break;
        case common.InsideJustification.topEnd:
          behaviorOffset = isRTL ? Offset.zero : rightOffset;
          break;
      }
    }

    return behaviorOffset;
  }

  _HorizontalJustification getOutsideJustification(
      common.OutsideJustification justification, bool isRTL) {
    _HorizontalJustification mappedJustification;

    switch (justification) {
      case common.OutsideJustification.startDrawArea:
        mappedJustification = isRTL
            ? _HorizontalJustification.rightDrawArea
            : _HorizontalJustification.leftDrawArea;
        break;
      case common.OutsideJustification.start:
        mappedJustification = isRTL
            ? _HorizontalJustification.right
            : _HorizontalJustification.left;
        break;
      case common.OutsideJustification.middleDrawArea:
        mappedJustification = _HorizontalJustification.middleDrawArea;
        break;
      case common.OutsideJustification.middle:
        mappedJustification = _HorizontalJustification.middle;
        break;
      case common.OutsideJustification.endDrawArea:
        mappedJustification = isRTL
            ? _HorizontalJustification.leftDrawArea
            : _HorizontalJustification.rightDrawArea;
        break;
      case common.OutsideJustification.end:
        mappedJustification = isRTL
            ? _HorizontalJustification.left
            : _HorizontalJustification.right;
        break;
    }

    return mappedJustification;
  }
}

enum _HorizontalJustification {
  leftDrawArea,
  left,
  middleDrawArea,
  middle,
  rightDrawArea,
  right,
}
