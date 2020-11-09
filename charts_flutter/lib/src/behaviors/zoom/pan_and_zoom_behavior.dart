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

import 'dart:io';

import 'package:charts_common/common.dart' as common
    show
        ChartBehavior,
        PanAndZoomBehavior,
        PanningCompletedCallback,
        InsideJustification,
        OutsideJustification,
        BehaviorPosition;
import 'package:charts_flutter/src/behaviors/zoom/default_zoom_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:meta/meta.dart' show immutable;

import '../chart_behavior.dart'
    show BuildableBehavior, ChartBehavior, GestureType;
import 'pan_behavior.dart' show FlutterPanBehaviorMixin;

@immutable
class PanAndZoomBehavior extends ChartBehavior<common.PanAndZoomBehavior> {
  final _desiredGestures = new Set<GestureType>.from([
    GestureType.onDrag,
  ]);

  Set<GestureType> get desiredGestures => _desiredGestures;

  /// Optional callback that is called when pan / zoom is completed.
  ///
  /// When flinging this callback is called after the fling is completed.
  /// This is because panning is only completed when the flinging stops.
  final common.PanningCompletedCallback panningCompletedCallback;

  final bool isRenderZoomButtons;

  final Widget Function(ChangeZoomFunction) widgetBuilder;

  PanAndZoomBehavior(
      {this.panningCompletedCallback,
      this.isRenderZoomButtons,
      this.widgetBuilder});

  @override
  common.PanAndZoomBehavior<D> createCommonBehavior<D>() {
    if ((kIsWeb || Platform.isMacOS || Platform.isWindows) &&
        (isRenderZoomButtons == null || isRenderZoomButtons))
      return new FlutterWidgetPanAndZoomBehavior<D>(
          widgetBuilder: widgetBuilder)
        ..panningCompletedCallback = panningCompletedCallback;
    else
      return new FlutterPanAndZoomBehavior<D>()
        ..panningCompletedCallback = panningCompletedCallback;
  }

  @override
  void updateCommonBehavior(common.ChartBehavior commonBehavior) {}

  @override
  String get role => 'PanAndZoom';

  bool operator ==(Object other) {
    return other is PanAndZoomBehavior &&
        other.panningCompletedCallback == panningCompletedCallback;
  }

  int get hashCode {
    return panningCompletedCallback.hashCode;
  }
}

typedef ChangeZoomFunction = Function(bool isZoomIn, {double zoomRate});

/// Adds fling gesture support to [common.PanAndZoomBehavior], by way of
/// [FlutterPanBehaviorMixin].
class FlutterPanAndZoomBehavior<D> extends common.PanAndZoomBehavior<D>
    with FlutterPanBehaviorMixin {}

class FlutterWidgetPanAndZoomBehavior<D> extends common.PanAndZoomBehavior<D>
    with FlutterPanBehaviorMixin
    implements BuildableBehavior {
  final double _defaultZoomRate = 1.5;
  final Widget Function(ChangeZoomFunction) widgetBuilder;

  FlutterWidgetPanAndZoomBehavior(
      {Widget Function(ChangeZoomFunction) widgetBuilder})
      : this.widgetBuilder = widgetBuilder ??
            ((changeZoomFunction) => DefaultZoomWidget(changeZoomFunction));

  @override
  Widget build(BuildContext context) {
    return widgetBuilder(changeZoom);
  }

  changeZoom(bool isZoomIn, {double zoomRate}) {
    zoomRate ??= _defaultZoomRate;
    double scale = isZoomIn
        ? (chart.domainAxis.scale.viewportScalingFactor * zoomRate)
        : (chart.domainAxis.scale.viewportScalingFactor / zoomRate);
    double newScalingFactor = calcNewScalingFactor(scale);
    double changeRate =
        newScalingFactor / chart.domainAxis.scale.viewportScalingFactor;
    changeScale(newScalingFactor,
        additionalViewportOffset:
            chart.domainAxis.viewportTranslatePx * (changeRate - 1) -
                (chart.domainAxis.range.width * (changeRate - 1)) / 2,
        isAnimated: true);
  }

  @override
  common.InsideJustification get insideJustification =>
      common.InsideJustification.topEnd;

  @override
  common.OutsideJustification get outsideJustification =>
      common.OutsideJustification.endDrawArea;

  @override
  common.BehaviorPosition get position => common.BehaviorPosition.inside;
}
