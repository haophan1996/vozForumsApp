import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vozforums/Page/Settings/SettingsBinding.dart';
import 'package:vozforums/Page/Settings/SettingsUI.dart';
import 'package:vozforums/Page/UserProfile/UserProfileBinding.dart';
import 'package:vozforums/Page/UserProfile/UserProfileUI.dart';
import 'package:vozforums/Page/View/ViewBinding.dart';
import 'package:vozforums/Page/View/ViewUI.dart';
import 'package:vozforums/Page/home/homeBinding.dart';
import 'package:vozforums/Page/Thread/subThreadBinding.dart';
import 'package:vozforums/Page/Thread/subThreadUI.dart';
import 'package:vozforums/Page/languages.dart';
import 'package:vozforums/theme.dart';
import 'GlobalController.dart';
import 'Page/NavigationDrawer/NaviDrawerController.dart';
import 'Page/home/homeUI.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put<GlobalController>(GlobalController());
  Get.put<NaviDrawerController>(NaviDrawerController(), permanent: true);
  await GetStorage.init().then((value) async {
    await GlobalController.i.checkUserSetting();
  });
  runApp(MyPage());
}

class MyPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.cupertino,
      transitionDuration: Duration(milliseconds: 200),
      translations: Language(),
      locale: GlobalController.i.langList.elementAt(GlobalController.i.userStorage.read('lang')),
      theme: Themes().lightTheme,
      darkTheme: Themes().darkTheme,
      initialRoute: "/HomePage",
      getPages: [
        GetPage(name: "/HomePage", page: () => HomePageUI(), popGesture: true, binding: HomeBinding(), maintainState: false),
        GetPage(name: "/ThreadPage", page: () => ThreadUI(), popGesture: true, binding: ThreadBinding(), maintainState: false),
        GetPage(
            name: "/ViewPage",
            page: () => ViewUI(),
            transition: Transition.rightToLeft,
            transitionDuration: Duration(milliseconds: 200),
            popGesture: true,
            //binding: ViewBinding(),
            maintainState: false),
        GetPage(name: "/UserProfile", page: () => UserProfileUI(), popGesture: true, binding: UserProfileBinding(), maintainState: false),
        GetPage(
            name: "/Settings",
            page: () => SettingsUI(),
            popGesture: true,
            binding: SettingsBinding(),
            transition: Transition.rightToLeft,
            transitionDuration: Duration(milliseconds: 200),
            maintainState: false),
      ],
    );
  }
}
