import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/**
 * @Author SuK
 * @Des
 * @Date 2022/12/5
 */
class PopupWindowRoute extends PopupRoute {
  final PopupWindow Function(BuildContext context) builder;

  PopupWindowRoute(this.builder);

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return builder.call(context);
  }

  @override
  Duration get transitionDuration => const Duration(microseconds: 0);
}

class PopupWindow extends StatelessWidget {
  final Widget child;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final AlignmentGeometry? alignment;

  const PopupWindow(this.child,
      {Key? key, this.alignment, this.left, this.top, this.right, this.bottom})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final positioned = Positioned(
      child: child,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );

    final children = [
      Opacity(
        opacity: 1,
       child: Container(color: Colors.black54,),
      ),
      Positioned(
        child: child,
        left: left,
        top: top,
        right: right,
        bottom: bottom,
      )
    ];

    final alignment = this.alignment;

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
        },
        child: Container(
          color: Colors.transparent,
          child: alignment != null
              ? Stack(
                  alignment: alignment,
                  children: children,
                )
              : Stack(children: children),
        ),
      ),
    );
  }
}
