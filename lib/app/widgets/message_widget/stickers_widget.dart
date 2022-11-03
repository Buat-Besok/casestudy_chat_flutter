import 'dart:async';
import 'dart:isolate';

import 'package:bluebubbles/models/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:universal_io/io.dart';

class StickersWidget extends StatefulWidget {
  StickersWidget({Key? key, required this.messages, required this.size}) : super(key: key);
  final List<Message> messages;
  final Size size;

  @override
  State<StickersWidget> createState() => _StickersWidgetState();
}

class _StickersWidgetState extends State<StickersWidget> with AutomaticKeepAliveClientMixin {
  bool _visible = true;
  late final controller = cm.activeChat == null ? null : cvc(cm.activeChat!.chat);

  @override
  void initState() {
    super.initState();
    loadStickers();
  }

  void toggleShow() {
    if (!mounted) return;
    setState(() {
      _visible = !_visible;
    });
  }

  Future<void> loadStickers() async {
    if (cm.activeChat == null) return;
    // For each message, load the sticker for it
    for (Message msg in widget.messages) {
      // If the message type isn't a sticker, skip it
      if (msg.associatedMessageType != "sticker") continue;

      // Get the associated attachments
      if (msg.attachments.isEmpty) {
        msg.attachments = msg.fetchAttachments() ?? [];
      }
      for (Attachment? attachment in msg.attachments) {
        // If we've already loaded it, don't try again
        if (controller?.stickerData.keys.contains(attachment!.guid) ?? false) continue;

        String pathName = attachment!.path;

        final receivePort = ReceivePort();

        // Check if the attachment exists
        if (await FileSystemEntity.type(pathName) == FileSystemEntityType.notFound) {
          // Download the attachment and when complete, re-render the UI
          attachmentDownloader.startDownload(attachment, onComplete: (_) async {
            // Make sure it downloaded correctly
            if (await FileSystemEntity.type(pathName) != FileSystemEntityType.notFound) {
              // Check via the image package to make sure this is a valid, render-able image
              await Isolate.spawn(
                  decodeIsolate, IsolateData(File(pathName), receivePort.sendPort));
              // Get the processed image from the isolate.
              final image = await receivePort.first as img.Image?;

              if (image != null) {
                final bytes = await File(pathName).readAsBytes();
                controller?.stickerData[msg.guid!] = {
                  attachment.guid!: bytes
                };
              }
              if (mounted) setState(() {});
            }
          });
        } else {
          // Check via the image package to make sure this is a valid, render-able image
          await Isolate.spawn(
              decodeIsolate, IsolateData(File(pathName), receivePort.sendPort));
          // Get the processed image from the isolate.
          final image = await receivePort.first as img.Image?;

          if (image != null) {
            final bytes = await File(pathName).readAsBytes();
            controller?.stickerData[msg.guid!] = {
              attachment.guid!: bytes
            };
          }
        }
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final guids = widget.messages.map((e) => e.guid!);
    final stickers = controller?.stickerData.entries.where((element) => guids.contains(element.key)).map((e) => e.value) ?? [];

    if (stickers.isEmpty) return Container();

    final data = stickers.map((e) => e.values).expand((element) => element);

    List<double> leftVec = [];
    data.forEachIndexed((index, item) {
      leftVec.add(widget.size.width / data.length * index);
    });
    double middle = 0;
    if (leftVec.length <= 1) {
      middle = 0;
    } else if (leftVec.length.isEven) {
      middle = (leftVec[(leftVec.length / 2 - 1).toInt()] + leftVec[leftVec.length ~/ 2]) / 2;
    } else {
      middle = leftVec[(leftVec.length / 2 - 0.5).toInt()];
    }

    leftVec = leftVec.map((e) => e - middle).toList();

    // Turn the attachments into Image Widgets
    List<Widget> stickerWidgets = data.mapIndexed((index, item) {
      return Positioned(
        left: leftVec[index] + widget.size.height / 2,
        bottom: -15,
        height: widget.size.height + 20,
        child: Image.memory(
          item,
          height: widget.size.height + 20,
          gaplessPlayback: true,
        ),
      );
    }).toList();

    return GestureDetector(
        onTap: toggleShow,
        child: Opacity(
            key: Key(stickers.first.keys.first),
            opacity: _visible ? 1.0 : 0.25,
            child: Container(
              width: widget.size.width,
              height: widget.size.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: stickerWidgets,
                alignment: Alignment.centerLeft
              ),
            )
        )
    );
  }

  @override
  bool get wantKeepAlive => true;
}

void decodeIsolate(IsolateData param) {
  try {
    var image = img.decodeImage(param.file.readAsBytesSync())!;
    param.sendPort.send(image);
  } catch (_) {
    param.sendPort.send(null);
  }
}

class IsolateData {
  final File file;
  final SendPort sendPort;
  IsolateData(this.file, this.sendPort);
}
