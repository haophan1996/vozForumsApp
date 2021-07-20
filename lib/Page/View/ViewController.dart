import 'dart:convert';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reaction_button/flutter_reaction_button.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vozforums/GlobalController.dart';
import 'package:vozforums/Page/reuseWidget.dart';
import 'dart:io';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'package:http/http.dart' as http;

class ViewController extends GetxController {
  List htmlData = [];
  RxList reactionList = [].obs;
  int currentPage = 0, totalPage = 0;
  Map<String, dynamic> data = {};
  int lengthHtmlDataList = 0;
  late var _user;
  late dom.Document res;
  late RefreshController refreshController = RefreshController(initialRefresh: false);
  late ScrollController listViewScrollController = ScrollController();
  late ItemScrollController itemScrollController = ItemScrollController();
  late PanelController panelController = PanelController();

  @override
  Future<void> onInit() async {
    super.onInit();
    data['subHeader'] = Get.arguments[0];
    data['subTypeHeader'] = Get.arguments[2] ?? '';
    data['view'] = Get.arguments[3];
  }

  @override
  Future<void> onReady() async {
    super.onReady();
    data['subLink'] = Get.arguments[1];

    data['view'] == 0
        ? await loadUserPost(data['fullUrl'] = GlobalController.i.url + data['subLink'])
        : await loadInboxView(data['fullUrl'] = GlobalController.i.url + data['subLink']);
    if (data['fullUrl'].contains("/unread") == true) {
      data['fullUrl'] = data['fullUrl'].split("unread")[0];
    }
  }

  @override
  onClose() {
    super.onClose();
    GlobalController.i.tagView.removeLast();
    refreshController.dispose();
    listViewScrollController.dispose();
    reactionList.close();
    clearMemoryImageCache();
    GlobalController.i.percentDownload = -1.0;
  }

  launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: true, forceWebView: false, enableJavaScript: true);
    } else {
      throw 'Could not launch $url';
    }
  }

  _removeTag(String content) {
    return content.replaceAll(
        RegExp(r'<div class="bbCodeBlock-expandLink js-expandLink"><a role="button" tabindex="0">Click to expand...</a></div>'), "");
  }

  setPageOnClick(String toPage) async {
    if (int.parse(toPage) > totalPage) {
      HapticFeedback.heavyImpact();
      refreshController.loadComplete();
    } else {
      GlobalController.i.percentDownload = 0.01;
      data['view'] == 0
          ? await loadUserPost(data['fullUrl'] + GlobalController.i.pageLink + toPage)
          : await loadInboxView(data['fullUrl'] + GlobalController.i.pageLink + toPage);
      //await loadUserPost(data['fullUrl'] + GlobalController.i.pageLink + toPage);
    }
  }

  getImage(String url) async {
    return await getCachedImageFile(url);
  }

  write(String text) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/my_file.txt');
    await file.writeAsString(text);
    print('${directory.path}/my_file.txt');
    print(File('${directory.path}/my_file.txt').toString());
  }

  saveImage(String url) async {
    final Directory? directory = Directory("storage/emulated/0/Pictures/vozNext");
    await directory!.create();
    final File file = File((await getCachedImageFilePath(url)).toString());
    await file.copy(directory.path + "/${file.path.split("/").last}.jpg");
    print(await file.copy(directory.path + "/${file.path.split("/").last}.jpg"));
  }

  scrollToFunc() {
    itemScrollController.scrollTo(
        index: currentPage + 1, duration: Duration(milliseconds: 100), curve: Curves.slowMiddle, alignment: GlobalController.i.pageNaviAlign);
  }

  getIDYoutube(String link) {
    return link.split('embed/')[1].split('?')[0];
  }

  final flagsReactions = [
    Reaction(
      previewIcon: buildFlagsPreviewIcon('assets/reaction/0.png', 'unReact'.tr),
      icon: buildIcon('assets/reaction/nil.png', 'react'),
    ),
    Reaction(
      previewIcon: buildFlagsPreviewIcon('assets/reaction/1.png', 'sweet'.tr),
      icon: buildIcon('assets/reaction/1.png', 'sweeted'),
    ),
    Reaction(
      previewIcon: buildFlagsPreviewIcon('assets/reaction/2.png', 'brick'.tr),
      icon: buildIcon('assets/reaction/2.png', 'bricked'),
    ),
  ];

  getDataReactionList(int index) async {
    reactionList.clear();
    await GlobalController.i
        .getBody(
            '${data['view'] == 0 ? GlobalController.i.viewReactLink : GlobalController.i.inboxReactLink}' +
                htmlData.elementAt(index)['postID'] +
                '/reactions',
            false)
        .then((value) {
      value.getElementsByClassName('block-row block-row--separated').forEach((element) {
        data['rName'] = element.getElementsByClassName('username ')[0].text;
        data['rTitle'] = element.getElementsByClassName('userTitle')[0].text;
        data['rMessage'] = element.getElementsByClassName('pairs pairs--inline')[0].getElementsByTagName('dd')[0].text;
        data['rMessage2'] = element.getElementsByClassName('pairs pairs--inline')[1].getElementsByTagName('dd')[0].text;
        data['rMessage3'] = element.getElementsByClassName('pairs pairs--inline')[2].getElementsByTagName('dd')[0].text;
        data['rTime'] = element.getElementsByClassName('u-dt')[0].text;
        data['rReactIcon'] = element.getElementsByClassName('reaction-image js-reaction')[0].attributes['alt'].toString() == 'Ưng' ? '1' : '2';
        data['avatar'] = element.getElementsByClassName('avatar')[0].getElementsByTagName('img').length > 0
            ? element.getElementsByClassName('avatar')[0].getElementsByTagName('img')[0].attributes['src']
            : 'no';
        reactionList.add({
          'rName': data['rName'],
          'rTitle': data['rTitle'],
          'rMessage': data['rMessage'],
          'rMessage2': data['rMessage2'],
          'rMessage3': data['rMessage3'],
          'rTime': data['rTime'],
          'rReactIcon': data['rReactIcon'],
          'rAvatar': data['avatar'],
        });
      });
    });
  }

  Future<void> loadUserPost(String url) async {
    data['_commentImg'] = '';
    await GlobalController.i.getBody(url, false).then((value) async {
      lengthHtmlDataList = htmlData.length;
      data['dataCsrfPost'] = value.getElementsByTagName('html')[0].attributes['data-csrf'];
      data['xfCsrfPost'] = GlobalController.i.xfCsrfPost;
      if (value.getElementsByTagName('html')[0].attributes['data-logged-in'] == 'true') {
        GlobalController.i.isLogged.value = true;
        // NaviDrawerController.i.titleUser.value = GlobalController.i.userStorage.read('titleUser');
        // NaviDrawerController.i.linkUser.value = GlobalController.i.userStorage.read('linkUser');
        // NaviDrawerController.i.avatarUser.value = GlobalController.i.userStorage.read('avatarUser');
        // NaviDrawerController.i.nameUser.value = GlobalController.i.userStorage.read('nameUser');
        GlobalController.i.inboxNotifications = value.getElementsByClassName('p-navgroup-link--conversations').length > 0
            ? int.parse(value.getElementsByClassName('p-navgroup-link--conversations')[0].attributes['data-badge'].toString())
            : 0;
        GlobalController.i.alertNotifications = value.getElementsByClassName('p-navgroup-link--alerts').length > 0
            ? int.parse(value.getElementsByClassName('p-navgroup-link--alerts')[0].attributes['data-badge'].toString())
            : 0;
        GlobalController.i.update();
      } else
        GlobalController.i.isLogged.value = false;

      value.getElementsByClassName("block block--messages").forEach((element) {
        var lastP = element.getElementsByClassName("pageNavSimple");
        if (lastP.length == 0) {
          currentPage = 1;
          totalPage = 1;
        } else {
          data['fullUrl'] =
              GlobalController.i.url + element.getElementsByClassName('pageNav-page ')[0].getElementsByTagName('a')[0].attributes['href'].toString();
          var naviPage = element.getElementsByClassName("pageNavSimple-el pageNavSimple-el--current").first.innerHtml.trim();
          currentPage = int.parse(naviPage.replaceAll(RegExp(r'[^0-9]\S*'), ""));
          totalPage = int.parse(naviPage.replaceAll(RegExp(r'\S*[^0-9]'), ""));
        }
        //Get post
        element.getElementsByClassName("message message--post js-post js-inlineModContainer").forEach((element) {
          data['_postContent'] = element.getElementsByClassName("message-body js-selectToQuote").map((e) => e.outerHtml).first;
          data['_userPostDate'] = element.getElementsByClassName("u-concealed").map((e) => e.getElementsByTagName("time")[0].innerHtml).first;

          _user = element.getElementsByClassName("message-cell message-cell--user");
          data['_userLink'] = _user.map((e) => e.getElementsByTagName("a")[1].attributes['href']).first!;
          data['_userTitle'] = _user.map((e) => e.getElementsByClassName("userTitle message-userTitle")[0].innerHtml).first;
          if (_user.map((e) => e.getElementsByTagName("img").length).toString() == "(1)") {
            data['_userAvatar'] = _user.map((e) => e.getElementsByTagName("img")[0].attributes['src']).first!;
          } else {
            data['_userAvatar'] = "no";
          }

          data['_userName'] = _user.map((e) => e.getElementsByTagName("a")[1].text).first;

          data['_orderPost'] = element
              .getElementsByClassName("message-attribution-opposite message-attribution-opposite--list")
              .map((e) => e.getElementsByTagName("a")[GlobalController.i.isLogged.value == true ? 2 : 1].innerHtml)
              .first
              .trim();

          if (element.getElementsByClassName('reactionsBar-link').length > 0) {
            data['_commentName'] = element.getElementsByClassName('reactionsBar-link')[0].innerHtml.replaceAll(RegExp(r"<[^>]*>"), '');

            if (element.getElementsByClassName('has-reaction').length > 0) {
              if (element.getElementsByClassName('has-reaction')[0].getElementsByTagName('img')[0].attributes['title'] == 'Ưng') {
                data['_commentByMe'] = '1';
              } else
                data['_commentByMe'] = '2';
            } else
              data['_commentByMe'] = '0';

            element.getElementsByClassName('reactionSummary').forEach((element) {
              element.getElementsByClassName('reaction reaction--small').forEach((element) {
                data['_commentImg'] += element.attributes['data-reaction-id'].toString();
              });
            });
          } else {
            data['_commentImg'] = 'no';
            data['_commentName'] = '';
            data['_commentByMe'] = '0';
          }
          htmlData.add({
            'newPost': element.getElementsByClassName('message-newIndicator').isNotEmpty == false ? false : true,
            "postContent": _removeTag(data['_postContent']),
            "userPostDate": data['_userPostDate'],
            "userName": data['_userName'],
            "userLink": data['_userLink'],
            "userTitle": data['_userTitle'],
            "userAvatar": (data['_userAvatar'] == "no" || data['_userAvatar'].contains("https://"))
                ? data['_userAvatar']
                : GlobalController.i.url + data['_userAvatar'],
            "orderPost": data['_orderPost'],
            "commentName": data['_commentName'],
            "commentImage": data['_commentImg'],
            "postID": element.attributes['id']!.split('t-')[1],
            'commentByMe': int.parse(data['_commentByMe'])
          });
          data['_commentImg'] = '';
        });
      });
      update();
      if (Get.isDialogOpen == true || refreshController.isLoading) {
        if (Get.isDialogOpen == true) Get.back();
        htmlData.removeRange(0, lengthHtmlDataList);
        listViewScrollController.jumpTo(-10.0);
      }
      refreshController.loadComplete();
    });
    await Future.delayed(Duration(milliseconds: 50), () {
      scrollToFunc();
    });
  }

  Future<void> loadInboxView(String link) async {
    data['_commentImg'] = '';
    await GlobalController.i.getBody(link, false).then((value) {
      lengthHtmlDataList = htmlData.length;
      data['dataCsrfPost'] = value.getElementsByTagName('html')[0].attributes['data-csrf'];
      data['xfCsrfPost'] = GlobalController.i.xfCsrfPost;
      if (value.getElementsByTagName('html')[0].attributes['data-logged-in'] == 'true') {
        GlobalController.i.isLogged.value = true;
        // NaviDrawerController.i.titleUser.value = GlobalController.i.userStorage.read('titleUser');
        // NaviDrawerController.i.linkUser.value = GlobalController.i.userStorage.read('linkUser');
        // NaviDrawerController.i.avatarUser.value = GlobalController.i.userStorage.read('avatarUser');
        // NaviDrawerController.i.nameUser.value = GlobalController.i.userStorage.read('nameUser');
        GlobalController.i.inboxNotifications = value.getElementsByClassName('p-navgroup-link--conversations').length > 0
            ? int.parse(value.getElementsByClassName('p-navgroup-link--conversations')[0].attributes['data-badge'].toString())
            : 0;
        GlobalController.i.alertNotifications = value.getElementsByClassName('p-navgroup-link--alerts').length > 0
            ? int.parse(value.getElementsByClassName('p-navgroup-link--alerts')[0].attributes['data-badge'].toString())
            : 0;
        GlobalController.i.update();
      } else
        GlobalController.i.isLogged.value = false;


      var lastP = value.getElementsByClassName("pageNavSimple");
      if (lastP.length == 0) {
        currentPage = 1;
        totalPage = 1;
      } else {
        data['fullUrl'] =
            GlobalController.i.url + value.getElementsByClassName('pageNav-page ')[0].getElementsByTagName('a')[0].attributes['href'].toString();
        var naviPage = value.getElementsByClassName("pageNavSimple-el pageNavSimple-el--current").first.innerHtml.trim();
        currentPage = int.parse(naviPage.replaceAll(RegExp(r'[^0-9]\S*'), ""));
        totalPage = int.parse(naviPage.replaceAll(RegExp(r'\S*[^0-9]'), ""));
      }

      value.getElementsByClassName('message message--conversationMessage').forEach((element) {
        data['_postContent'] = _removeTag(element.getElementsByClassName('message-body js-selectToQuote')[0].getElementsByClassName('bbWrapper')[0].innerHtml);
        data['postID'] =
            element.getElementsByClassName('actionBar-action actionBar-action--mq u-jsOnly js-multiQuote')[0].attributes['data-message-id'];
        data['name'] = element.getElementsByClassName('username ')[0].text;
        data['title'] = element.getElementsByClassName('message-userTitle')[0].text;
        data['date'] = element.getElementsByClassName('u-dt')[0].text;
        if (element.getElementsByClassName('message-avatar-wrapper')[0].getElementsByTagName('img').length > 0) {
          data['avatar'] = element.getElementsByClassName('message-avatar-wrapper')[0].getElementsByTagName('img')[0].attributes['src'].toString();
        } else {
          data['avatar'] = 'no';
        }

        if (element.getElementsByClassName('reactionsBar-link').length > 0) {
          data['_commentName'] = element.getElementsByClassName('reactionsBar-link')[0].innerHtml.replaceAll(RegExp(r"<[^>]*>"), '');

          if (element.getElementsByClassName('has-reaction').length > 0) {
            if (element.getElementsByClassName('has-reaction')[0].getElementsByTagName('img')[0].attributes['title'] == 'Ưng') {
              data['_commentByMe'] = '1';
            } else
              data['_commentByMe'] = '2';
          } else
            data['_commentByMe'] = '0';

          element.getElementsByClassName('reactionSummary').forEach((element) {
            element.getElementsByClassName('reaction reaction--small').forEach((element) {
              data['_commentImg'] += element.attributes['data-reaction-id'].toString();
            });
          });
        } else {
          data['_commentImg'] = 'no';
          data['_commentName'] = '';
          data['_commentByMe'] = '0';
        }
        htmlData.add({
          'newPost': false,
          'postContent': data['_postContent'],
          'userPostDate': data['date'],
          'postID': data['postID'],
          'userName': data['name'],
          'userTitle': data['title'],
          'userAvatar': (data['avatar'] == "no" || data['avatar'].contains("https://")) ? data['avatar'] : GlobalController.i.url + data['avatar'],
          'commentName': data['_commentName'],
          'commentImage': data['_commentImg'],
          'commentByMe': int.parse(data['_commentByMe']),
          'userLink': '',
          'orderPost': '',
        });
        data['_commentImg'] = '';
      });
      update();
      if (Get.isDialogOpen == true || refreshController.isLoading) {
        if (Get.isDialogOpen == true) Get.back();
        htmlData.removeRange(0, lengthHtmlDataList);
        listViewScrollController.jumpTo(-10.0);
      }
      refreshController.loadComplete();
    });
    await Future.delayed(Duration(milliseconds: 50), () {
      scrollToFunc();
    });
  }

  Future reactionPost(int index, String idPost, int idReact, BuildContext context) async {
    var status = {};
    setDialog('popMess'.tr, 'popMess5'.tr);
    var headers = {
      'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'host': 'voz.vn',
      'cookie': '${data['xfCsrfPost']}; xf_user=${GlobalController.i.xfUser};',
    };
    var body = {'_xfWithData': '1', '_xfToken': '${data['dataCsrfPost']}', '_xfResponseType': 'json'};

    await GlobalController.i
        .getHttpPost(headers, body,
            '${data['view'] == 0 ? GlobalController.i.viewReactLink : GlobalController.i.inboxReactLink}$idPost/react?reaction_id=$idReact?reaction_id=$idReact')
        .then((jsonValue) {
      if (jsonValue['status'] == 'error') {
        status['status'] = 'error';
        status['mess'] = jsonValue['errors'].first;
      } else {
        final value = parser.parse(jsonValue['reactionList']['content']);
        if (value.documentElement!.getElementsByClassName('reactionsBar-link').length > 0) {
          data['_commentImg'] = '';
          value.getElementsByClassName('reaction reaction--small reaction').forEach((element) {
            data['_commentImg'] += element.attributes['data-reaction-id'].toString();
          });

          htmlData.elementAt(index)['commentName'] =
              value.documentElement!.getElementsByClassName('reactionsBar-link')[0].innerHtml.replaceAll(RegExp(r"<[^>]*>"), '');
          htmlData.elementAt(index)['commentImage'] = data['_commentImg'];
        } else {
          htmlData.elementAt(index)['commentName'] = '';
          htmlData.elementAt(index)['commentImage'] = 'no';
        }
        status['status'] = 'ok';
        status['mess'] = '';
      }
    });
    update();
    Get.back();
    return status;
  }

  reply(String message, bool isReply) async {
    //                                            token               xf_csrf             link
    var x = await Get.toNamed('/PostStatus', arguments: [data['xfCsrfPost'], data['dataCsrfPost'], data['fullUrl'], message]);
    if (x?[0] == 'ok'){
      if (await GlobalController.i.userStorage.read('scrollToMyRepAfterPost') == true){
        String lastPage = totalPage.toString();
        await setPageOnClick(lastPage);
        if (totalPage.toString() != lastPage){
          await setPageOnClick(totalPage.toString());
        }
        listViewScrollController.jumpTo(listViewScrollController.position.maxScrollExtent);
      }
    }
  }



  editRep(int index) async{
    if (Get.isBottomSheetOpen==true) Get.back();
    setDialog('loading3', 'loading3');

    String url = '${data['view'] == 0 ? GlobalController.i.viewReactLink : GlobalController.i.inboxReactLink}${htmlData.elementAt(index)['postID']}/edit?_xfToken=${data['dataCsrfPost']}&_xfResponseType=json';
    var headers = {
      'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'host': 'voz.vn',
      'cookie': '${data['xfCsrfPost']}; xf_user=${GlobalController.i.xfUser};',
    };


    await GlobalController.i.getHttp(headers,url).then((value) {
      if (Get.isDialogOpen == true) Get.back();
      if (value['status'] == 'ok'){
        //print(fixEdit(value['html']['content']));
        reply(fixEdit(value['html']['content']), false);
      } else {
        setDialogError(value['errors'][0]);
      }
    });


  }

  Future<void> quote(int index) async {
    setDialog('popMess'.tr, 'popMess2'.tr);
    var headers = {
      'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'host': 'voz.vn',
      'cookie': '${data['xfCsrfPost']}; xf_user=${GlobalController.i.xfUser};',
    };
    var body = {'_xfWithData': '1', '_xfToken': '${data['dataCsrfPost']}', '_xfResponseType': 'json'};

    await GlobalController.i.getHttpPost(headers, body, '${data['view'] == 0 ? GlobalController.i.viewReactLink : GlobalController.i.inboxReactLink}${htmlData.elementAt(index)['postID']}/quote').then(
          (value) {
            //print(value);
            Get.back();
            if (value['status'] == 'ok'){
              //print(value['quoteHtml']);
              fixQuote(value['quoteHtml']);
              //reply(value['quoteHtml']+'<br>');
            } else {
              setDialogError(value['errors'][0].toString());
            }
          },
        );
  }

  fixQuote(String html)async{
    reply(await fixHtmlUrl(html)+'<br>', true);
  }

  fixHtmlUrl(String html) async {
    dom.Document document = parser.parse(html);
    for(var element in document.getElementsByTagName('img')){
      if (element.outerHtml.contains('smilie smilie--emoji')){
        html = html.replaceAll(element.outerHtml.replaceAll('>', ' />'), element.attributes['alt'].toString());
      } else if (element.attributes['class'] == 'smilie'){
        var img = await getImageFileFromAssets(element.attributes['src']!.split('smilies/')[1].split('?')[0]);
        html = html.replaceAll(element.outerHtml.replaceAll('>', ' />'), '<img src="${img.path}" class="smilie">');
      }
    }
    return html.replaceAll('src="/attachments', 'src="https://voz.vn//attachments').replaceAll('\'', '&#039;').replaceAll('amp;', '');
  }

  fixEdit(String html){
    late List code = [];
    html = '<textarea name=' + html.split('<textarea name=')[1].split('</textarea>')[0] + '</textarea>';
    dom.Document document = parser.parse(html);
    html = document.getElementsByTagName('textarea')[0].innerHtml;

    if (html.contains('[/CODE]')==true){
      int lengthCode = (html.split('[/CODE]').length);
      while(lengthCode!=1){
        lengthCode-=1;
        String first = '[CODE'+ html.split('[CODE')[1].split('[/CODE]')[0]+'[/CODE]';
        html = html.replaceAll(first, '[comCodeLength$lengthCode]');
        code.insert(0, first);
      }
    }

    html = html.replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;nbsp;', " ")
        .replaceAll('&amp;quot;', "\"")
        .replaceAll('&amp;lt;', '<')
        .replaceAll('&amp;gt;', '>')
        .replaceAll('&amp;quot;', "\"")
        .replaceAll('&quot;', "\"");

    if (html.contains('[comCodeLength')==true){
      while(code.length != 0){
        html = html.replaceAll('[comCodeLength${code.length}]', code.elementAt(code.length-1));
        code.removeLast();
      }
    }

    return fixHtmlUrl(html);
  }

  Future<File> getImageFileFromAssets(String path) async {
    final byteData = await rootBundle.load('assets/$path');
    final file = File('${(await getTemporaryDirectory()).path}/${path.replaceAll("/", '')}');
    await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    return file;
  }
}




