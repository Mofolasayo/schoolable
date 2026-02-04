import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mockito/mockito.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/ui/views/home/home_view.dart';

import '../helpers/test_helpers.dart';

const _svgPayload =
    '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"></svg>';

class _SvgTestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _SvgTestHttpClient();
  }
}

class _SvgTestHttpClient extends Mock implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _SvgTestHttpClientRequest();
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _SvgTestHttpClientRequest();
  }

  @override
  void close({bool force = false}) {}
}

class _SvgTestHttpClientRequest extends Mock implements HttpClientRequest {
  final HttpHeaders _headers = _SvgTestHttpHeaders();

  @override
  HttpHeaders get headers => _headers;

  @override
  Future<void> addStream(Stream<List<int>> stream) async {}

  @override
  Future<HttpClientResponse> close() async {
    final bytes = utf8.encode(_svgPayload);
    return _SvgTestHttpClientResponse(bytes);
  }
}

class _SvgTestHttpClientResponse extends Mock implements HttpClientResponse {
  _SvgTestHttpClientResponse(this._bytes);

  final List<int> _bytes;
  final HttpHeaders _headers = _SvgTestHttpHeaders();

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _bytes.length;

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => 'OK';

  @override
  HttpHeaders get headers => _headers;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_bytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _SvgTestHttpHeaders extends Mock implements HttpHeaders {}

void main() {
  setUpAll(() {
    HttpOverrides.global = _SvgTestHttpOverrides();
    registerServices();
  });
  tearDownAll(() {
    HttpOverrides.global = null;
    locator.reset();
  });

  testGoldens('HomeView - default state', (tester) async {
    await loadAppFonts();

    // Set device pixel ratio and size
    await tester.binding.setSurfaceSize(const Size(393, 852));
    tester.binding.window.devicePixelRatioTestValue = 1.0;

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(size: Size(393, 852), devicePixelRatio: 1.0),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: const HomeView(buildAllTabs: false),
        ),
      ),
    );

    await screenMatchesGolden(
      tester,
      'home_view_default',
      customPump: (tester) => tester.pump(const Duration(milliseconds: 100)),
    );
  });
}
