import 'package:flutter/material.dart';
import 'package:fuodz/widgets/dynamic_status_bar.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:fuodz/utils/utils.dart';

import 'package:velocity_x/velocity_x.dart';

class BasePage extends StatefulWidget {
  final bool showAppBar;
  final bool showLeadingAction;
  final bool showCart;
  final Function? onBackPressed;
  final String? title;
  final Widget body;
  final Widget? bottomSheet;
  final Widget? fab;
  final bool isLoading;
  final bool extendBodyBehindAppBar;
  final double? elevation;
  final Color? appBarItemColor;
  final Color? backgroundColor;
  final Color? appBarColor;
  final Widget? leading;
  final Widget? bottomNavigationBar;
  final List<Widget>? actions;

  BasePage({
    this.showAppBar = false,
    this.showLeadingAction = false,
    this.leading,
    this.showCart = false,
    this.onBackPressed,
    this.title = "",
    required this.body,
    this.bottomSheet,
    this.fab,
    this.isLoading = false,
    this.appBarColor,
    this.elevation,
    this.extendBodyBehindAppBar = false,
    this.appBarItemColor,
    this.backgroundColor,
    this.bottomNavigationBar,
    this.actions,
    Key? key,
  }) : super(key: key);

  @override
  _BasePageState createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  @override
  Widget build(BuildContext context) {
    Color textColor = Utils.textColorByColor(
      widget.appBarColor ?? context.primaryColor,
    );
    //
    return DynamicStatusBar(
      baseColor: widget.backgroundColor ?? context.backgroundColor,
      child: Directionality(
        textDirection: Utils.textDirection,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: widget.backgroundColor ?? context.backgroundColor,
          extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
          appBar:
              widget.showAppBar
                  ? AppBar(
                    backgroundColor: widget.appBarColor ?? context.primaryColor,
                    automaticallyImplyLeading: widget.showLeadingAction,
                    elevation: widget.elevation,
                    leading:
                        widget.showLeadingAction
                            ? widget.leading == null
                                ? IconButton(
                                  icon: HugeIcon(
                                    icon:
                                        !Utils.isArabic
                                            ? HugeIcons.strokeRoundedArrowLeft01
                                            : HugeIcons
                                                .strokeRoundedArrowRight01,
                                    color: textColor,
                                  ),
                                  onPressed:
                                      (widget.onBackPressed != null)
                                          ? () => widget.onBackPressed!()
                                          : () => Navigator.pop(context),
                                )
                                : widget.leading
                            : null,
                    title: Text(
                      "${widget.title}",
                      style: context.titleLarge!.copyWith(color: textColor),
                    ),
                    actions: widget.actions,
                  )
                  : null,
          body:
              VStack([
                //
                if (widget.isLoading) LinearProgressIndicator(),

                //
                widget.body.expand(),
              ]).safeArea(),
          bottomSheet: widget.bottomSheet,
          floatingActionButton: widget.fab,
          // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: widget.bottomNavigationBar,
        ),
      ),
    );
  }
}
