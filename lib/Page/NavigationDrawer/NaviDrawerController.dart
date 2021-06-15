import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../GlobalController.dart';
import 'package:http/http.dart' as http;

class NaviDrawerController extends GetxController {
  static NaviDrawerController get i => Get.find();
  double heightAppbar = 45;
  TextEditingController textEditingControllerLogin = TextEditingController();
  TextEditingController textEditingControllerPassword = TextEditingController();

  RxString nameUser = ''.obs;
  RxString titleUser = ''.obs;
  RxString avatarUser = ''.obs;
  RxString linkUser = ''.obs;
  RxString statusLogin = ''.obs;

  Future<void> loginFunction() async {

    if (textEditingControllerLogin.text.length < 6 || textEditingControllerPassword.text.length <6){
      statusLogin.value = 'Login or Password maybe too short ?';
      Get.back();
      return;
    }

    final getMyData = await login(textEditingControllerLogin.text, textEditingControllerPassword.text, GlobalController.i.dataCsrf,
        GlobalController.i.xfCsrf, textEditingControllerLogin.text);

    if (getMyData == 'none') {
      await Future.delayed(Duration(milliseconds: 3000), () async {
        Get.back();
      });
      statusLogin.value = "Incorrect ID/Password or server busy\nIf this continue happens, please restart app and try again";
    } else {
      statusLogin.value = "Success";
      statusLogin.value = '';
      await GlobalController.i.userStorage.remove('userLoggedIn');
      await GlobalController.i.userStorage.remove('xf_user');
      await GlobalController.i.userStorage.remove('xf_session');
      await GlobalController.i.userStorage.remove('date_expire');

      await GlobalController.i.userStorage.write("userLoggedIn", true);
      await GlobalController.i.userStorage.write("xf_user", getMyData['xf_user']);
      await GlobalController.i.userStorage.write("xf_session", getMyData['xf_session']);
      await GlobalController.i.userStorage.write("date_expire", getMyData['date_expire']);
      await GlobalController.i.setDataUser();
      await getUserProfile();
      await Future.delayed(Duration(milliseconds: 3000), () async {
        Get.back();
        Get.back();
      });

    }
  }

  getUserProfile() async{
    await GlobalController.i.getBody(GlobalController.i.url, false).then((res) async {
      String linkProfile = res.getElementsByTagName('form')[1].attributes['action']!.split('/post')[0];
      linkUser.value = linkProfile;
       await GlobalController.i.getBody(GlobalController.i.url+linkProfile, false).then((value) {
        nameUser.value = value.documentElement!.getElementsByClassName(' is-stroked')[0].getElementsByTagName('span')[0].innerHtml;
        titleUser.value = value.documentElement!.getElementsByClassName('userTitle')[0].innerHtml;
        if (value.documentElement!.getElementsByClassName('avatar avatar--l').map((e)=>e.innerHtml).first.contains('span') == true){
          avatarUser.value = 'no';
        } else {
          avatarUser.value = value.documentElement!.getElementsByClassName('avatarWrapper')[0].getElementsByTagName('img')[0].attributes['src'].toString();
        }
      });
    });
  }

  login(String login, String pass, String token, String cookie, String userAgent) async {
    var headers = {
      'content-type': 'application/json; charset=UTF-8',
      'host': 'vozloginapinode.herokuapp.com',
    };
    var map = {"login": login, "password": pass, "remember": "1", "_xfToken": token, "userAgent": userAgent, "cookie": cookie};

    final response = await http.post(Uri.parse("https://vozloginapinode.herokuapp.com/api/vozlogin"), headers: headers, body: jsonEncode(map));

    if (response.statusCode != 200) {
      return "none";
    } else {
      return jsonDecode(response.body);
    }
  }

  logout() async{
    GlobalController.i.dio.options.headers['cookie'] = '';
    GlobalController.i.isLogged.value = false;
    nameUser.value = '';
    titleUser.value = '';
    avatarUser.value = '';
    linkUser.value = '';
    await GlobalController.i.userStorage.remove("userLoggedIn");
    await GlobalController.i.userStorage.remove("xf_user");
    await GlobalController.i.userStorage.remove("xf_session");
    await GlobalController.i.userStorage.remove("date_expire");
  }
}
