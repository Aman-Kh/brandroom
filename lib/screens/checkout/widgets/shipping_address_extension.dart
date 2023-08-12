part of 'shipping_address.dart';

extension on _ShippingAddressState {
  void updateAddress(Address? newAddress) {
    address = newAddress;
    loadUserInfoFromAddress(newAddress);
    loadAddressFields(address);
  }

  void loadUserInfoFromAddress(Address? address) {
    _textControllers[AddressFieldType.firstName]?.text =
        address?.firstName ?? '';
    _textControllers[AddressFieldType.lastName]?.text = address?.lastName ?? '';
    _textControllers[AddressFieldType.phoneNumber]?.text =
        address?.phoneNumber ?? '';
    _textControllers[AddressFieldType.email]?.text = address?.email ?? '';
  }

  void loadAddressFields(Address? address) {
    _textControllers[AddressFieldType.country]?.text = address?.country ?? '';
    _textControllers[AddressFieldType.state]?.text = address?.state ?? '';
    _textControllers[AddressFieldType.apartment]?.text =
        address?.apartment ?? '';
    _textControllers[AddressFieldType.street]?.text = address?.street ?? '';
    refresh();
  }

  bool checkToSave() {
    final storage = LocalStorage(LocalStorageKey.address);
    var listAddress = <Address>[];
    try {
      var data = storage.getItem('data');
      if (data != null) {
        for (var item in (data as List)) {
          final add = Address.fromLocalJson(item);
          listAddress.add(add);
        }
      }
      for (var local in listAddress) {
        final isNotExistedInLocal =
            local.street != _textControllers[AddressFieldType.street]?.text ||
                local.state != _textControllers[AddressFieldType.state]?.text;
        if (isNotExistedInLocal) {
          continue;
        }
        showDialog(
          context: context,
          useRootNavigator: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(S.of(context).yourAddressExistYourLocal),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    S.of(context).ok,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                )
              ],
            );
          },
        );
        return false;
      }
    } catch (err) {
      printLog(err);
    }
    return true;
  }

  Future<void> saveDataToLocal() async {
    final storage = LocalStorage(LocalStorageKey.address);
    var listAddress = <Address?>[];
    listAddress.add(address);
    try {
      final ready = await storage.ready;
      if (ready) {
        var data = storage.getItem('data');
        if (data != null) {
          var listData = data as List;
          for (var item in listData) {
            final add = Address.fromLocalJson(item);
            listAddress.add(add);
          }
        }
        await storage.setItem(
            'data',
            listAddress.map((item) {
              return item!.toJsonEncodable();
            }).toList());
        await FlashHelper.message(
          context,
          message: S.of(context).yourAddressHasBeenSaved,
        );
      }
    } catch (err) {
      printLog(err);
    }
  }

  String? validateEmail(String email) {
    if (email.isEmail) {
      return null;
    }
    return 'The E-mail Address must be a valid email address.';
  }

  /// Load Shipping beforehand
  void _loadShipping({bool beforehand = true}) {
    Services().widget.loadShippingMethods(
        context, Provider.of<CartModel>(context, listen: false), beforehand);
  }

  /// on tap to Next Button
  void _onNext() {
    {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();
        Provider.of<CartModel>(context, listen: false).setAddress(address);
        _loadShipping(beforehand: false);
        widget.onNext!();
      }
    }
  }

  Widget renderStateInput() {
    var items = <DropdownMenuItem>[];
    for (var item in states) {
      items.add(
        DropdownMenuItem(
          value: item.id,
          child: Text(item.name),
        ),
      );
    }
    String? value;

    Object? firstState = states
        .firstWhereOrNull((o) => o.id.toString() == address!.state.toString());

    if (firstState != null) {
      value = address!.state;
    }
    return DropdownButton(
      items: items,
      value: value,
      onChanged: (dynamic val) {
        address!.state = val;
        refresh();
      },
      isExpanded: true,
      itemHeight: 70,
      hint: Text(S.of(context).stateProvince),
    );
  }

  void _openCountryPickerDialog() => showDialog(
        context: context,
        useRootNavigator: false,
        builder: (contextBuilder) => countries!.isEmpty
            ? Theme(
                data: Theme.of(context).copyWith(primaryColor: Colors.pink),
                child: SizedBox(
                  height: 500,
                  child: picker.CountryPickerDialog(
                    titlePadding: const EdgeInsets.all(8.0),
                    contentPadding: const EdgeInsets.all(2.0),
                    searchCursorColor: Colors.pinkAccent,
                    searchInputDecoration:
                        const InputDecoration(hintText: 'Search...'),
                    isSearchable: true,
                    title: Text(S.of(context).country),
                    onValuePicked: (picker_country.Country country) async {
                      _textControllers[AddressFieldType.country]?.text =
                          country.isoCode;
                      address!.country = country.isoCode;
                      refresh();
                      final c =
                          Country(id: country.isoCode, name: country.name);
                      states = await Services().widget.loadStates(c);
                      refresh();
                    },
                    itemBuilder: (country) {
                      return Row(
                        children: <Widget>[
                          picker.CountryPickerUtils.getDefaultFlagImage(
                              country),
                          const SizedBox(width: 8.0),
                          Expanded(child: Text(country.name)),
                        ],
                      );
                    },
                  ),
                ),
              )
            : Dialog(
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(
                      countries!.length,
                      (index) {
                        return GestureDetector(
                          onTap: () async {
                            _textControllers[AddressFieldType.country]?.text =
                                countries![index].code!;
                            address!.country = countries![index].id;
                            address!.countryId = countries![index].id;
                            refresh();
                            Navigator.pop(contextBuilder);
                            states = await Services()
                                .widget
                                .loadStates(countries![index]);
                            refresh();
                          },
                          child: ListTile(
                            leading: countries![index].icon != null
                                ? SizedBox(
                                    height: 40,
                                    width: 60,
                                    child: FluxImage(
                                      imageUrl: countries![index].icon!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : (countries![index].code != null
                                    ? Image.asset(
                                        picker.CountryPickerUtils
                                            .getFlagImageAssetPath(
                                                countries![index].code!),
                                        height: 40,
                                        width: 60,
                                        fit: BoxFit.fill,
                                        package: 'country_pickers',
                                      )
                                    : const SizedBox(
                                        height: 40,
                                        width: 60,
                                        child: Icon(Icons.streetview),
                                      )),
                            title: Text(countries![index].name!),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
      );

  void onTextFieldSaved(String? value, AddressFieldType type) {
    switch (type) {
      case AddressFieldType.firstName:
        address?.firstName = value;
        break;
      case AddressFieldType.lastName:
        address?.lastName = value;
        break;
      case AddressFieldType.phoneNumber:
        address?.phoneNumber = value;
        break;
      case AddressFieldType.email:
        address?.email = value;
        break;
      case AddressFieldType.country:
        address?.country = value;
        break;
      case AddressFieldType.state:
        address?.state = value;
        break;

      case AddressFieldType.apartment:
        address?.apartment = value;
        break;

      case AddressFieldType.street:
        address?.street = value;
        break;

      /// Unsupported.
      case AddressFieldType.searchAddress:
      case AddressFieldType.selectAddress:
      case AddressFieldType.unknown:
      default:
        break;
    }
  }

  String? getFieldLabel(AddressFieldType type) {
    switch (type) {
      case AddressFieldType.firstName:
        return S.of(context).firstName;
      case AddressFieldType.lastName:
        return S.of(context).lastName;
      case AddressFieldType.phoneNumber:
        return S.of(context).phoneNumber;
      case AddressFieldType.email:
        return S.of(context).email;
      case AddressFieldType.country:
        return S.of(context).country;
      case AddressFieldType.state:
        return S.of(context).stateProvince;

      case AddressFieldType.apartment:
        return S.of(context).streetNameApartment;

      case AddressFieldType.street:
        return S.of(context).streetName;

      case AddressFieldType.searchAddress:
      case AddressFieldType.selectAddress:
      default:
        return null;
    }
  }

  String? validateField(
      String? val, AddressFieldConfig config, AddressFieldType type) {
    if (!config.required) {
      return null;
    }

    final label = getFieldLabel(type)?.toLowerCase();
    if (val != null && val.isEmpty && label != null) {
      return S.of(context).theFieldIsRequired(label);
    }
    if (val != null && type == AddressFieldType.email) {
      return validateEmail(val);
    }
    return null;
  }

  TextInputType getKeyboardType(AddressFieldType type) {
    // if (type == AddressFieldType.zipCode &&
    //     kPaymentConfig.enableAlphanumericZipCode) {
    //   return TextInputType.streetAddress;
    // }
    return type.keyboardType;
  }

  Widget _buildBottom() {
    return CommonSafeArea(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 150,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () {
                if (!checkToSave()) return;
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  Provider.of<CartModel>(context, listen: false)
                      .setAddress(address);
                  saveDataToLocal();
                }
              },
              icon: const Icon(
                CupertinoIcons.plus_app,
                size: 20,
              ),
              label: Text(
                S.of(context).saveAddress.toUpperCase(),
                style: Theme.of(context).textTheme.caption!.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
            ),
          ),
          Container(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
                elevation: 0.0,
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(
                Icons.local_shipping_outlined,
                size: 18,
              ),
              onPressed: _onNext,
              label: Text(
                (kPaymentConfig.enableShipping
                        ? S.of(context).continueToShipping
                        : kPaymentConfig.enableReview
                            ? S.of(context).continueToReview
                            : S.of(context).continueToPayment)
                    .toUpperCase(),
                style: Theme.of(context)
                    .textTheme
                    .caption!
                    .copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool isFieldReadOnly(int index) {
    final config = _configs[index];
    if (config == null) {
      return false;
    }

    /// Disable edit only when the field has a default value.
    if (!config.editable && config.defaultValue.isNotEmpty) {
      return true;
    }

    return false;
  }
}
