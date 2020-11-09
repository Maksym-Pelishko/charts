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

import 'dart:math' show min, max, Point;
import 'dart:math';

import 'package:charts_common/src/chart/common/chart_canvas.dart';
import 'package:charts_common/src/chart/layout/layout_view.dart';
import 'package:charts_common/src/common/graphics_factory.dart';
import 'package:meta/meta.dart' show protected;

import 'pan_behavior.dart';
import 'panning_tick_provider.dart' show PanningTickProviderMode;

/// Adds domain axis panning and zooming support to the chart.
///
/// Zooming is supported for the web by mouse wheel events. Scrolling up zooms
/// the chart in, and scrolling down zooms the chart out. The chart can never be
/// zoomed out past the domain axis range.
///
/// Zooming is supported by pinch gestures for mobile devices.
///
/// Panning is supported by clicking and dragging the mouse for web, or tapping
/// and dragging on the chart for mobile devices.
class PanAndZoomBehavior<D> extends PanBehavior<D> implements LayoutView {
  @override
  String get role => 'PanAndZoom';

  /// Flag which is enabled to indicate that the user is "zooming" the chart.
  bool _isZooming = false;

  @protected
  bool get isZooming => _isZooming;

  /// Current zoom scaling factor for the behavior.
  double _scalingFactor = 1.0;

  /// Minimum amount of any data points/bars or other on max scale
  double _minDataAmountForMaxScale = 3;

  /// Minimum scalingFactor to prevent zooming out beyond the data range.
  final _minScalingFactor = 1.0;

  Rectangle<int> _componentBounds;
  Rectangle<int> _drawAreaBounds;
  GraphicsFactory _graphicsFactory;

  @override
  bool onDragStart(Point<double> localPosition) {
    if (chart == null) {
      return false;
    }

    super.onDragStart(localPosition);

    // Save the current scaling factor to make zoom events relative.
    _scalingFactor = chart.domainAxis?.viewportScalingFactor;
    _isZooming = true;

    return true;
  }

  @override
  bool onDragUpdate(Point<double> localPosition, double scale) {
    // Swipe gestures should be handled by the [PanBehavior].
    if (scale == 1.0) {
      _isZooming = false;
      return super.onDragUpdate(localPosition, scale);
    }

    // No further events in this chain should be handled by [PanBehavior].
    cancelPanning();

    if (!_isZooming || lastPosition == null || chart == null) {
      return false;
    }

    // Update the domain axis's viewport scale factor to zoom the chart.
    final domainAxis = chart.domainAxis;

    if (domainAxis == null) {
      return false;
    }

    // Clamp the scale to prevent zooming out beyond the range of the data, or
    // zooming in so far that we show nothing useful.
    changeScale(calcNewScalingFactor(_scalingFactor * scale));

    return true;
  }

  @override
  bool onDragEnd(
      Point<double> localPosition, double scale, double pixelsPerSec) {
    _isZooming = false;

    return super.onDragEnd(localPosition, scale, pixelsPerSec);
  }

  double calcNewScalingFactor(double scale) {
    double maxScale = (chart.domainAxis.range.width /
        (chart.domainAxis.stepSize /
            chart.domainAxis.scale.viewportScalingFactor)) /
        _minDataAmountForMaxScale;
    return min(
        max(scale, _minScalingFactor), maxScale);
  }

  changeScale(
      double newScalingFactor,
      {double additionalViewportOffset = 0,
      bool isAnimated = false}) {
    // This is set during onDragUpdate and NOT onDragStart because we don't yet
    // know during onDragStart whether pan/zoom behavior is panning or zooming.
    // During zoom in / zoom out, domain tick provider set to return existing
    // cached ticks.
    domainAxisTickProvider.mode = PanningTickProviderMode.useCachedTicks;

    final domainAxis = chart.domainAxis;

    domainAxis.setViewportSettings(newScalingFactor,
        domainAxis.viewportTranslatePx + additionalViewportOffset,
        drawAreaWidth: chart.drawAreaBounds.width);

    chart.redraw(skipAnimation: !isAnimated, skipLayout: true);
  }

  @override
  GraphicsFactory get graphicsFactory => _graphicsFactory;

  @override
  set graphicsFactory(GraphicsFactory value) {
    _graphicsFactory = value;
  }

  @override
  Rectangle<int> get componentBounds => _componentBounds;

  @override
  bool get isSeriesRenderer => false;

  Rectangle<int> get drawAreaBounds => _drawAreaBounds;

  @override
  void layout(Rectangle<int> componentBounds, Rectangle<int> drawAreaBounds) {
    _componentBounds = componentBounds;
    _drawAreaBounds = drawAreaBounds;
  }

  @override
  LayoutViewConfig get layoutConfig {
    return LayoutViewConfig(
        position: LayoutPosition.DrawArea,
        positionOrder: LayoutViewPositionOrder.zoomButtons,
        paintOrder: LayoutViewPaintOrder.zoomButtons);
  }

  @override
  ViewMeasuredSizes measure(int maxWidth, int maxHeight) {
    return ViewMeasuredSizes(preferredWidth: 0, preferredHeight: 0);
  }

  @override
  void paint(ChartCanvas canvas, double animationPercent) {}
}
