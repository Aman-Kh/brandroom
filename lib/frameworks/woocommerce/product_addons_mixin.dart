import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../common/config.dart';
import '../../common/constants.dart';
import '../../common/tools.dart';
import '../../generated/l10n.dart' show S;
import '../../models/index.dart'
    show AddonsOption, AppModel, Product, ProductAddons, UserModel;
import '../../modules/dynamic_layout/helper/helper.dart';
import '../../services/index.dart';

mixin ProductAddonsMixin {
  bool get mediaTypeAllowed =>
      (kProductAddons['allowImageType'] ?? true) ||
      (kProductAddons['allowVideoType'] ?? true);

  bool isUploading = false;

  bool get customTypeAllowed => (kProductAddons['allowCustomType'] ?? false);

  FileType get allowedCustomFileType {
    final allowedTypes = kProductAddons['allowedCustomType'];
    if ((kProductAddons['allowCustomType'] ?? false) &&
        (allowedTypes is List && allowedTypes.isNotEmpty)) {
      return FileType.custom;
    }
    if ((kProductAddons['allowCustomType'] ?? false) &&
        (allowedTypes == null ||
            (allowedTypes is List && allowedTypes.isEmpty))) {
      return FileType.any;
    }
    throw Exception('No file type is supported!');
  }

  FileType get allowedMediaFileType {
    if ((kProductAddons['allowImageType'] ?? true) &&
        (kProductAddons['allowVideoType'] ?? true)) {
      return FileType.media;
    }
    if ((kProductAddons['allowImageType'] ?? true) &&
        !(kProductAddons['allowVideoType'] ?? true)) {
      return FileType.image;
    }
    if (!(kProductAddons['allowImageType'] ?? true) &&
        (kProductAddons['allowVideoType'] ?? true)) {
      return FileType.video;
    }
    throw Exception('No file type is supported!');
  }

  Future<void> getProductAddons({
    required BuildContext context,
    required Product product,
    required Function(
            {Product? productInfo,
            required Map<String, Map<String, AddonsOption>> selectedOptions})
        onLoad,
    required Map<String, Map<String, AddonsOption>> selectedOptions,
  }) async {
    final lang = Provider.of<AppModel>(context, listen: false).langCode;
    await Services()
        .api
        .getProduct(product.id, lang: lang)!
        .then((onValue) async {
      if (onValue?.addOns?.isNotEmpty ?? false) {
        /// Select default options.
        selectedOptions.addAll(onValue!.defaultAddonsOptions);

        onLoad(productInfo: onValue, selectedOptions: selectedOptions);
      }
    });
  }

  List<Widget> getProductAddonsWidget({
    required BuildContext context,
    String? lang,
    required Product product,
    required Map<String, Map<String, AddonsOption>> selectedOptions,
    Function? onSelectProductAddons,
    int quantity = 1,
  }) {
    final model = Provider.of<AppModel>(context);
    final rates = model.currencyRate;
    final currency = model.currency;
    final listWidget = <Widget>[];
    if (product.addOns?.isNotEmpty ?? false) {
      listWidget.add(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColorLight.withOpacity(0.7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  S.of(context).options.toUpperCase(),
                  style: Theme.of(context)
                      .textTheme
                      .subtitle2!
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  S.of(context).total,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                PriceTools.getCurrencyFormatted(
                    product.getProductOptionsPrice(quantity), rates)!,
                style: Theme.of(context).textTheme.headline6,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      );
      listWidget.add(Column(
        children: product.addOns!.map<Widget>((ProductAddons item) {
          final selected = (selectedOptions[item.name!] ?? {});
          if (item.isHeadingType) {
            return Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColorLight.withOpacity(0.7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name!,
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }

          return ExpansionTile(
            trailing: const Icon(CupertinoIcons.plus_circle_fill, size: 25),
            title: ListTile(
              visualDensity: VisualDensity.compact,
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            item.name!,
                            style:
                                Theme.of(context).textTheme.subtitle1!.copyWith(
                                      color: selected.isNotEmpty
                                          ? null
                                          : Theme.of(context)
                                              .colorScheme
                                              .secondary
                                              .withOpacity(0.7),
                                    ),
                          ),
                        ),
                        if (item.isTextType)
                          Text(
                            ' (${PriceTools.getCurrencyFormatted(item.price, rates)})',
                            style:
                                Theme.of(context).textTheme.subtitle1?.copyWith(
                                      color: selected.isNotEmpty
                                          ? null
                                          : Theme.of(context)
                                              .colorScheme
                                              .secondary
                                              .withOpacity(0.7),
                                      fontSize: 13,
                                    ),
                          ),
                      ],
                    ),
                  ),
                  if (item.isRadioButtonType && item.required!)
                    Text(
                      S.of(context).mustSelectOneItem,
                      style: TextStyle(
                        fontSize: 10,
                        color: selected.isNotEmpty
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.7),
                      ),
                    ),
                ],
              ),
              subtitle: selected.isNotEmpty
                  ? Text(
                      _getSelectedOptionsTitle(context, item, selected),
                      style: Theme.of(context).textTheme.caption!.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                    )
                  : null,
              contentPadding: EdgeInsets.zero,
            ),
            children: [
              Wrap(
                children: [
                  if (item.isRadioButtonType && !item.required!)
                    Container(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width * 0.45,
                      ),
                      child: InkWell(
                        onTap: () {
                          selected.clear();
                          onSelectProductAddons!(
                              selectedOptions: selectedOptions);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IgnorePointer(
                              child: Radio(
                                visualDensity: VisualDensity.compact,
                                groupValue: selected.keys.isNotEmpty
                                    ? selected.keys.first
                                    : null,
                                value: null,
                                onChanged: (dynamic _) {},
                                activeColor: Theme.of(context).primaryColor,
                              ),
                            ),
                            Text(
                              S.of(context).none,
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                    fontWeight: selected.isEmpty
                                        ? FontWeight.bold
                                        : null,
                                  ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ...List.generate(
                    item.isCustomPriceType ? 1 : item.options!.length,
                    (index) {
                      if (item.isCustomPriceType) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: TextField(
                              onChanged: (text) {
                                if (text.isEmpty) {
                                  selected.remove(item.name);
                                  onSelectProductAddons!(
                                      selectedOptions: selectedOptions);
                                  return;
                                }

                                text = text.replaceAll(',', '');
                                final price = double.tryParse(text);
                                if (price == null) {
                                  return;
                                }

                                final formattedPrice =
                                    PriceTools.getCurrencyFormatted(
                                            price, rates,
                                            currency: currency) ??
                                        text;

                                if (selected[item.name] != null) {
                                  selected[item.name]!.label = formattedPrice;
                                  selected[item.name]!.price =
                                      '${Helper.formatDouble(text) ?? 0.0}';
                                } else {
                                  selected[item.name!] = AddonsOption(
                                      parent: item.name,
                                      type: item.type,
                                      label: formattedPrice,
                                      price:
                                          '${Helper.formatDouble(text) ?? 0.0}',
                                      display: item.display,
                                      fieldName: item.fieldName);
                                }
                                onSelectProductAddons!(
                                    selectedOptions: selectedOptions);
                              },
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                signed: false,
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.all(8),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                hintText: PriceTools.getCurrencyFormatted(
                                  0,
                                  null,
                                  currency: currency,
                                ),
                              ),
                              minLines: 1,
                              maxLines: 1,
                            ),
                          ),
                        );
                      }
                      final option = item.options![index];
                      final isSelected = selected[option.label] != null;
                      void onTap() {
                        if (item.isRadioButtonType) {
                          selected.clear();
                          selected[option.label!] = option;
                          onSelectProductAddons!(
                              selectedOptions: selectedOptions);
                          return;
                        }
                        if (item.isCheckboxType) {
                          if (isSelected) {
                            selected.remove(option.label);
                          } else {
                            selected[option.label!] = option;
                          }
                          onSelectProductAddons!(
                              selectedOptions: selectedOptions);
                          return;
                        }
                      }

                      return Container(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width * 0.45,
                        ),
                        child: item.isFileUploadType
                            ? Padding(
                                padding: const EdgeInsets.only(
                                  left: 8.0,
                                  right: 8.0,
                                  bottom: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: StatefulBuilder(builder:
                                          (context, StateSetter setState) {
                                        return TextButton.icon(
                                          onPressed: isUploading
                                              ? null
                                              : () => _showOption(context,
                                                      onFileUploadStart: () {
                                                    isUploading = true;
                                                    setState(() {});
                                                  }, onFileUploadFailed: () {
                                                    isUploading = false;
                                                    setState(() {});
                                                  }, onFileUploaded:
                                                          (List<String?>
                                                              fileUrls) {
                                                    isUploading = false;
                                                    setState(() {});
                                                    for (var url in fileUrls) {
                                                      /// Overwrite previous file if multiple files not allowed.
                                                      var key = kProductDetail
                                                              .allowMultiple
                                                          ? url!.split('/').last
                                                          : item.name;
                                                      selected[key!] =
                                                          AddonsOption(
                                                              parent: item.name,
                                                              label: url,
                                                              type: item.type,
                                                              display:
                                                                  item.display,
                                                              fieldName: item
                                                                  .fieldName);
                                                      onSelectProductAddons!(
                                                          selectedOptions:
                                                              selectedOptions);
                                                    }
                                                  }),
                                          icon: isUploading
                                              ? SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2.0,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Theme.of(context)
                                                                .primaryColor),
                                                  ),
                                                )
                                              : const Icon(
                                                  CupertinoIcons.doc_text,
                                                ),
                                          label: Text(
                                            (isUploading
                                                    ? S.of(context).uploading
                                                    : S.of(context).uploadFile)
                                                .toUpperCase(),
                                          ),
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              )
                            : InkWell(
                                onTap: onTap,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (item.isRadioButtonType)
                                      Radio(
                                        visualDensity: VisualDensity.compact,
                                        groupValue: selected.keys.isNotEmpty
                                            ? selected.keys.first
                                            : '',
                                        value: option.label,
                                        onChanged: (dynamic _) => onTap(),
                                        activeColor:
                                            Theme.of(context).primaryColor,
                                      ),
                                    if (item.isCheckboxType)
                                      Checkbox(
                                        visualDensity: VisualDensity.compact,
                                        onChanged: (_) => onTap(),
                                        activeColor:
                                            Theme.of(context).primaryColor,
                                        checkColor: Colors.white,
                                        value: isSelected,
                                      ),
                                    if (item.isTextType)
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child: TextField(
                                            onChanged: (text) {
                                              if (text.isEmpty) {
                                                selected.remove(item.name);
                                                onSelectProductAddons!(
                                                    selectedOptions:
                                                        selectedOptions);
                                                return;
                                              }

                                              if (selected[item.name] != null) {
                                                selected[item.name]!.label =
                                                    text;
                                              } else {
                                                selected[item.name!] =
                                                    AddonsOption(
                                                        parent: item.name,
                                                        type: item.type,
                                                        label: text,
                                                        price: item.price,
                                                        display: item.display,
                                                        fieldName:
                                                            item.fieldName);
                                              }
                                              onSelectProductAddons!(
                                                  selectedOptions:
                                                      selectedOptions);
                                            },
                                            decoration: InputDecoration(
                                              contentPadding:
                                                  const EdgeInsets.all(8),
                                              border: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .secondary),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              labelText: option.label,
                                            ),
                                            minLines: 1,
                                            maxLines:
                                                item.isShortTextType ? 1 : 4,
                                          ),
                                        ),
                                      ),
                                    if (!item.isTextType)
                                      Text(
                                        option.label!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle1!
                                            .copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : null,
                                            ),
                                      ),
                                    if (!item.isTextType && !item.isHeadingType)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4.0),
                                        child: Text(
                                          '(${PriceTools.getCurrencyFormatted(option.price, rates)})',
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : null,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                      );
                    },
                  )
                ],
              )
            ],
          );
        }).toList(),
      ));
    }
    return listWidget;
  }

  void _showOption(BuildContext context,
      {VoidCallback? onFileUploadStart,
      Function(List<String?> fileUrl)? onFileUploaded,
      VoidCallback? onFileUploadFailed}) {
    showModalBottomSheet(
      context: context,
      builder: (modalContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                children: <Widget>[
                  if (mediaTypeAllowed)
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(modalContext);
                        selectFile(
                          context,
                          allowedMediaFileType,
                          onFileSelected: onFileUploaded,
                          onFileUploadStart: onFileUploadStart,
                          onFileUploadFailed: onFileUploadFailed,
                        );
                      },
                      child: _UploadTypeIcon(
                        icon: CupertinoIcons.arrow_up_circle,
                        text: S.of(context).gallery,
                      ),
                    ),
                  const SizedBox(width: 20),
                  if (customTypeAllowed)
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(modalContext);
                        selectFile(
                          context,
                          allowedCustomFileType,
                          onFileSelected: onFileUploaded,
                          onFileUploadStart: onFileUploadStart,
                          onFileUploadFailed: onFileUploadFailed,
                        );
                      },
                      child: _UploadTypeIcon(
                        icon: CupertinoIcons.doc,
                        text: S.of(context).files,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  S
                      .of(context)
                      .maximumFileSizeMb(kProductAddons['fileUploadSizeLimit']),
                  style: Theme.of(context).textTheme.caption,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> selectFile(BuildContext context, FileType fileType,
      {VoidCallback? onFileUploadStart,
      Function(List<String?> fileUrls)? onFileSelected,
      VoidCallback? onFileUploadFailed}) async {
    final userModel = Provider.of<UserModel>(context, listen: false);

    if (userModel.user?.cookie == null) {
      await showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              content: Text(S.of(context).pleaseSignInBeforeUploading),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(S.of(context).cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(
                      App.fluxStoreNavigatorKey.currentContext!,
                    ).pushNamed(RouteList.login);
                  },
                  child: Text(
                    S.of(context).signIn,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          });
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: (kProductAddons['allowMultiple'] ?? false),
      type: fileType,
      allowedExtensions: fileType == FileType.custom
          ? kProductAddons['allowedCustomType']
          : null,
    );
    if (result?.files.isEmpty ?? true) {
      /// Cancel select file.
      Tools.showSnackBar(
        ScaffoldMessenger.of(context),
        S.of(context).selectFileCancelled,
      );
      return;
    }

    /// Check file size limit.
    final double? fileSizeLimit =
        kProductAddons['fileUploadSizeLimit'] is double
            ? kProductAddons['fileUploadSizeLimit']
            : double.tryParse('${kProductAddons['fileUploadSizeLimit']}');
    if (fileSizeLimit != null && fileSizeLimit > 0.0) {
      for (var file in result!.files) {
        if (file.size.toDouble() > (fileSizeLimit * 1000000)) {
          Tools.showSnackBar(
            ScaffoldMessenger.of(context),
            S.of(context).fileIsTooBig,
          );
          return;
        }
      }
    }

    onFileUploadStart!();

    try {
      final urls = <String?>[];
      for (var file in result!.files) {
        await Services().api.uploadImage({
          'title': {'rendered': path.basename(file.path.toString())},
          'media_attachment': base64.encode(file.bytes!),
          'media_path': 'product_addons_uploads',
        }, userModel.user != null ? userModel.user!.cookie : null)!.then(
            (photo) {
          urls.add(photo['guid']['rendered']);
        });
      }
      onFileSelected!(urls);
    } catch (err, trace) {
      printLog(err);
      printLog(trace);
      onFileUploadFailed!();

      try {
        Tools.showSnackBar(
          ScaffoldMessenger.of(context),
          S.of(context).fileUploadFailed,
        );
      } catch (_) {}
    }
  }

  String _getSelectedOptionsTitle(BuildContext context, ProductAddons item,
      Map<String, AddonsOption> selected) {
    if (item.isTextType || item.isCustomPriceType) {
      return selected[item.name]?.label ?? '';
    }
    if (item.isFileUploadType &&
        selected.isNotEmpty &&
        !(kProductAddons['allowMultiple'] ?? false)) {
      return selected.values.first.label!.split('/').last;
    }
    return selected.keys.join(', ');
  }
}

class _UploadTypeIcon extends StatelessWidget {
  final IconData? icon;
  final String? text;

  const _UploadTypeIcon({Key? key, this.icon, this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        if (icon != null)
          Icon(
            icon,
            size: 50,
            color: Theme.of(context).primaryColor,
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            text ?? '',
            style: Theme.of(context).textTheme.subtitle2!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
        ),
      ],
    );
  }
}
