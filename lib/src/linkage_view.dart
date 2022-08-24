import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef GetHearWidget<M extends BaseItem> = Widget Function(
    BuildContext context, M item);
typedef GetGeneralItem<M extends BaseItem> = Widget Function(
    BuildContext context, int index, M item);
typedef GetGroupItem<M extends BaseItem> = Widget Function(
    BuildContext context, int index, M item);
typedef OnGroupItemTap<M extends BaseItem> = void Function(
    BuildContext context, int index, M item);

class BaseItem {
  bool isHeader;
  String header;
  bool isSelect = false;
  String title;
  dynamic info;
  int index = -1;

  BaseItem(
      {this.isHeader = false, this.header = '', this.info, this.title = ''});
}

/// 双列表菜单
///
/// itemHeadHeight 是右边列表的高度
/// itemHeight 是没一项的高度
/// items 是列表内容,分head和item
/// itemBuilder是item的builder
/// groupItemBuilder是groupItem的builder
/// headerBuilder是header的builder
/// OnGroupItemTap是点击组的时候返回的回调
/// flexLeft是左边打flex
/// flexRight是右边的flex
/// duration 动画时间
/// isNeedStick 是否需要粘性头
/// curved 动画效果
///
class LinkageView<T extends BaseItem> extends StatefulWidget {
  final double itemHeadHeight;
  final double itemHeight;
  final double itemGroupHeight;

  final List<T> items;
  final GetGroupItem itemBuilder;
  final GetGeneralItem groupItemBuilder;
  final GetHearWidget? headerBuilder;
  final OnGroupItemTap? onGroupItemTap;
  final int flexLeft;
  final int flexRight;
  final int duration;
  final bool isNeedStick;
  final Curve curve;
  final List<T> groups = [];

  LinkageView(
      {Key? key,
      required this.items,
      required this.itemBuilder,
      required this.groupItemBuilder,
      this.headerBuilder,
      this.onGroupItemTap,
      this.isNeedStick = true,
      this.curve = Curves.linear,
      this.itemHeadHeight = 30,
      this.itemHeight = 50,
      this.itemGroupHeight = 50,
      this.duration = 0,
      this.flexLeft = 1,
      this.flexRight = 3})
      : super(key: key) {
    for (var i = 0; i < items.length; i++) {
      items[i]
        ..index = i
        ..isSelect = false;
      if (items[i].isHeader) {
        groups.add(items[i]);
      }
    }
  }

  @override
  _LinkageViewState createState() => _LinkageViewState();
}

class _LinkageViewState<T extends BaseItem> extends State<LinkageView> {
  bool selected = false;
  int selectIndex = 0;
  bool showTopHeader = false;
  double headerOffset = 0.0;
  T? headerStr;
  double beforeScroll = 0.0;
  VoidCallback? callback;
  late ScrollController? scrollController;
  late ScrollController? groupScrollController;
  late Size containerSize;
  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    super.dispose();
    if (callback != null) {
      scrollController?.removeListener(callback!);
    }
  }

  final GlobalKey _containerKey = GlobalKey();
  _onBuildCompleted(Duration timestamp) {
    final RenderBox? containerRenderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox;
    containerSize = containerRenderBox!.size;
  }

  Widget groupItem(BuildContext context, int index) {
    var item = widget.groups[index];
    return GestureDetector(
      onTap: () {
        if (kDebugMode) {
          print("$index tap");
        }
        if (mounted) {
          setState(() {});
          widget.onGroupItemTap?.call(context, index, widget.groups[index]);
          selectIndex = index;
          double tempLength = 0.0;
          for (var i = 0; i < widget.groups[index].index; i++) {
            double currentHeight = widget.items[i].isHeader
                ? widget.itemHeadHeight
                : widget.itemHeight;
            tempLength += currentHeight;
          }
          selected = true;
          scrollController!
              .animateTo(tempLength,
                  duration: Duration(milliseconds: widget.duration),
                  curve: Curves.linear)
              .whenComplete(() {
            selected = false;
            if (kDebugMode) {
              print("异步任务处理完成");
            }
          });
        }
      },
      child: SizedBox(
        child: widget.groupItemBuilder(context, index, item),
        height: widget.itemGroupHeight,
      ),
    );
  }

  Widget generalItem(BuildContext context, int index) {
    var item = widget.items[index];
    if (item.isHeader) {
      return SizedBox(
        child: widget.itemBuilder(context, index, item),
        height: widget.itemHeadHeight,
      );
    } else {
      return SizedBox(
        child: widget.itemBuilder(context, index, item),
        height: widget.itemHeight,
      );
    }
  }

  //初始化控制器和分组
  init() {
    scrollController ??= ScrollController();
    groupScrollController ??= ScrollController();
    headerStr = widget.items.first as T?;
    if (scrollController != null) {
      callback = () {
        double offset2 = scrollController!.offset;
        if (offset2 >= 0) {
          if (mounted) {
            setState(() {
              showTopHeader = true;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              showTopHeader = false;
            });
          }
        }
        //计算滑动了多少距离了
        double pixels = scrollController!.position.pixels;
        // print("pixels is $pixels");
        double tempLength = 0.0;
        int position = 0;
        double offset = 0;
        double currentHeight = 0;

        for (var i = 0; i < widget.items.length; i++) {
          currentHeight = widget.items[i].isHeader
              ? widget.itemHeadHeight
              : widget.itemHeight;
          tempLength += currentHeight;
          if (widget.items[i].isHeader) {
            headerStr?.isSelect = false;
            headerStr = widget.items[i] as T?;
            headerStr?.isSelect = true;
          }
          //滚动的大小没有超过最大的item index,那么当前地一个item的下标就是index
          if (tempLength >= pixels) {
            position = i;
            break;
          }
        }
        if (widget.items[position + 1].isHeader) {
          //如果下一个是header,又刚刚滚定到临界点,那么group往下一个
          if (tempLength == pixels) {
            headerStr?.isSelect = false;
            headerStr = widget.items[position + 1] as T?;
            headerStr?.isSelect = true;
          }
          if (mounted) {
            setState(() {
              offset = currentHeight - (tempLength - pixels);
              if (offset - (widget.itemHeight - widget.itemHeadHeight) >= 0) {
                headerOffset =
                    -(offset - (widget.itemHeight - widget.itemHeadHeight));
              }
            });
          }
        } else {
          if (headerOffset != 0) {
            if (mounted) {
              setState(() {
                headerOffset = 0.0;
              });
            }
          }
        }
        // if (!selected) {
        resetGroupPosition();
        // }
      };
      headerStr?.isSelect = true;
      if (callback != null) {
        scrollController?.addListener(callback!);
      }
    }
  }

  resetGroupPosition() {
    int index = 0;
    if (!selected) {
      for (var i = 0; i < widget.groups.length; i++) {
        if (headerStr == widget.groups[i]) {
          index = i;
        }
      }
    } else {
      index = selectIndex;
    }

    double currentLength = widget.itemGroupHeight * (index + 1);
    double offset = 0;

    if (currentLength > containerSize.height / 2 &&
        widget.groups.length * widget.itemGroupHeight > containerSize.height) {
      offset = ((currentLength - containerSize.height / 2) /
              widget.itemGroupHeight.round()) *
          widget.itemGroupHeight;
      if (offset + containerSize.height >
          widget.groups.length * widget.itemGroupHeight) {
        offset = widget.groups.length * widget.itemGroupHeight -
            containerSize.height;
      }
      groupScrollController!.animateTo(offset,
          duration: Duration(milliseconds: widget.duration),
          curve: Curves.linear);
    }

    // if ((currentLength - (widget.itemGroupHeight / 2)) >= containerSize.height / 2 &&
    //     widget.groups.length * widget.itemGroupHeight > containerSize.height) {
    //   // offset = (currentLength - (widget.itemGroupHeight / 2)) - containerSize.height / 2;
    //   if (offset + containerSize.height > widget.groups.length * widget.itemGroupHeight) {
    //     offset = widget.groups.length * widget.itemGroupHeight - containerSize.height;
    //   }

    //   groupScrollController.animateTo(offset, duration: Duration(milliseconds: widget.duration), curve: Curves.ease);
    // }
    if (currentLength <= containerSize.height / 2 &&
        offset < widget.itemGroupHeight) {
      offset = 0;
      groupScrollController!.animateTo(offset,
          duration: Duration(milliseconds: widget.duration),
          curve: Curves.linear);
    }
    if (kDebugMode) {
      print(
          "currentLength is $currentLength offset is $offset   ${(currentLength - (widget.itemGroupHeight / 2))} ${containerSize.height / 2}");
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance?.addPostFrameCallback(_onBuildCompleted);

    return Container(
      color: Colors.transparent,
      width: double.infinity,
      height: double.infinity,
      child: Row(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              key: _containerKey,
              padding: const EdgeInsets.all(0),
              controller: groupScrollController,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.groups.length,
              itemBuilder: (BuildContext context, int index) {
                return groupItem(context, index);
              },
              // separatorBuilder: (context, index) {
              //   return Divider(
              //     height: .5,
              //     indent: 0,
              //     color: Color(0xFFDDDDDD),
              //   );
              // },
            ),
            flex: widget.flexLeft,
          ),
          Expanded(
            child: Stack(children: [
              ListView.builder(
                padding: const EdgeInsets.all(0),
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.items.length,
                itemBuilder: (BuildContext context, int index) {
                  return generalItem(context, index);
                },
                // separatorBuilder: (context, index) {
                //   return Divider(
                //     height: .1,
                //     indent: 0,
                //     color: Color(0xFFDDDDDD),
                //   );
                // },
              ),
              Visibility(
                visible: widget.isNeedStick ? showTopHeader : false,
                child: Container(
                  transform: Matrix4.translationValues(0.0, headerOffset, 0.0),
                  width: double.infinity,
                  height: widget.itemHeadHeight,
                  child: widget.headerBuilder!(context, headerStr!),
                ),
              )
            ]),
            flex: widget.flexRight,
          ),
        ],
      ),
    );
  }
}
