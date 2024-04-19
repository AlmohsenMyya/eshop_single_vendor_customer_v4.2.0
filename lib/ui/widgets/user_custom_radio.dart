import 'package:eshop/Model/User.dart';

import 'package:flutter/material.dart';

import '../../Helper/Color.dart';
import '../../Helper/Session.dart';

class RadioItem extends StatelessWidget {
  final RadioModel _item;

  const RadioItem(this._item, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: <Widget>[
              _item.show
                  ? Container(
                      height: 20.0,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _item.isSelected!
                              ? colors.primary
                              : Theme.of(context).colorScheme.white,
                          border: Border.all(color: colors.primary)),
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: _item.isSelected!
                            ? Icon(
                                Icons.check,
                                size: 15.0,
                                color: Theme.of(context).colorScheme.white,
                              )
                            : Icon(
                                Icons.circle,
                                size: 15.0,
                                color: Theme.of(context).colorScheme.white,
                              ),
                      ),
                    )
                  : const SizedBox.shrink(),
              Expanded(
                child: Container(
                  margin: const EdgeInsetsDirectional.only(start: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _item.name!,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              maxLines: 1,
                            ),
                          ),
                          InkWell(
                            child: Text(
                              getTranslated(context, 'EDIT')!,
                              style: const TextStyle(
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                              _item.onEditSelected!();
                            },
                          ),
                        ],
                      ),
                      Text(_item.add!),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () {
                                _item.onSetDefault!();
                              },
                              child: Container(
                                height: 20.0,
                                width: 20.0,
                                decoration: BoxDecoration(
                                    shape: BoxShape.rectangle,
                                    color: _item.addItem!.isDefault == "1"
                                        ? colors.primary
                                        : Theme.of(context).colorScheme.white,
                                    border: Border.all(color: colors.primary)),
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: _item.addItem!.isDefault == "1"
                                      ? Icon(
                                          Icons.check,
                                          size: 15.0,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .white,
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding:
                                    const EdgeInsetsDirectional.only(start: 20),
                                child: InkWell(
                                  onTap: () {
                                    if (_item.addItem!.isDefault == "0") {
                                      _item.onSetDefault!();
                                    }
                                  },
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(4.0))),
                                    child: _item.addItem!.isDefault == "0"
                                        ? Text(
                                            getTranslated(
                                                context, 'SET_DEFAULT')!,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor,
                                            ),
                                          )
                                        : Text(
                                            getTranslated(
                                                context, 'MARKED_DEFAULT')!,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding:
                                    const EdgeInsetsDirectional.only(start: 20),
                                child: InkWell(
                                  onTap: () {
                                    _item.onDeleteSelected!();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      border: Border.all(
                                        color: colors.primary,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: Text(
                                      getTranslated(context, 'DELETE')!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor,
                                          fontSize: 10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class RadioModel {
  bool? isSelected;
  final String? add;
  final String? name;
  final User? addItem;
  final VoidCallback? onEditSelected;
  final VoidCallback? onDeleteSelected;
  final VoidCallback? onSetDefault;
  final show;

  RadioModel({
    this.isSelected,
    this.name,
    this.add,
    this.addItem,
    this.onEditSelected,
    this.onSetDefault,
    this.show,
    this.onDeleteSelected,
  });
}
