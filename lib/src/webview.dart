import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'webview_events_listener.dart';
import 'webview_javascript.dart';

const MethodChannel _pluginChannel = MethodChannel("webview_cef");

class WebViewController extends ValueNotifier<bool> {
  late Completer<void> _creatingCompleter;
  int _textureId = 0;
  bool _isDisposed = false;
  WebviewEventsListener? _listener;

  final Map<String, JavascriptChannel> _javascriptChannels =
      <String, JavascriptChannel>{};

  Future<void> get ready => _creatingCompleter.future;

  WebViewController() : super(false);

  /// Initializes the underlying platform view.
  Future<void> initialize() async {
    if (_isDisposed) {
      return Future<void>.value();
    }
    _creatingCompleter = Completer<void>();
    try {
      _textureId = await _pluginChannel.invokeMethod<int>('init') ?? 0;
      _pluginChannel.setMethodCallHandler(_methodCallhandler);
      value = true;
      _creatingCompleter.complete();
    } on PlatformException catch (e) {
      _creatingCompleter.completeError(e);
    }

    return _creatingCompleter.future;
  }

  Future<void> _methodCallhandler(MethodCall call) async {
    if (_listener == null) return;
    switch (call.method) {
      case "urlChanged":
        _listener?.onUrlChanged?.call(call.arguments);
        return;
      case "titleChanged":
        _listener?.onTitleChanged?.call(call.arguments);
        return;
      case "allCookiesVisited":
        _listener?.onAllCookiesVisited?.call(Map.from(call.arguments));
        return;
      case "urlCookiesVisited":
        _listener?.onUrlCookiesVisited?.call(Map.from(call.arguments));
        return;
      case 'javascriptChannelMessage':
        _handleJavascriptChannelMessage(
            call.arguments['channel'],
            call.arguments['message'],
            call.arguments['callbackId'],
            call.arguments['frameId']);
        break;
      default:
    }
  }

  setWebviewListener(WebviewEventsListener listener) {
    _listener = listener;
  }

  @override
  Future<void> dispose() async {
    await _creatingCompleter.future;
    if (!_isDisposed) {
      _isDisposed = true;
      _javascriptChannels.clear();
      await _pluginChannel.invokeMethod('dispose', _textureId);
    }
    super.dispose();
  }

  /// Loads the given [url].
  Future<void> loadUrl(String url) async {
    if (_isDisposed) {
      return;
    }
    assert(value);
    return _pluginChannel.invokeMethod('loadUrl', url);
  }

  /// Reloads the current document.
  Future<void> reload() async {
    if (_isDisposed) {
      return;
    }
    assert(value);
    return _pluginChannel.invokeMethod('reload');
  }

  Future<void> goForward() async {
    if (_isDisposed) {
      return;
    }
    assert(value);
    return _pluginChannel.invokeMethod('goForward');
  }

  Future<void> goBack() async {
    if (_isDisposed) {
      return;
    }
    assert(value);
    return _pluginChannel.invokeMethod('goBack');
  }

  Future<void> openDevTools() async {
    if (_isDisposed) {
      return;
    }
    assert(value);
    return _pluginChannel.invokeMethod('openDevTools');
  }

  Future<void> setCookie(String domain, String key, String val, {bool httpOnly = true, bool secure = true}) async {
    if (_isDisposed) {
      return;
    }
    assert(value);
    return _pluginChannel.invokeMethod('setCookie', [domain, key, val, httpOnly, secure]);
  }

  Future<void> deleteCookie(String domain, String key) async {
    if (_isDisposed) {
      return;
    }
    assert(value);
    return _pluginChannel.invokeMethod('deleteCookie', [domain, key]);
  }

  Future<void> visitAllCookies() async {
    if (_isDisposed) {
      return;
    }
    assert(value);
    return _pluginChannel.invokeMethod('visitAllCookies');
  }

  Future<void> visitUrlCookies(String domain, bool isHttpOnly) async {
    if (_isDisposed) {
      return;
    }
    assert(value);
    return _pluginChannel.invokeMethod('visitUrlCookies', [domain, isHttpOnly]);
  }

  Future<void> setJavaScriptChannels(Set<JavascriptChannel> channels) async {
    if (_isDisposed) {
      return;
    }
    assert(value);
    _assertJavascriptChannelNamesAreUnique(channels);

    channels.forEach((channel) {
      _javascriptChannels[channel.name] = channel;
    });

    return _pluginChannel.invokeMethod('setJavaScriptChannels',
        [_extractJavascriptChannelNames(channels).toList()]);
  }

  Future<void> sendJavaScriptChannelCallBack(
      bool error, String result, String callbackId, String frameId) async {
    if (_isDisposed) {
      return;
    }
    assert(value);
    return _pluginChannel.invokeMethod(
        'sendJavaScriptChannelCallBack', [error, result, callbackId, frameId]);
  }

  Future<void> executeJavaScript(String code) async {
    if (_isDisposed) {
      return;
    }
    assert(value);
    return _pluginChannel.invokeMethod('executeJavaScript', [code]);
  }

  /// Moves the virtual cursor to [position].
  Future<void> _cursorMove(Offset position) async {
    if (_isDisposed) {
      return;
    }
    assert(value);
    return _pluginChannel
        .invokeMethod('cursorMove', [position.dx.round(), position.dy.round()]);
  }

  Future<void> _cursorDragging(Offset position) async {
    if (_isDisposed) {
      return;
    }
    assert(value);
    return _pluginChannel.invokeMethod(
        'cursorDragging', [position.dx.round(), position.dy.round()]);
  }

  Future<void> _cursorClickDown(Offset position) async {
    if (_isDisposed) {
      return;
    }
    assert(value);
    return _pluginChannel.invokeMethod(
        'cursorClickDown', [position.dx.round(), position.dy.round()]);
  }

  Future<void> _cursorClickUp(Offset position) async {
    if (_isDisposed) {
      return;
    }
    assert(value);
    return _pluginChannel.invokeMethod(
        'cursorClickUp', [position.dx.round(), position.dy.round()]);
  }

  /// Sets the horizontal and vertical scroll delta.
  Future<void> _setScrollDelta(Offset position, int dx, int dy) async {
    if (_isDisposed) {
      return;
    }
    assert(value);
    return _pluginChannel.invokeMethod(
        'setScrollDelta', [position.dx.round(), position.dy.round(), dx, dy]);
  }

  /// Sets the surface size to the provided [size].
  Future<void> _setSize(double dpi, Size size) async {
    if (_isDisposed) {
      return;
    }
    assert(value);
    return _pluginChannel
        .invokeMethod('setSize', [dpi, size.width, size.height]);
  }

  Set<String> _extractJavascriptChannelNames(Set<JavascriptChannel> channels) {
    final Set<String> channelNames =
        channels.map((JavascriptChannel channel) => channel.name).toSet();
    return channelNames;
  }

  void _handleJavascriptChannelMessage(final String channelName,
      final String message, final String callbackId, final String frameId) {
    if (_javascriptChannels.containsKey(channelName)) {
      _javascriptChannels[channelName]!
          .onMessageReceived(JavascriptMessage(message, callbackId, frameId));
    } else {
      print('Channel "$channelName" is not exstis');
    }
  }

  void _assertJavascriptChannelNamesAreUnique(
      final Set<JavascriptChannel>? channels) {
    if (channels == null || channels.isEmpty) {
      return;
    }
    assert(_extractJavascriptChannelNames(channels).length == channels.length);
  }
}

class WebView extends StatefulWidget {
  final WebViewController controller;

  const WebView(this.controller, {Key? key}) : super(key: key);

  @override
  WebViewState createState() => WebViewState();
}

class WebViewState extends State<WebView> {
  final GlobalKey _key = GlobalKey();
  var _subpixelPan = Offset.zero;

  WebViewController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    // Report initial surface size
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _reportSurfaceSize(context));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(key: _key, child: _buildInner());
  }

  Widget _buildInner() {
    return NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (notification) {
          _reportSurfaceSize(context);
          return true;
        },
        child: SizeChangedLayoutNotifier(
            child: Listener(
          onPointerHover: (ev) {
            _controller._cursorMove(ev.localPosition);
          },
          onPointerDown: (ev) {
            _controller._cursorClickDown(ev.localPosition);
          },
          onPointerUp: (ev) {
            _controller._cursorClickUp(ev.localPosition);
          },
          onPointerMove: (ev) {
            _controller._cursorDragging(ev.localPosition);
          },
          onPointerSignal: (signal) {
            if (signal is! PointerScrollEvent) {
              return;
            }
            final dpr = MediaQuery.of(context).devicePixelRatio;
            final dx = (dpr * signal.scrollDelta.dx).round();
            var dy = (-dpr * signal.scrollDelta.dy).round();
            if(Platform.isMacOS) {
              dy = -dy;
            }
            _controller._setScrollDelta(signal.localPosition, dx, dy);
          },
          onPointerPanZoomUpdate: (event) {
            _subpixelPan += event.panDelta;
            final dx = _subpixelPan.dx.round();
            final dy = _subpixelPan.dy.round();
            if (dx.abs() < 2 && dy.abs() < 2) {
              return;
            }
            _controller._setScrollDelta(event.localPosition, dx, dy);
            _subpixelPan -= Offset(dx.toDouble(), dy.toDouble());
          },
          child: Texture(textureId: _controller._textureId),
        )));
  }

  void _reportSurfaceSize(BuildContext context) async {
    double dpi = MediaQuery.of(context).devicePixelRatio;
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      await _controller.ready;
      unawaited(
          _controller._setSize(dpi, Size(box.size.width, box.size.height)));
    }
  }
}
