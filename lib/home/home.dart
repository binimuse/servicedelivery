import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:servicedelivery/constants.dart';
import 'package:upgrader/upgrader.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Main extends StatefulWidget {
  @override
  _WebViewExampleState createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<Main> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  GlobalKey _globalKey = GlobalKey();
  late WebViewController goback;
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBack2,
      child: Scaffold(
        key: _globalKey,
        backgroundColor: Colors.white,

        appBar: AppBar(
          leadingWidth: 500,
          backgroundColor: Colors.white,
          leading: Container(
            padding: const EdgeInsets.only(left: 5, top: 20, bottom: 10),
            width: 500,
            child: Container(
              decoration: const BoxDecoration(),
              child: Center(
                child: Image.asset(
                  'assets/images/1.png',
                  height: 160,
                  width: 200,
                ),
              ),
            ),
          ),
          actions: <Widget>[
            NavigationControls(_controller.future),
            SampleMenu(_controller.future),
          ],
        ),
        // We're using a Builder here so we have a context that is below the Scaffold
        // to allow calling Scaffold.of(context) so we can show a snackbar.
        body: UpgradeAlert(
          debugLogging: true,
          child: Builder(builder: (BuildContext context) {
            return Stack(children: <Widget>[
              WebView(
                initialUrl: 'http://pfs.mols.gov.et',
                javascriptMode: JavascriptMode.unrestricted,
                onWebViewCreated: (WebViewController webViewController) {
                  _controller.complete(webViewController);
                  goback = webViewController;
                },
                onWebResourceError: (WebResourceError webviewerrr) {},
                onProgress: (int progress) {
                  const CircularProgressIndicator(
                    color: kPrimaryColor,
                    strokeWidth: 8,
                  );
                },
                javascriptChannels: <JavascriptChannel>{
                  _toasterJavascriptChannel(context),
                },
                navigationDelegate: (NavigationRequest request) {
                  const CircularProgressIndicator(
                    color: kPrimaryColor,
                    strokeWidth: 8,
                  );
                  print('allowing navigation to $request');
                  setState(() {
                    isLoading = true;
                  });
                  return NavigationDecision.navigate;
                },
                onPageStarted: (String url) {
                  print('Page started loading: $url');
                },
                onPageFinished: (String url) {
                  setState(() {
                    isLoading = false;
                  });
                },
                gestureNavigationEnabled: true,
                backgroundColor: const Color(0x00000000),
              ),
              isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Stack(),
            ]);
          }),
        ),
      ),
    );
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toaster',
        onMessageReceived: (JavascriptMessage message) {
          // ignore: deprecated_member_use
          Scaffold.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        });
  }

  Future<bool> _onBack2() async {
    bool goBack;

    var value = await goback.canGoBack(); // check webview can go back

    if (value) {
      goback.goBack(); // perform webview back operation

      isLoading = true;

      await Future.delayed(const Duration(milliseconds: 1000));
      isLoading = true;
      return false;
    } else {
      // late BackEventNotifier _notifier;
      await showDialog(
        context: _globalKey.currentState!.context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmation'),
          content: Text("Do you want exit app ?"),
          actions: <Widget>[
            // ignore: deprecated_member_use
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                setState(() {
                  isLoading = false;
                });
              },
              child: const Text('ok'),
            ),
          ],
        ),
      );

      //Navigator.pop(_globalKey.currentState!.context);

      return true;
    }
  }
}

class NavigationControls extends StatelessWidget {
  const NavigationControls(this._webViewControllerFuture)
      : assert(_webViewControllerFuture != null);

  final Future<WebViewController> _webViewControllerFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: _webViewControllerFuture,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> snapshot) {
        final bool webViewReady =
            snapshot.connectionState == ConnectionState.done;
        final WebViewController? controller = snapshot.data;
        return Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.replay,
                color: kPrimaryColor,
              ),
              onPressed: !webViewReady
                  ? null
                  : () {
                      controller!.reload();
                    },
            ),
          ],
        );
      },
    );
  }
}

enum MenuOptions {
  clearCookies,

  clearCache,
}

class SampleMenu extends StatelessWidget {
  SampleMenu(this.controller);

  final Future<WebViewController> controller;
  final CookieManager cookieManager = CookieManager();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: controller,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> controller) {
        return PopupMenuButton<MenuOptions>(
          key: const ValueKey<String>('ShowPopupMenu'),
          onSelected: (MenuOptions value) {
            switch (value) {
              case MenuOptions.clearCookies:
                _onClearCookies(context);
                break;

              case MenuOptions.clearCache:
                _onClearCache(controller.data!, context);
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuItem<MenuOptions>>[
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.clearCookies,
              child: Text('Clear cookies'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.clearCache,
              child: Text('Clear cache'),
            ),
          ],
          icon: Icon(
            Icons.more_vert,
            color: kPrimaryColor,
          ),
        );
      },
    );
  }

  Future<void> _onClearCache(
      WebViewController controller, BuildContext context) async {
    await controller.clearCache();
    // ignore: deprecated_member_use
    Scaffold.of(context).showSnackBar(const SnackBar(
      content: Text('Cache cleared.'),
    ));
  }

  Future<void> _onClearCookies(BuildContext context) async {
    final bool hadCookies = await cookieManager.clearCookies();
    String message = 'There were cookies. Now, they are gone!';
    if (!hadCookies) {
      message = 'There are no cookies.';
    }
    // ignore: deprecated_member_use
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
