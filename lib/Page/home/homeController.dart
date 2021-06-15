import 'package:get/get.dart';
import 'package:vozforums/GlobalController.dart';
import 'package:vozforums/Page/NavigationDrawer/NaviDrawerController.dart';

class HomeController extends GetxController {
  late String header;
  late String label;
  RxList myHomePage = [].obs;

  @override
  onInit() async {
    super.onInit();
    GlobalController.i.percentDownload.value = 0.01;
    await GlobalController.i.setDataUser();
    await loading();
  }

  loading() async {
    await GlobalController.i.getBody(GlobalController.i.url, true).then((doc) async {
      //Set token
      GlobalController.i.dataCsrf = doc.getElementsByTagName('html')[0].attributes['data-csrf'];
      GlobalController.i.isLogged.value = doc.getElementsByTagName('html')[0].attributes['data-logged-in'] == 'true' ? true : false;
      if (doc.getElementsByTagName('html')[0].attributes['data-logged-in'] == 'true') {
        NaviDrawerController.i.getUserProfile();
      }

      doc.getElementsByClassName("block block--category block--category").forEach((value) {
        value.getElementsByClassName("node-body").forEach((element) {
          myHomePage.add({
            "header": value.getElementsByTagName("a")[0].innerHtml.replaceAll("&amp;", "&"),
            "title": (element.getElementsByClassName("label label").length > 0
                    ? (element.getElementsByClassName("label label")[0].innerHtml + ": ")
                    : "") +
                element.getElementsByClassName("node-extra-row").map((e) => e.getElementsByTagName("a")[0].attributes["title"]).first!.trim(),
            "subHeader": element.getElementsByTagName("a")[0].innerHtml.trim().replaceAll("&amp;", "&"),
            "linkSubHeader": element.getElementsByTagName("a")[0].attributes['href'].toString(),
            "threads": "Threads: " +
                element.getElementsByClassName("pairs pairs--inline").map((e) => e.getElementsByTagName("dd")[0].innerHtml).elementAt(0),
            "messages": "Messages: " +
                element.getElementsByClassName("pairs pairs--inline").map((e) => e.getElementsByTagName("dd")[0].innerHtml).elementAt(1)
          });
        });
      });
    });
  }

  navigateToThread(String title, String link) async {
    Future.delayed(Duration(milliseconds: 200), () {
      Get.toNamed("/ThreadPage", arguments: [title, GlobalController.i.url + link]);
    });
  }
}
// doc = await GlobalController.i.getBody(GlobalController.i.url);
// late dom.Document doc;
// doc.getElementsByClassName("block block--category block--category")
