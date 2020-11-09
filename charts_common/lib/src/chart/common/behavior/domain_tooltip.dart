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

import 'package:charts_common/common.dart';
import 'package:charts_common/src/chart/common/chart_canvas.dart';

import 'package:charts_common/src/common/graphics_factory.dart';

import '../base_chart.dart' show BaseChart, LifecycleListener;
import '../selection_model/selection_model.dart'
    show SelectionModel, SelectionModelType;
import 'chart_behavior.dart' show ChartBehavior;
import '../../layout/layout_view.dart'
    show
        LayoutPosition,
        LayoutView,
        LayoutViewConfig,
        LayoutViewPaintOrder,
        ViewMeasuredSizes;
import '../datum_details.dart' show DatumDetails;
import '../../cartesian/axis/axis.dart'
    show ImmutableAxis, domainAxisKey, measureAxisKey;
import '../../cartesian/cartesian_chart.dart' show CartesianChart;
import '../processed_series.dart' show ImmutableSeries;

/// Chart behavior that monitors the specified [SelectionModel] and shows tooltip
/// for selected data.
///
/// This is typically used for bars to show specific tooltips.
///
/// It is used in combination with SelectNearest to update the selection model
/// and expand selection out to the domain value.
class DomainTooltip<D> implements ChartBehavior<D> {
  final SelectionModelType selectionModelType;

  BaseChart<D> _chart;

  _DomainTooltipLayoutView _view;

  LifecycleListener<D> _lifecycleListener;

  DomainTooltip([this.selectionModelType = SelectionModelType.info]) {
    _lifecycleListener =
        LifecycleListener<D>(onAxisConfigured: _updateViewData);
  }

  void _selectionChanged(SelectionModel selectionModel) {
    _chart.redraw(skipLayout: true, skipAnimation: true);
  }

  void _updateViewData() {
    final selectedDatumDetails =
        _chart.getSelectedDatumDetails(selectionModelType);

    var point;
    for (DatumDetails<D> detail in selectedDatumDetails) {
      if (detail == null) {
        continue;
      }

      final series = detail.series;
      final datum = detail.datum;

      final domainAxis = series.getAttr(domainAxisKey) as ImmutableAxis<D>;
      final measureAxis = series.getAttr(measureAxisKey) as ImmutableAxis<num>;

      final lineKey = series.id;

      /*double radiusPx = (detail.radiusPx != null)
          ? detail.radiusPx.toDouble() + radiusPaddingPx
          : defaultRadiusPx;*/

      //final pointKey = '${lineKey}::${detail.domain}::${detail.measure}';

      // If we already have a point for that key, use it.
      //_AnimatedPoint<D> animatingPoint;
      /*if (_seriesPointMap.containsKey(pointKey)) {
        animatingPoint = _seriesPointMap[pointKey];
      } else {*/
      // Create a new point and have it animate in from axis.
      /*final point = _DatumPoint<D>(
            datum: datum,
            domain: detail.domain,
            series: series,
            x: domainAxis.getLocation(detail.domain),
            y: measureAxis.getLocation(0.0));*/

      /*animatingPoint = _AnimatedPoint<D>(
            key: pointKey, overlaySeries: series.overlaySeries)
          ..setNewTarget(_PointRendererElement<D>()
            ..point = point
            ..color = detail.color
            ..fillColor = detail.fillColor
            ..radiusPx = radiusPx
            ..measureAxisPosition = measureAxis.getLocation(0.0)
            ..strokeWidthPx = detail.strokeWidthPx
            ..symbolRenderer = detail.symbolRenderer);*/
      //}

      //newSeriesMap[pointKey] = animatingPoint;

      // Create a new line using the final point locations.
      point = _DatumPoint<D>(
          datum: datum,
          domain: detail.domain,
          series: series,
          textStyleSpec: series.insideLabelStyleAccessorFn(detail.index),
          x: detail.chartPosition.x,
          y: detail.chartPosition.y);

      // Update the set of points that still exist in the series data.
      //_currentKeys.add(pointKey);

      // Get the point element we are going to setup.
      /*final pointElement = _PointRendererElement<D>()
        ..point = point
        ..color = detail.color
        ..fillColor = detail.fillColor
        ..radiusPx = radiusPx
        ..measureAxisPosition = measureAxis.getLocation(0.0)
        ..strokeWidthPx = detail.strokeWidthPx
        ..symbolRenderer = detail.symbolRenderer;

      animatingPoint.setNewTarget(pointElement);*/

    }

    _view.position = point;
  }

  @override
  void attachTo(BaseChart<D> chart) {
    _chart = chart;
    _view = _DomainTooltipLayoutView<D>();

    if (chart is CartesianChart) {
      // Only vertical rendering is supported by this behavior.
      assert((chart as CartesianChart).vertical);
    }

    chart.addView(_view);

    chart.addLifecycleListener(_lifecycleListener);
    chart
        .getSelectionModel(selectionModelType)
        .addSelectionChangedListener(_selectionChanged);
  }

  @override
  void removeFrom(BaseChart chart) {
    chart.removeView(_view);
    chart
        .getSelectionModel(selectionModelType)
        .removeSelectionChangedListener(_selectionChanged);
    chart.removeLifecycleListener(_lifecycleListener);
  }

  @override
  String get role => 'domainTooltip-${selectionModelType.toString()}';
}

class _DomainTooltipLayoutView<D> extends LayoutView {
  final LayoutViewConfig layoutConfig;
  GraphicsFactory _graphicsFactory;
  Rectangle<int> _drawAreaBounds;
  _DatumPoint position;

  _DomainTooltipLayoutView()
      : layoutConfig = LayoutViewConfig(
            paintOrder: LayoutViewPaintOrder.linePointHighlighter,
            position: LayoutPosition.DrawArea,
            positionOrder: 1);

  Rectangle<int> get drawBounds => _drawAreaBounds;

  @override
  GraphicsFactory get graphicsFactory => _graphicsFactory;

  @override
  set graphicsFactory(GraphicsFactory value) {
    _graphicsFactory = value;
  }

  @override
  ViewMeasuredSizes measure(int maxWidth, int maxHeight) {
    return null;
  }

  @override
  void layout(Rectangle<int> componentBounds, Rectangle<int> drawAreaBounds) {
    _drawAreaBounds = drawAreaBounds;
  }

  @override
  Rectangle<int> get componentBounds => _drawAreaBounds;

  @override
  bool get isSeriesRenderer => false;

  @override
  void paint(ChartCanvas canvas, double animationPercent) {
    if (position == null) return;

    TextElement element = graphicsFactory
        .createTextElement("${position.series.id}\n${position.domain}: ${position.datum}");
    element.textStyle = _getTextStyle(graphicsFactory, position.textStyleSpec)
      ..color = Color.white;
    double textWidth = element.measurement.horizontalSliceWidth;
    double textHeight = element.measurement.verticalSliceWidth;
    double rectanglePadding = 5;

    canvas.drawRRect(
        Rectangle.fromPoints(
            Point(position.x - textWidth / 2 - rectanglePadding,
                position.y - textHeight - 2 * rectanglePadding),
            Point(position.x + textWidth / 2 + rectanglePadding, position.y)),
        radius: 5,
        fill: Color.fromHex(code: "#555555"),
        roundTopLeft: true,
        roundTopRight: true,
        roundBottomLeft: true,
        roundBottomRight: true);
    canvas.drawText(element, (position.x - textWidth / 2).toInt(),
        (position.y - textHeight - rectanglePadding).toInt());
  }

  TextStyle _getTextStyle(
      GraphicsFactory graphicsFactory, TextStyleSpec labelSpec) {
    return graphicsFactory.createTextPaint()
      ..color = labelSpec?.color ?? Color.black
      ..fontFamily = labelSpec?.fontFamily
      ..fontSize = labelSpec?.fontSize ?? 12
      ..lineHeight = labelSpec?.lineHeight;
  }
}

class _DatumPoint<D> extends Point<double> {
  final dynamic datum;
  final D domain;
  final ImmutableSeries<D> series;
  final TextStyleSpec textStyleSpec;

  _DatumPoint(
      {this.datum,
      this.domain,
      this.series,
      this.textStyleSpec,
      double x,
      double y})
      : super(x, y);

  factory _DatumPoint.from(_DatumPoint<D> other, [double x, double y]) {
    return _DatumPoint<D>(
        datum: other.datum,
        domain: other.domain,
        series: other.series,
        textStyleSpec: other.textStyleSpec,
        x: x ?? other.x,
        y: y ?? other.y);
  }
}
