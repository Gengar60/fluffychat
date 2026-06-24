// SPDX-FileCopyrightText: 2019-Present Christian Kußowski
// SPDX-FileCopyrightText: 2019-Present Contributors to FluffyChat
//
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:typed_data';

import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_text_input_dialog.dart';
import 'package:flutter/material.dart';
import 'package:pasteboard/pasteboard.dart';

class MarkdownContextBuilder extends StatefulWidget {
  final EditableTextState editableTextState;
  final TextEditingController controller;
  final ValueChanged<Uint8List?>? onPasteImage;

  const MarkdownContextBuilder({
    required this.editableTextState,
    required this.controller,
    this.onPasteImage,
    super.key,
  });

  @override
  State<MarkdownContextBuilder> createState() => _MarkdownContextBuilderState();
}

class _MarkdownContextBuilderState extends State<MarkdownContextBuilder> {
  bool _hasImageInClipboard = false;

  @override
  void initState() {
    super.initState();
    if (widget.onPasteImage != null) {
      Pasteboard.image.then((image) {
        if (mounted) {
          setState(() => _hasImageInClipboard = image != null);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.editableTextState.textEditingValue;
    final selectedText = value.selection.textInside(value.text);
    final buttonItems = widget.editableTextState.contextMenuButtonItems;
    final pasteImageButton = _hasImageInClipboard && widget.onPasteImage != null
        ? ContextMenuButtonItem(
            label: 'Paste Image',
            onPressed: () {
              Pasteboard.image.then((image) {
                if (image != null) {
                  widget.onPasteImage?.call(image);
                  ContextMenuController.removeAny();
                }
              });
            },
          )
        : null;
    final l10n = L10n.of(context);

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: widget.editableTextState.contextMenuAnchors,
      buttonItems: [
        ...buttonItems,
        if (pasteImageButton != null) pasteImageButton,
        if (selectedText.isNotEmpty) ...[
          ContextMenuButtonItem(
            label: l10n.link,
            onPressed: () async {
              final input = await showTextInputDialog(
                context: context,
                title: l10n.addLink,
                okLabel: l10n.ok,
                cancelLabel: l10n.cancel,
                validator: (text) {
                  if (text.isEmpty) {
                    return l10n.pleaseFillOut;
                  }
                  try {
                    text.startsWith('http') ? Uri.parse(text) : Uri.https(text);
                  } catch (_) {
                    return l10n.invalidUrl;
                  }
                  return null;
                },
                hintText: 'www...',
                keyboardType: TextInputType.url,
              );
              final urlString = input;
              if (urlString == null) return;
              final url = urlString.startsWith('http')
                  ? Uri.parse(urlString)
                  : Uri.https(urlString);
              final selection = widget.controller.selection;
              widget.controller.text = widget.controller.text.replaceRange(
                selection.start,
                selection.end,
                '[$selectedText]($url)',
              );
              ContextMenuController.removeAny();
            },
          ),
          ContextMenuButtonItem(
            label: l10n.checkList,
            onPressed: () {
              final text = widget.controller.text;
              final selection = widget.controller.selection;

              var start = selection.textBefore(text).lastIndexOf('\n');
              if (start == -1) start = 0;
              final end = selection.end;

              final fullLineSelection = TextSelection(
                baseOffset: start,
                extentOffset: end,
              );

              const checkBox = '- [ ]';

              final replacedRange = fullLineSelection
                  .textInside(text)
                  .split('\n')
                  .map(
                    (line) => line.startsWith(checkBox) || line.isEmpty
                        ? line
                        : '$checkBox $line',
                  )
                  .join('\n');
              widget.controller.text = widget.controller.text.replaceRange(
                start,
                end,
                replacedRange,
              );
              ContextMenuController.removeAny();
            },
          ),
          ContextMenuButtonItem(
            label: l10n.boldText,
            onPressed: () {
              final selection = widget.controller.selection;
              widget.controller.text = widget.controller.text.replaceRange(
                selection.start,
                selection.end,
                '**$selectedText**',
              );
              ContextMenuController.removeAny();
            },
          ),
          ContextMenuButtonItem(
            label: l10n.italicText,
            onPressed: () {
              final selection = widget.controller.selection;
              widget.controller.text = widget.controller.text.replaceRange(
                selection.start,
                selection.end,
                '*$selectedText*',
              );
              ContextMenuController.removeAny();
            },
          ),
          ContextMenuButtonItem(
            label: l10n.strikeThrough,
            onPressed: () {
              final selection = widget.controller.selection;
              widget.controller.text = widget.controller.text.replaceRange(
                selection.start,
                selection.end,
                '~~$selectedText~~',
              );
              ContextMenuController.removeAny();
            },
          ),
        ],
      ],
    );
  }
}
