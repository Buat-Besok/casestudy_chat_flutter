import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:bluebubbles/helpers/utils.dart';
import 'package:bluebubbles/managers/settings_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';
import 'dart:io';

class TitleBarWrapper extends StatelessWidget {
  TitleBarWrapper({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Obx(() => (SettingsManager().settings.useCustomTitleBar.value && !kIsWeb && Platform.isLinux) || (kIsDesktop && !Platform.isLinux)
        ? WindowBorder(
            color: Colors.transparent,
            width: 0,
            child: Stack(children: <Widget>[child, TitleBar()]),
          )
        : child);
  }
}

class TitleBar extends StatelessWidget {
  const TitleBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WindowTitleBarBox(
      child: Row(
        children: [
          Expanded(
            child: MoveWindow(),
          ),
          const WindowButtons()
        ],
      ),
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WindowButtonColors buttonColors = WindowButtonColors(
        iconNormal: context.theme.primaryColor,
        mouseOver: context.theme.primaryColor,
        mouseDown: context.theme.primaryColorDark,
        iconMouseOver: context.theme.colorScheme.secondary,
        iconMouseDown: context.theme.primaryColorLight);

    WindowButtonColors closeButtonColors = WindowButtonColors(
        mouseOver: Color(0xFFD32F2F),
        mouseDown: Color(0xFFB71C1C),
        iconNormal: context.theme.primaryColor,
        iconMouseOver: Colors.white);
    return Row(
      children: [
        MinimizeWindowButton(
          colors: buttonColors,
          onPressed: () => SettingsManager().settings.minimizeToTray.value ? appWindow.hide() : appWindow.minimize(),
        ),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(
            colors: closeButtonColors,
            onPressed: () => SettingsManager().settings.closeToTray.value ? appWindow.hide() : appWindow.close()),
      ],
    );
  }
}
