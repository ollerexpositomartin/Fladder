import 'package:fladder/models/items/item_shared_models.dart';
import 'package:fladder/util/adaptive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as customtab;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' as urllauncher;
import 'package:url_launcher/url_launcher_string.dart';

class ExternalUrlsRow extends ConsumerWidget {
  final List<ExternalUrls>? urls;
  const ExternalUrlsRow({
    this.urls,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      children: urls
              ?.map(
                (url) => TextButton(
                  onPressed: () => launchUrl(context, url.url),
                  child: Text(url.name),
                ),
              )
              .toList() ??
          [],
    );
  }
}

Future<void> launchUrl(BuildContext context, String link) async {
  final Uri url = Uri.parse(link);

  if (AdaptiveLayout.of(context).isDesktop) {
    if (!await urllauncher.launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  } else {
    try {
      await customtab.launch(
        link,
        customTabsOption: customtab.CustomTabsOption(
          toolbarColor: Theme.of(context).primaryColor,
          enableDefaultShare: true,
          enableUrlBarHiding: true,
          showPageTitle: true,
          extraCustomTabs: const <String>[
            // ref. https://play.google.com/store/apps/details?id=org.mozilla.firefox
            'org.mozilla.firefox',
            // ref. https://play.google.com/store/apps/details?id=com.microsoft.emmx
            'com.microsoft.emmx',
          ],
        ),
        safariVCOption: customtab.SafariViewControllerOption(
          preferredBarTintColor: Theme.of(context).primaryColor,
          preferredControlTintColor: Colors.white,
          barCollapsingEnabled: true,
          entersReaderIfAvailable: false,
          dismissButtonStyle: customtab.SafariViewControllerDismissButtonStyle.close,
        ),
      );
    } catch (e) {
      // An exception is thrown if browser app is not installed on Android device.
      debugPrint(e.toString());
    }
  }
}
