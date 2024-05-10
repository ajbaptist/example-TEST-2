import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' show Platform;

import 'package:clevertap_plugin/clevertap_plugin.dart';
import 'package:example/deeplink_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

@pragma('vm:entry-point')
void onKilledStateNotificationClickedHandler(Map<String, dynamic> map) async {
  print("onKilledStateNotificationClickedHandler called from headless task!");
  print("Notification Payload received: " + map.toString());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CleverTapPlugin.onKilledStateNotificationClicked(
      onKilledStateNotificationClickedHandler);
  runApp(MaterialApp(
    title: 'Home Page',
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late CleverTapPlugin _clevertapPlugin;
  var inboxInitialized = false;
  var optOut = false;
  var offLine = false;
  var enableDeviceNetworkingInfo = false;

  void _handleKilledStateNotificationInteraction() async {
    CleverTapAppLaunchNotification appLaunchNotification =
        await CleverTapPlugin.getAppLaunchNotification();
    print(
        "_handleKilledStateNotificationInteraction => $appLaunchNotification");

    if (appLaunchNotification.didNotificationLaunchApp) {
      Map<String, dynamic> notificationPayload = appLaunchNotification.payload!;
      handleDeeplink(notificationPayload);
    }
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
    activateCleverTapFlutterPluginHandlers();
    CleverTapPlugin.setDebugLevel(3);
    if (Platform.isAndroid) {
      _handleKilledStateNotificationInteraction();
    }
    CleverTapPlugin.createNotificationChannel(
        "fluttertest", "Flutter Test", "Flutter Test", 3, true);
    CleverTapPlugin.initializeInbox();
    CleverTapPlugin.registerForPush(); //only for iOS
    //var initialUrl = CleverTapPlugin.getInitialUrl();
  }

  @override
  void dispose() {
    super.dispose();
    // CleverTapPlugin.unregisterPushPermissionNotificationResponseListener();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    if (!mounted) return;
  }

  void activateCleverTapFlutterPluginHandlers() {
    _clevertapPlugin = new CleverTapPlugin();
    _clevertapPlugin
        .setCleverTapPushAmpPayloadReceivedHandler(pushAmpPayloadReceived);
    _clevertapPlugin.setCleverTapPushClickedPayloadReceivedHandler(
        pushClickedPayloadReceived);
    _clevertapPlugin.setCleverTapInAppNotificationDismissedHandler(
        inAppNotificationDismissed);
    _clevertapPlugin
        .setCleverTapInAppNotificationShowHandler(inAppNotificationShow);
    _clevertapPlugin
        .setCleverTapProfileDidInitializeHandler(profileDidInitialize);
    _clevertapPlugin.setCleverTapProfileSyncHandler(profileDidUpdate);
    _clevertapPlugin.setCleverTapInboxDidInitializeHandler(inboxDidInitialize);
    _clevertapPlugin
        .setCleverTapInboxMessagesDidUpdateHandler(inboxMessagesDidUpdate);
    _clevertapPlugin
        .setCleverTapDisplayUnitsLoadedHandler(onDisplayUnitsLoaded);
    _clevertapPlugin.setCleverTapInAppNotificationButtonClickedHandler(
        inAppNotificationButtonClicked);
    _clevertapPlugin.setCleverTapInboxNotificationButtonClickedHandler(
        inboxNotificationButtonClicked);
    _clevertapPlugin.setCleverTapInboxNotificationMessageClickedHandler(
        inboxNotificationMessageClicked);
    _clevertapPlugin.setCleverTapFeatureFlagUpdatedHandler(featureFlagsUpdated);
    _clevertapPlugin
        .setCleverTapProductConfigInitializedHandler(productConfigInitialized);
    _clevertapPlugin
        .setCleverTapProductConfigFetchedHandler(productConfigFetched);
    _clevertapPlugin
        .setCleverTapProductConfigActivatedHandler(productConfigActivated);
    _clevertapPlugin.setCleverTapPushPermissionResponseReceivedHandler(
        pushPermissionResponseReceived);
  }

  void inAppNotificationDismissed(Map<String, dynamic> map) {
    this.setState(() {
      print("inAppNotificationDismissed called");
      // Uncomment to print payload.
      // printInAppNotificationDismissedPayload(map);
    });
  }

  void printInAppNotificationDismissedPayload(Map<String, dynamic>? map) {
    if (map != null) {
      var extras = map['extras'];
      var actionExtras = map['actionExtras'];
      print("InApp -> dismissed with extras map: ${extras.toString()}");
      print(
          "InApp -> dismissed with actionExtras map: ${actionExtras.toString()}");
      actionExtras.forEach((key, value) {
        print("Value for key: ${key.toString()} is: ${value.toString()}");
      });
    }
  }

  void inAppNotificationShow(Map<String, dynamic> map) {
    this.setState(() {
      print("inAppNotificationShow called = ${map.toString()}");
    });
  }

  void inAppNotificationButtonClicked(Map<String, dynamic>? map) {
    this.setState(() {
      print("inAppNotificationButtonClicked called = ${map.toString()}");
      // Uncomment to print payload.
      // printInAppButtonClickedPayload(map);
    });
  }

  void printInAppButtonClickedPayload(Map<String, dynamic>? map) {
    if (map != null) {
      print("InApp -> button clicked with map: ${map.toString()}");
      map.forEach((key, value) {
        print("Value for key: ${key.toString()} is: ${value.toString()}");
      });
    }
  }

  void inboxNotificationButtonClicked(Map<String, dynamic>? map) {
    this.setState(() {
      print("inboxNotificationButtonClicked called = ${map.toString()}");
      // Uncomment to print payload.
      // printInboxMessageButtonClickedPayload(map);
    });
  }

  void printInboxMessageButtonClickedPayload(Map<String, dynamic>? map) {
    if (map != null) {
      print("App Inbox -> message button tapped with customExtras key/value:");
      map.forEach((key, value) {
        print("Value for key: ${key.toString()} is: ${value.toString()}");
      });
    }
  }

  void inboxNotificationMessageClicked(
      Map<String, dynamic>? data, int contentPageIndex, int buttonIndex) {
    this.setState(() {
      print("App Inbox -> "
              "inboxNotificationMessageClicked called = InboxItemClicked at page-index "
              "$contentPageIndex with button-index $buttonIndex" +
          data.toString());

      var inboxMessageClicked = data?["msg"];
      if (inboxMessageClicked == null) {
        return;
      }

      //The contentPageIndex corresponds to the page index of the content, which ranges from 0 to the total number of pages for carousel templates. For non-carousel templates, the value is always 0, as they only have one page of content.
      var messageContentObject =
          inboxMessageClicked["content"][contentPageIndex];

      //The buttonIndex corresponds to the CTA button clicked (0, 1, or 2). A value of -1 indicates the app inbox body/message clicked.
      if (buttonIndex != -1) {
        //button is clicked
        var buttonObject = messageContentObject["action"]["links"][buttonIndex];
        var buttonType = buttonObject?["type"];
        switch (buttonType) {
          case "copy":
            //this type copies the associated text to the clipboard
            var copiedText = buttonObject["copyText"]?["text"];
            print("App Inbox -> copied text to Clipboard: $copiedText");
            //dismissAppInbox();
            break;
          case "url":
            //this type fires the deeplink
            var firedDeepLinkUrl = buttonObject["url"]?["android"]?["text"];
            print("App Inbox -> fired deeplink url: $firedDeepLinkUrl");
            //dismissAppInbox();
            break;
          case "kv":
            //this type contains the custom key-value pairs
            var kvPair = buttonObject["kv"];
            print("App Inbox -> custom key-value pair: $kvPair");
            //dismissAppInbox();
            break;
        }
      } else {
        //Item's body is clicked
        print(
            "App Inbox -> type/template of App Inbox item: ${inboxMessageClicked["type"]}");
        //dismissAppInbox();
      }
    });
  }

  void dismissAppInbox() {
    CleverTapPlugin.dismissInbox();
  }

  void profileDidInitialize() {
    this.setState(() {
      print("profileDidInitialize called");
    });
  }

  void profileDidUpdate(Map<String, dynamic>? map) {
    this.setState(() {
      print("profileDidUpdate called");
    });
  }

  void inboxDidInitialize() {
    this.setState(() {
      print("inboxDidInitialize called");
      inboxInitialized = true;
    });
  }

  void inboxMessagesDidUpdate() {
    this.setState(() async {
      print("inboxMessagesDidUpdate called");
      int? unread = await CleverTapPlugin.getInboxMessageUnreadCount();
      int? total = await CleverTapPlugin.getInboxMessageCount();
      print("Unread count = " + unread.toString());
      print("Total count = " + total.toString());
    });
  }

  void onDisplayUnitsLoaded(List<dynamic>? displayUnits) {
    this.setState(() {
      print("Display Units = " + displayUnits.toString());
      // Uncomment to print payload.
      // printDisplayUnitPayload(displayUnits);
    });
  }

  void printDisplayUnitPayload(List<dynamic>? displayUnits) {
    if (displayUnits != null) {
      print("Total Display unit count = ${(displayUnits.length).toString()}");
      displayUnits.forEach((element) {
        printDisplayUnit(element);
      });
    }
  }

  void printDisplayUnit(Map<dynamic, dynamic> displayUnit) {
    var content = displayUnit['content'];
    content.forEach((contentElement) {
      print("Title text of display unit is ${contentElement['title']['text']}");
      print(
          "Message text of display unit is ${contentElement['message']['text']}");
    });
    var customKV = displayUnit['custom_kv'];
    if (customKV != null) {
      print("Display units custom key-values:");
      customKV.forEach((key, value) {
        print("Value for key: ${key.toString()} is: ${value.toString()}");
      });
    }
  }

  void featureFlagsUpdated() {
    print("Feature Flags Updated");
    this.setState(() async {
      bool? booleanVar = await CleverTapPlugin.getFeatureFlag("BoolKey", false);
      print("Feature flag = " + booleanVar.toString());
    });
  }

  void productConfigInitialized() {
    print("Product Config Initialized");
    this.setState(() async {
      await CleverTapPlugin.fetch();
    });
  }

  void productConfigFetched() {
    print("Product Config Fetched");
    this.setState(() async {
      await CleverTapPlugin.activate();
    });
  }

  void productConfigActivated() {
    print("Product Config Activated");
    this.setState(() async {
      String? stringvar =
          await CleverTapPlugin.getProductConfigString("StringKey");
      print("PC String = " + stringvar.toString());
      int? intvar = await CleverTapPlugin.getProductConfigLong("IntKey");
      print("PC int = " + intvar.toString());
      double? doublevar =
          await CleverTapPlugin.getProductConfigDouble("DoubleKey");
      print("PC double = " + doublevar.toString());
    });
  }

  void pushAmpPayloadReceived(Map<String, dynamic> map) {
    print("pushAmpPayloadReceived called");
    this.setState(() async {
      var data = jsonEncode(map);
      print("Push Amp Payload = " + data.toString());
      CleverTapPlugin.createNotification(data);
    });
  }

  void pushClickedPayloadReceived(Map<String, dynamic> notificationPayload) {
    print("pushClickedPayloadReceived called");
    print("on Push Click Payload = " + notificationPayload.toString());
    handleDeeplink(notificationPayload);
  }

  void pushPermissionResponseReceived(bool accepted) {
    print("Push Permission response called ---> accepted = " +
        (accepted ? "true" : "false"));
  }

  @override
  Widget build(BuildContext context) {
    return StyledToast(
      locale: const Locale('en', 'US'),
      child: MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: const Text('CleverTap Plugin Example App'),
              backgroundColor: Colors.red.shade800,
            ),
            body: ListView(
              children: <Widget>[
                Card(
                  color: Colors.orange,
                  child: Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: ListTile(
                      dense: true,
                      trailing: Icon(Icons.warning),
                      title: Text(
                          "NOTE : All CleverTap functions are listed below"),
                      subtitle: Text(
                          "Please check console logs for more info after tapping below"),
                    ),
                  ),
                ),
                Card(
                  color: Colors.lightBlueAccent,
                  child: Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: ListTile(
                      title: Text("User Profiles"),
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Push User"),
                      subtitle: Text("Pushes/Records a user"),
                      onTap: recordUser,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Set Profile Multi Values"),
                      subtitle: Text("Sets a multi valued user property"),
                      onTap: setProfileMultiValue,
                    ),
                  ),
                ),
                Card(
                  color: Colors.lightBlueAccent,
                  child: Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: ListTile(
                      title: Text("Identity Management"),
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Performs onUserLogin"),
                      subtitle: Text("Used to identify multiple profiles"),
                      onTap: onUserLogin,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Set Debug Level"),
                      subtitle: Text(
                          "Sets the debug level in Android/iOS to show console logs"),
                      onTap: () {
                        CleverTapPlugin.setDebugLevel(3);
                      },
                      trailing: Icon(Icons.info),
                    ),
                  ),
                ),
                Card(
                  color: Colors.lightBlueAccent,
                  child: Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: ListTile(
                      title: Text("In-App messaging controls"),
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Suspend InApp notifications"),
                      subtitle:
                          Text("Suspends display of InApp Notifications."),
                      onTap: suspendInAppNotifications,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Discard InApp notifications"),
                      subtitle: Text(
                          "Suspends the display of InApp Notifications "
                          "and discards any new InApp Notifications to be shown"
                          " after this method is called."),
                      onTap: discardInAppNotifications,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Resume InApp notifications"),
                      subtitle: Text("Resumes display of InApp Notifications."),
                      onTap: resumeInAppNotifications,
                    ),
                  ),
                ),
                Card(
                  color: Colors.lightBlueAccent,
                  child: Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: ListTile(
                      title: Text("Product Config"),
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Get Event First Time"),
                      subtitle: Text("Gets first epoch of an event"),
                      onTap: eventGetFirstTime,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Get Event Occurrences"),
                      subtitle: Text("Get number of occurences of an event"),
                      onTap: eventGetOccurrences,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Get Event Last Time"),
                      subtitle: Text("Returns last epoch value for an event"),
                      onTap: eventGetLastTime,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Fetch"),
                      subtitle: Text("Fetches Product Config values"),
                      onTap: fetch,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Activate"),
                      subtitle: Text("Activates Product Config values"),
                      onTap: activate,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Fetch and Activate"),
                      subtitle: Text("Fetches and Activates Config values"),
                      onTap: fetchAndActivate,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Session Time Elapsed"),
                      subtitle: Text("Returns session time elapsed"),
                      onTap: getTimeElapsed,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Session Total Visits"),
                      subtitle: Text("Returns session total visits"),
                      onTap: getTotalVisits,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Session Screen Count"),
                      subtitle: Text("Returns session screen count"),
                      onTap: getScreenCount,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Session Previous Visit Time"),
                      subtitle: Text("Returns session previous visit time"),
                      onTap: getPreviousVisitTime,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Session UTM Details"),
                      subtitle: Text("Returns session UTM details"),
                      onTap: getUTMDetails,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Get Ad Units"),
                      subtitle: Text("Returns all Display Units set"),
                      onTap: getAdUnits,
                    ),
                  ),
                ),
                Card(
                  color: Colors.lightBlueAccent,
                  child: Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: ListTile(
                      title: Text("Attribution"),
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Get Attribution ID"),
                      subtitle: Text(
                          "Returns Attribution ID to send to attribution partners"),
                      onTap: getCTAttributionId,
                    ),
                  ),
                ),
                Card(
                  color: Colors.lightBlueAccent,
                  child: Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: ListTile(
                      title: Text("GDPR"),
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Set Opt Out"),
                      subtitle:
                          Text("Used to opt out of sending data to CleverTap"),
                      onTap: setOptOut,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Device Networking Info"),
                      subtitle: Text(
                          "Enables/Disable device networking info as per GDPR"),
                      onTap: setEnableDeviceNetworkingInfo,
                    ),
                  ),
                ),
                Card(
                  color: Colors.lightBlueAccent,
                  child: Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: ListTile(
                      title: Text("Multi-Instance"),
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Enable Personalization"),
                      subtitle: Text("Enables Personalization"),
                      onTap: enablePersonalization,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Disables Personalization"),
                      subtitle: Text("Disables Personalization"),
                      onTap: disablePersonalization,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Set Offline"),
                      subtitle: Text("Switches CleverTap to offline mode"),
                      onTap: setOffline,
                    ),
                  ),
                ),
                Card(
                  color: Colors.lightBlueAccent,
                  child: Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: ListTile(
                      title: Text("Push Templates"),
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Basic Push"),
                      onTap: sendBasicPush,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Carousel Push"),
                      onTap: sendAutoCarouselPush,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Manual Carousel Push"),
                      onTap: sendManualCarouselPush,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("FilmStrip Carousel Push"),
                      onTap: sendFilmStripCarouselPush,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Set Push token : FCM"),
                      onTap: setPushTokenFCM,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Set Push token : XPS"),
                      onTap: setPushTokenXPS,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Set Push token : HMS"),
                      onTap: setPushTokenHMS,
                    ),
                  ),
                ),
                Card(
                  color: Colors.lightBlueAccent,
                  child: Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: ListTile(
                      title: Text("Push Primer"),
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Prompt for Push Notification"),
                      onTap: promptForPushNotification,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Local Half Interstitial Push Primer"),
                      onTap: localHalfInterstitialPushPrimer,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Local Alert Push Primer"),
                      onTap: localAlertPushPrimer,
                    ),
                  ),
                ),
                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ListTile(
                      title: Text("Set Locale"),
                      subtitle: Text("Use to set Locale of a user"),
                      onTap: setLocale,
                    ),
                  ),
                ),
              ],
            )),
      ),
    );
  }

  void sendBasicPush() {
    var eventData = {
      // Key:    Value
      'first': 'partridge',
      'second': 'turtledoves'
    };
    CleverTapPlugin.recordEvent("Send Basic Push", eventData);
  }

  void sendAutoCarouselPush() {
    var eventData = {
      // Key:    Value
      '': ''
    };
    CleverTapPlugin.recordEvent("Send Carousel Push", eventData);
  }

  void sendManualCarouselPush() {
    var eventData = {
      // Key:    Value
      '': ''
    };
    CleverTapPlugin.recordEvent("Send Manual Carousel Push", eventData);
  }

  void sendFilmStripCarouselPush() {
    var eventData = {
      // Key:    Value
      '': ''
    };
    CleverTapPlugin.recordEvent("Send Filmstrip Carousel Push", eventData);
  }

  void sendRatingCarouselPush() {
    var eventData = {
      // Key:    Value
      '': ''
    };
    CleverTapPlugin.recordEvent("Send Rating Push", eventData);
  }

  void sendProductDisplayPush() {
    var eventData = {
      // Key:    Value
      '': ''
    };
    CleverTapPlugin.recordEvent("Send Product Display Notification", eventData);
  }

  void sendLinearProductDisplayPush() {
    var eventData = {
      // Key:    Value
      '': ''
    };
    CleverTapPlugin.recordEvent("Send Linear Product Display Push", eventData);
  }

  void sendCTAPush() {
    var eventData = {
      // Key:    Value
      '': ''
    };
    CleverTapPlugin.recordEvent("Send CTA Notification", eventData);
  }

  void sendZeroBezelPush() {
    var eventData = {
      // Key:    Value
      '': ''
    };
    CleverTapPlugin.recordEvent("Send Zero Bezel Notification", eventData);
  }

  void sendZeroBezelTextOnlyPush() {
    var eventData = {
      // Key:    Value
      '': ''
    };
    CleverTapPlugin.recordEvent(
        "Send Zero Bezel Text Only Notification", eventData);
  }

  void sendTimerPush() {
    var eventData = {
      // Key:    Value
      '': ''
    };
    CleverTapPlugin.recordEvent("Send Timer Notification", eventData);
  }

  void sendInputBoxPush() {
    var eventData = {
      // Key:    Value
      '': ''
    };
    CleverTapPlugin.recordEvent("Send Input Box Notification", eventData);
  }

  void sendInputBoxReplyEventPush() {
    var eventData = {
      // Key:    Value
      '': ''
    };
    CleverTapPlugin.recordEvent(
        "Send Input Box Reply with Event Notification", eventData);
  }

  void sendInputBoxReplyAutoOpenPush() {
    var eventData = {
      // Key:    Value
      '': ''
    };
    CleverTapPlugin.recordEvent(
        "Send Input Box Reply with Auto Open Notification", eventData);
  }

  void sendInputBoxRemindDOCFalsePush() {
    var eventData = {
      // Key:    Value
      '': ''
    };
    CleverTapPlugin.recordEvent(
        "Send Input Box Remind Notification DOC FALSE", eventData);
  }

  void sendInputBoxCTADOCTruePush() {
    var eventData = {
      // Key:    Value
      '': ''
    };
    CleverTapPlugin.recordEvent("Send Input Box CTA DOC true", eventData);
  }

  void sendInputBoxCTADOCFalsePush() {
    var eventData = {
      // Key:    Value
      '': ''
    };
    CleverTapPlugin.recordEvent("Send Input Box CTA DOC false", eventData);
  }

  void sendInputBoxReminderDOCTruePush() {
    var eventData = {
      // Key:    Value
      '': ''
    };
    CleverTapPlugin.recordEvent("Send Input Box Reminder DOC true", eventData);
  }

  void sendInputBoxReminderDOCFalsePush() {
    var eventData = {
      // Key:    Value
      '': ''
    };
    CleverTapPlugin.recordEvent("Send Input Box Reminder DOC false", eventData);
  }

  void setPushTokenFCM() {
    CleverTapPlugin.setPushToken("token_fcm");
  }

  void setPushTokenXPS() {
    // CleverTapPlugin.setXiaomiPushToken("token_xps", "Europe");
  }

  void setPushTokenHMS() {
    CleverTapPlugin.setHuaweiPushToken("token_fcm");
  }

  void recordEvent() {
    var now = new DateTime.now();
    var eventData = {
      // Key:    Value
      'first': 'partridge',
      'second': 'turtledoves',
      'date': CleverTapPlugin.getCleverTapDate(now),
      'number': 1
    };
    CleverTapPlugin.recordEvent("Flutter Event", eventData);
    showToast("Raised event - Flutter Event");
  }

  void recordNotificationClickedEvent() {
    var eventData = {
      /// Key:    Value
      'nm': 'Notification message',
      'nt': 'Notification title',
      'wzrk_id': '0_0',
      'wzrk_cid': 'Notification Channel ID'

      ///other CleverTap Push Payload Key Values found in Step 3 of
      ///https://developer.clevertap.com/docs/android#section-custom-android-push-notifications-handling
    };
    CleverTapPlugin.pushNotificationClickedEvent(eventData);
    showToast("Raised event - Notification Clicked");
  }

  void recordNotificationViewedEvent() {
    var eventData = {
      /// Key:    Value
      'nm': 'Notification message',
      'nt': 'Notification title',
      'wzrk_id': '0_0',
      'wzrk_cid': 'Notification Channel ID'

      ///other CleverTap Push Payload Key Values found in Step 3 of
      ///https://developer.clevertap.com/docs/android#section-custom-android-push-notifications-handling
    };
    CleverTapPlugin.pushNotificationViewedEvent(eventData);
    showToast("Raised event - Notification Viewed");
  }

  void recordChargedEvent() {
    var item1 = {
      // Key:    Value
      'name': 'thing1',
      'amount': '100'
    };
    var item2 = {
      // Key:    Value
      'name': 'thing2',
      'amount': '100'
    };
    var items = [item1, item2];
    var chargeDetails = {
      // Key:    Value
      'total': '200',
      'payment': 'cash'
    };
    CleverTapPlugin.recordChargedEvent(chargeDetails, items);
    showToast("Raised event - Charged");
  }

  void recordUser() {
    var profile = {
      'Name': 'sarvesh',
      'DOB': '22-04-2000',

      ///Key always has to be "DOB" and format should always be dd-MM-yyyy
      'Email': 'sarveshgk10@gmail.com',
      'Phone': '14155551234',
      'props': 'property1',
    };
    CleverTapPlugin.profileSet(profile);
    showToast("Pushed profile " + profile.toString());
  }

  void showInbox() {
    if (inboxInitialized) {
      showToast("Opening App Inbox", onDismiss: () {
        var styleConfig = {
          'noMessageTextColor': '#ff6600',
          'noMessageText': 'No message(s) to show.',
          'navBarTitle': 'App Inbox',
          'navBarTitleColor': '#101727',
          'navBarColor': '#EF4444'
        };
        CleverTapPlugin.showInbox(styleConfig);
      });
    }
  }

  void showInboxWithTabs() {
    if (inboxInitialized) {
      showToast("Opening App Inbox", onDismiss: () {
        var styleConfig = {
          'noMessageTextColor': '#ff6600',
          'noMessageText': 'No message(s) to show.',
          'navBarTitle': 'App Inbox',
          'navBarTitleColor': '#101727',
          'navBarColor': '#EF4444',
          'tabs': ["promos", "offers"]
        };
        CleverTapPlugin.showInbox(styleConfig);
      });
    }
  }

  void getAllInboxMessages() async {
    List? messages = await CleverTapPlugin.getAllInboxMessages();
    showToast("See all inbox messages in console");
    print("Inbox Messages = " + messages.toString());
    // Uncomment to print payload.
    // printInboxMessagesArray(messages);
  }

  void getUnreadInboxMessages() async {
    List? messages = await CleverTapPlugin.getUnreadInboxMessages();
    showToast("See unread inbox messages in console");
    print("Unread Inbox Messages = " + messages.toString());
    // Uncomment to print payload.
    // printInboxMessagesArray(messages);
  }

  void printInboxMessagesArray(List? messages) {
    if (messages != null) {
      print("Total Inbox messages count = ${(messages.length).toString()}");
      messages.forEach((element) {
        printInboxMessageMap(element);
      });
    }
  }

  void printInboxMessageMap(Map<dynamic, dynamic> inboxMessage) {
    print("Inbox Message wzrk_id = ${inboxMessage['wzrk_id'].toString()}");
    print("Type of Inbox = ${inboxMessage['msg']['type']}");
    var content = inboxMessage['msg']['content'];
    content.forEach((element) {
      print(
          "Inbox Message Title = ${element['title']['text']} and message = ${element['message']['text']}");
      var links = element['action']['links'];
      links.forEach((link) {
        print("Inbox Message have link type = ${link['type'].toString()}");
      });
    });
  }

  void getInboxMessageForId() async {
    var messageId = await getFirstInboxMessageId();

    if (messageId == null) {
      setState((() {
        showToast("Inbox Message id is null");
        print("Inbox Message id is null");
      }));
      return;
    }

    var messageForId = await CleverTapPlugin.getInboxMessageForId(messageId);
    setState((() {
      showToast("Inbox Message for id =  ${messageForId.toString()}");
      print("Inbox Message for id =  ${messageForId.toString()}");
      // Uncomment to print payload.
      // printInboxMessageMap(messageForId);
    }));
  }

  void deleteInboxMessageForId() async {
    var messageId = await getFirstInboxMessageId();

    if (messageId == null) {
      setState((() {
        showToast("Inbox Message id is null");
        print("Inbox Message id is null");
      }));
      return;
    }

    await CleverTapPlugin.deleteInboxMessageForId(messageId);

    setState((() {
      showToast("Deleted Inbox Message with id =  $messageId");
      print("Deleted Inbox Message with id =  $messageId");
    }));
  }

  void deleteInboxMessagesForIds() async {
    var messageId = await getFirstInboxMessageId();

    if (messageId == null) {
      setState((() {
        showToast("Inbox Message id is null");
        print("Inbox Message id is null");
      }));
      return;
    }

    await CleverTapPlugin.deleteInboxMessagesForIds([messageId]);

    setState((() {
      showToast("Deleted Inbox Messages with ids =  $messageId");
      print("Deleted Inbox Messages with ids =  $messageId");
    }));
  }

  void markReadInboxMessageForId() async {
    var messageId = await getFirstUnreadInboxMessageId();

    if (messageId == null) {
      setState((() {
        showToast("Inbox Message id is null");
        print("Inbox Message id is null");
      }));
      return;
    }

    await CleverTapPlugin.markReadInboxMessageForId(messageId);

    setState((() {
      showToast("Marked Inbox Message as read with id =  $messageId");
      print("Marked Inbox Message as read with id =  $messageId");
    }));
  }

  void markReadInboxMessagesForIds() async {
    var messageId = await getFirstUnreadInboxMessageId();

    if (messageId == null) {
      setState((() {
        showToast("Inbox Message id is null");
        print("Inbox Message id is null");
      }));
      return;
    }

    await CleverTapPlugin.markReadInboxMessagesForIds([messageId]);

    setState((() {
      showToast("Marked Inbox Messages as read with ids =  ${[messageId]}");
      print("Marked Inbox Messages as read with ids =  ${[messageId]}");
    }));
  }

  void pushInboxNotificationClickedEventForId() async {
    var messageId = await getFirstInboxMessageId();

    if (messageId == null) {
      setState((() {
        showToast("Inbox Message id is null");
        print("Inbox Message id is null");
      }));
      return;
    }

    await CleverTapPlugin.pushInboxNotificationClickedEventForId(messageId);

    setState((() {
      showToast(
          "Pushed NotificationClickedEvent for Inbox Message with id =  $messageId");
      print(
          "Pushed NotificationClickedEvent for Inbox Message with id =  $messageId");
    }));
  }

  void pushInboxNotificationViewedEventForId() async {
    var messageId = await getFirstInboxMessageId();

    if (messageId == null) {
      setState((() {
        showToast("Inbox Message id is null");
        print("Inbox Message id is null");
      }));
      return;
    }

    await CleverTapPlugin.pushInboxNotificationViewedEventForId(messageId);

    setState((() {
      showToast(
          "Pushed NotificationViewedEvent for Inbox Message with id =  $messageId");
      print(
          "Pushed NotificationViewedEvent for Inbox Message with id =  $messageId");
    }));
  }

  Future<String>? getFirstInboxMessageId() async {
    var messageList = await CleverTapPlugin.getAllInboxMessages();
    print("inside getFirstInboxMessageId");
    Map<dynamic, dynamic> itemFirst = messageList?[0];
    print(itemFirst.toString());

    if (Platform.isAndroid) {
      return itemFirst["id"];
    } else if (Platform.isIOS) {
      return itemFirst["_id"];
    }
    return "";
  }

  Future<String>? getFirstUnreadInboxMessageId() async {
    var messageList = await CleverTapPlugin.getUnreadInboxMessages();
    print("inside getFirstUnreadInboxMessageId");

    Map<dynamic, dynamic> itemFirst = messageList?[0];
    print(itemFirst.toString());

    if (Platform.isAndroid) {
      return itemFirst["id"];
    } else if (Platform.isIOS) {
      return itemFirst["_id"];
    }
    return "";
  }

  void setOptOut() {
    if (optOut) {
      CleverTapPlugin.setOptOut(false);
      optOut = false;
      showToast("You have opted in");
    } else {
      CleverTapPlugin.setOptOut(true);
      optOut = true;
      showToast("You have opted out");
    }
  }

  void setOffline() {
    if (offLine) {
      CleverTapPlugin.setOffline(false);
      offLine = false;
      showToast("You are online");
    } else {
      CleverTapPlugin.setOffline(true);
      offLine = true;
      showToast("You are offline");
    }
  }

  void setEnableDeviceNetworkingInfo() {
    if (enableDeviceNetworkingInfo) {
      CleverTapPlugin.enableDeviceNetworkInfoReporting(false);
      enableDeviceNetworkingInfo = false;
      showToast("You have disabled device networking info");
    } else {
      CleverTapPlugin.enableDeviceNetworkInfoReporting(true);
      enableDeviceNetworkingInfo = true;
      showToast("You have enabled device networking info");
    }
  }

  void recordScreenView() {
    var screenName = "Home Screen";
    CleverTapPlugin.recordScreenView(screenName);
  }

  void eventGetFirstTime() {
    var eventName = "Flutter Event";
    CleverTapPlugin.eventGetFirstTime(eventName).then((eventFirstTime) {
      if (eventFirstTime == null) return;
      setState((() {
        showToast("Event First time CleverTap = " + eventFirstTime.toString());
        print("Event First time CleverTap = " + eventFirstTime.toString());
      }));
    }).catchError((error) {
      setState(() {
        print("$error");
      });
    });
  }

  void eventGetLastTime() {
    var eventName = "Flutter Event";
    CleverTapPlugin.eventGetLastTime(eventName).then((eventLastTime) {
      if (eventLastTime == null) return;
      setState((() {
        showToast("Event Last time CleverTap = " + eventLastTime.toString());
        print("Event Last time CleverTap = " + eventLastTime.toString());
      }));
    }).catchError((error) {
      setState(() {
        print("$error");
      });
    });
  }

  void eventGetOccurrences() {
    var eventName = "Flutter Event";
    CleverTapPlugin.eventGetOccurrences(eventName).then((eventOccurrences) {
      if (eventOccurrences == null) return;
      setState((() {
        showToast(
            "Event detail from CleverTap = " + eventOccurrences.toString());
        print("Event detail from CleverTap = " + eventOccurrences.toString());
      }));
    }).catchError((error) {
      setState(() {
        print("$error");
      });
    });
  }

  void getEventDetail() {
    var eventName = "Flutter Event";
    CleverTapPlugin.eventGetDetail(eventName).then((eventDetailMap) {
      if (eventDetailMap == null) return;
      setState((() {
        showToast("Event detail from CleverTap = " + eventDetailMap.toString());
        print("Event detail from CleverTap = " + eventDetailMap.toString());
      }));
    }).catchError((error) {
      setState(() {
        print("$error");
      });
    });
  }

  void getEventHistory() {
    var eventName = "Flutter Event";
    CleverTapPlugin.getEventHistory(eventName).then((eventDetailMap) {
      if (eventDetailMap == null) return;
      setState((() {
        showToast(
            "Event History from CleverTap = " + eventDetailMap.toString());
        print("Event History from CleverTap = " + eventDetailMap.toString());
      }));
    }).catchError((error) {
      setState(() {
        print("$error");
      });
    });
  }

  void setLocation() {
    var lat = 19.07;
    var long = 72.87;
    CleverTapPlugin.setLocation(lat, long);
    showToast("Location is set");
  }

  void setLocale() {
    Locale locale = Locale('en', 'IN');
    CleverTapPlugin.setLocale(locale);
    showToast("Locale is set");
  }

  void getCTAttributionId() {
    CleverTapPlugin.profileGetCleverTapAttributionIdentifier()
        .then((attributionId) {
      if (attributionId == null) return;
      setState((() {
        showToast("Attribution Id = " + "$attributionId");
        print("Attribution Id = " + "$attributionId");
      }));
    }).catchError((error) {
      setState(() {
        print("$error");
      });
    });
  }

  void getCleverTapId() {
    CleverTapPlugin.getCleverTapID().then((clevertapId) {
      if (clevertapId == null) return;
      setState((() {
        showToast("$clevertapId");
        print("$clevertapId");
      }));
    }).catchError((error) {
      setState(() {
        print("$error");
      });
    });
  }

  void onUserLogin() async {
    var profile = {
      'Name': 'sarveshgk10',
      'Email': 'sarveshgk10@gmail.com',
      'Phone': '914155551234',
      'Photo': "",
      'checkin_longest_streak_count': "",
      'checkin_current_streak_count': "",
      'token_fcm': ""
    };
    await CleverTapPlugin.onUserLogin(profile);
    showToast("onUserLogin called, check console for details");
  }

  void removeProfileValue() {
    CleverTapPlugin.profileRemoveValueForKey("props");
    showToast("check console for details");
  }

  void setProfileMultiValue() {
    var values = ["value1", "value2"];
    CleverTapPlugin.profileSetMultiValues("props", values);
    showToast("check console for details");
  }

  void addMultiValue() {
    var value = "value1";
    CleverTapPlugin.profileAddMultiValue("props", value);
    showToast("check console for details");
  }

  void incrementValue() {
    var value = 15;
    CleverTapPlugin.profileIncrementValue("score", value);
    showToast("check console for details");
  }

  void decrementValue() {
    var value = 10;
    CleverTapPlugin.profileDecrementValue("score", value);
    showToast("check console for details");
  }

  void addMultiValues() {
    var values = ["value1", "value2"];
    CleverTapPlugin.profileAddMultiValues("props", values);
    showToast("check console for details");
  }

  void removeMultiValue() {
    var value = "value1";
    CleverTapPlugin.profileRemoveMultiValue("props", value);
    showToast("check console for details");
  }

  void removeMultiValues() {
    var values = ["value1", "value2"];
    CleverTapPlugin.profileRemoveMultiValues("props", values);
    showToast("check console for details");
  }

  void getTimeElapsed() {
    CleverTapPlugin.sessionGetTimeElapsed().then((timeElapsed) {
      if (timeElapsed == null) return;
      setState((() {
        showToast("Session Time Elapsed = " + timeElapsed.toString());
        print("Session Time Elapsed = " + timeElapsed.toString());
      }));
    }).catchError((error) {
      setState(() {
        print("$error");
      });
    });
  }

  void getTotalVisits() {
    CleverTapPlugin.sessionGetTotalVisits().then((totalVisits) {
      if (totalVisits == null) return;
      setState((() {
        showToast("Session Total Visits = " + totalVisits.toString());
        print("Session Total Visits = " + totalVisits.toString());
      }));
    }).catchError((error) {
      setState(() {
        print("$error");
      });
    });
  }

  void getScreenCount() {
    CleverTapPlugin.sessionGetScreenCount().then((screenCount) {
      if (screenCount == null) return;
      setState((() {
        showToast("Session Screen Count = " + screenCount.toString());
        print("Session Screen Count = " + screenCount.toString());
      }));
    }).catchError((error) {
      setState(() {
        print("$error");
      });
    });
  }

  void getPreviousVisitTime() {
    CleverTapPlugin.sessionGetPreviousVisitTime().then((previousTime) {
      if (previousTime == null) return;
      setState((() {
        showToast("Session Previous Visit Time = " + previousTime.toString());
        print("Session Previous Visit Time = " + previousTime.toString());
      }));
    }).catchError((error) {
      setState(() {
        print("$error");
      });
    });
  }

  void getUTMDetails() {
    CleverTapPlugin.sessionGetUTMDetails().then((utmDetails) {
      if (utmDetails == null) return;
      setState((() {
        showToast("Session UTM Details = " + utmDetails.toString());
        print("Session UTM Details = " + utmDetails.toString());
      }));
    }).catchError((error) {
      setState(() {
        print("$error");
      });
    });
  }

  void suspendInAppNotifications() {
    CleverTapPlugin.suspendInAppNotifications();
    showToast("InApp notification is suspended");
  }

  void discardInAppNotifications() {
    CleverTapPlugin.discardInAppNotifications();
    showToast("InApp notification is discarded");
  }

  void resumeInAppNotifications() {
    CleverTapPlugin.resumeInAppNotifications();
    showToast("InApp notification is resumed");
  }

  void enablePersonalization() {
    CleverTapPlugin.enablePersonalization();
    showToast("Personalization enabled");
    print("Personalization enabled");
  }

  void disablePersonalization() {
    CleverTapPlugin.disablePersonalization();
    showToast("Personalization disabled");
    print("Personalization disabled");
  }

  void getAdUnits() async {
    List? displayUnits = await CleverTapPlugin.getAllDisplayUnits();
    showToast("check console for logs");
    print("Display Units Payload = " + displayUnits.toString());

    // Uncomment to print payload.
    // printDisplayUnitPayload(displayUnits);
  }

  void fetch() {
    CleverTapPlugin.fetch();
    showToast("check console for logs");

    ///CleverTapPlugin.fetchWithMinimumIntervalInSeconds(0);
  }

  void activate() {
    CleverTapPlugin.activate();
    showToast("check console for logs");
  }

  void fetchAndActivate() {
    CleverTapPlugin.fetchAndActivate();
    showToast("check console for logs");
  }

  void promptForPushNotification() {
    var fallbackToSettings = true;
    CleverTapPlugin.promptForPushNotification(fallbackToSettings);
    showToast("Prompt Push Permission");
  }

  void localHalfInterstitialPushPrimer() {
    var pushPrimerJSON = {
      'inAppType': 'half-interstitial',
      'titleText': 'Get Notified',
      'messageText':
          'Please enable notifications on your device to use Push Notifications.',
      'followDeviceOrientation': false,
      'positiveBtnText': 'Allow',
      'negativeBtnText': 'Cancel',
      'fallbackToSettings': true,
      'backgroundColor': '#FFFFFF',
      'btnBorderColor': '#000000',
      'titleTextColor': '#000000',
      'messageTextColor': '#000000',
      'btnTextColor': '#000000',
      'btnBackgroundColor': '#FFFFFF',
      'btnBorderRadius': '4',
      'imageUrl':
          'https://icons.iconarchive.com/icons/treetog/junior/64/camera-icon.png'
    };
    CleverTapPlugin.promptPushPrimer(pushPrimerJSON);
    showToast("Half-Interstitial Push Primer");
  }

  void localAlertPushPrimer() {
    this.setState(() async {
      bool? isPushPermissionEnabled =
          await CleverTapPlugin.getPushNotificationPermissionStatus();
      if (isPushPermissionEnabled == null) return;

      // Check Push Permission status and then call `promptPushPrimer` if not enabled.
      if (!isPushPermissionEnabled) {
        var pushPrimerJSON = {
          'inAppType': 'alert',
          'titleText': 'Get Notified',
          'messageText': 'Enable Notification permission',
          'followDeviceOrientation': true,
          'positiveBtnText': 'Allow',
          'negativeBtnText': 'Cancel',
          'fallbackToSettings': true
        };
        CleverTapPlugin.promptPushPrimer(pushPrimerJSON);
        showToast("Alert Push Primer");
      } else {
        print("Push Permission is already enabled.");
      }
    });
  }

  void syncVariables() {
    CleverTapPlugin.syncVariables();
    showToast("Sync Variables");
    print("PE -> Sync Variables");
  }

  void fetchVariables() {
    showToast("Fetch Variables");
    this.setState(() async {
      bool? success = await CleverTapPlugin.fetchVariables();
      print("PE -> fetchVariables result: " + success.toString());
    });
  }

  void defineVariables() {
    var variables = {
      'flutter_var_string': 'flutter_var_string_value',
      'flutter_var_map': {'flutter_var_map_string': 'flutter_var_map_value'},
      'flutter_var_int': 6,
      'flutter_var_float': 6.9,
      'flutter_var_boolean': true
    };
    CleverTapPlugin.defineVariables(variables);
    showToast("Define Variables");
    print("PE -> Define Variables: " + variables.toString());
  }

  void getVariables() {
    showToast("Get Variables");
    this.setState(() async {
      Map<Object?, Object?> variables = await CleverTapPlugin.getVariables();
      print('PE -> getVariables: ' + variables.toString());
    });
  }

  void getVariable() {
    showToast("Get Variable");
    this.setState(() async {
      var variable = await CleverTapPlugin.getVariable('flutter_var_string');
      print('PE -> variable value for key \'flutter_var_string\': ' +
          variable.toString());
    });
  }

  void onVariablesChanged() {
    showToast("onVariablesChanged");
    CleverTapPlugin.onVariablesChanged((variables) {
      print("PE -> onVariablesChanged: " + variables.toString());
    });
  }

  void onValueChanged() {
    showToast("onValueChanged");
    CleverTapPlugin.onValueChanged('flutter_var_string', (variable) {
      print("PE -> onValueChanged: " + variable.toString());
    });
  }

  void handleDeeplink(Map<String, dynamic> notificationPayload) {
    var type = notificationPayload["type"];
    var title = notificationPayload["nt"];
    var message = notificationPayload["nm"];

    if (type != null) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  DeepLinkPage(type: type, title: title, message: message)));
    }

    print(
        "_handleKilledStateNotificationInteraction => Type: $type, Title: $title, Message: $message ");
  }
}