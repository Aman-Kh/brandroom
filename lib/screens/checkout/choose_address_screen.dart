import 'dart:async';

import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import '../../generated/l10n.dart';
import '../../models/index.dart' show Address, CartModel, User, UserModel;
import '../../services/index.dart';
import '../index.dart' show BaseScreen;

class ChooseAddressScreen extends StatefulWidget {
  final void Function(Address?) callback;

  const ChooseAddressScreen(this.callback);

  @override
  BaseScreen<ChooseAddressScreen> createState() => _StateChooseAddress();
}

class _StateChooseAddress extends BaseScreen<ChooseAddressScreen> {
  List<Address?> listAddress = [];
  User? user;
  bool isLoading = true;

  @override
  void afterFirstLayout(BuildContext context) {
    getDatafromLocal();
    final loggedIn = Provider.of<UserModel>(context, listen: false).loggedIn;
    if (loggedIn) {
      getUserInfo().then((_) async {
        await getDataFromNetwork();
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      });
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> getUserInfo() async {
    final storage = injector<LocalStorage>();
    final userJson = storage.getItem(kLocalKey['userInfo']!);
    if (userJson != null) {
      final user = await Services().api.getUserInfo(userJson['cookie']);
      if (user != null) {
        user.isSocial = userJson['isSocial'] ?? false;
        setState(() {
          this.user = user;
        });
      }
    }
  }

  Future<void> getDatafromLocal() async {
    final storage = LocalStorage(LocalStorageKey.address);
    var list = <Address?>[];
    try {
      final ready = await storage.ready;
      if (ready) {
        var data = storage.getItem('data');
        if (data != null) {
          for (var item in data as List) {
            final add = Address.fromLocalJson(item);
            list.add(add);
          }
        }
      }
      setState(() {
        listAddress = list;
      });
    } catch (_) {}
  }

  Future<void> getDataFromNetwork() async {
    try {
      var result = await Services().api.getCustomerInfo(user!.id)!;

      if (result['billing'] != null) {
        listAddress.add(result['billing']);
      }
    } catch (err) {
      printLog(err);
    }
  }

  void removeData(int index) {
    final storage = LocalStorage(LocalStorageKey.address);
    try {
      var data = storage.getItem('data');
      if (data != null) {
        (data as List).removeAt(index);
      }
      storage.setItem('data', data);
    } catch (_) {}
    getDatafromLocal();
  }

  Widget convertToCard(BuildContext context, Address address) {
    final s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 10.0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${s.streetName}:  ',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
            Flexible(
              child: Column(
                children: <Widget>[Text(address.street.toString())],
              ),
            )
          ],
        ),
        // const SizedBox(height: 4.0),
        // Row(
        //   crossAxisAlignment: CrossAxisAlignment.start,
        //   children: <Widget>[
        //     Text(
        //       '${s.city}:  ',
        //       style: TextStyle(color: Theme.of(context).primaryColor),
        //     ),
        //     Flexible(
        //       child: Column(
        //         children: <Widget>[Text(address.city.toString())],
        //       ),
        //     )
        //   ],
        // ),
        const SizedBox(height: 4.0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${s.stateProvince}:  ',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
            Flexible(
              child: Column(
                children: <Widget>[Text(address.state.toString())],
              ),
            )
          ],
        ),
        const SizedBox(height: 4.0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${s.country}:  ',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
            Flexible(
              child: Column(
                children: <Widget>[Text(address.country.toString())],
              ),
            )
          ],
        ),
        // const SizedBox(height: 4.0),
        // Row(
        //   crossAxisAlignment: CrossAxisAlignment.start,
        //   children: <Widget>[
        //     Text(
        //       '${s.zipCode}:  ',
        //       style: TextStyle(color: Theme.of(context).primaryColor),
        //     ),
        //     Flexible(
        //       child: Column(
        //         children: <Widget>[Text(address.zipCode.toString())],
        //       ),
        //     )
        //   ],
        // ),
        const SizedBox(height: 10.0),
      ],
    );
  }

  Widget _renderBillingAddress() {
    if (user == null || user!.billing == null) {
      return const SizedBox();
    }
    final userFullName =
        '${user!.billing!.firstName ?? ''} ${user!.billing!.lastName ?? ''}'
            .trim();
    return GestureDetector(
      onTap: () {
        final add = Address(
          firstName: (user!.billing!.firstName?.isNotEmpty ?? false)
              ? user!.billing!.firstName
              : user!.firstName,
          lastName: (user!.billing!.lastName?.isNotEmpty ?? false)
              ? user!.billing!.lastName
              : user!.lastName,
          email: (user!.billing!.email?.isNotEmpty ?? false)
              ? user!.billing!.email
              : user!.email,
          street: user!.billing!.address1,
          country: user!.billing!.country,
          state: user!.billing!.state,
          phoneNumber: user!.billing!.phone,
          city: user!.billing!.city,
          // zipCode: user!.billing!.postCode
        );
        Provider.of<CartModel>(context, listen: false).setAddress(add);
        Navigator.of(context).pop();
        widget.callback(add);
      },
      child: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).primaryColorLight,
            borderRadius: BorderRadius.circular(10)),
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              S.of(context).billingAddress,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(userFullName),
            Text(user!.billing!.phone ?? ''),
            Text(user!.billing!.email ?? ''),
            Text(user!.billing!.address1 ?? ''),
            Text(user!.billing!.city ?? ''),
            // Text(user!.billing!.postCode ?? '')
          ],
        ),
      ),
    );
  }

  Widget _renderShippingAddress() {
    if (user == null || user!.shipping == null) return const SizedBox();
    final userFullName =
        '${user!.billing!.firstName ?? ''} ${user!.billing!.lastName ?? ''}'
            .trim();
    return GestureDetector(
      onTap: () {
        final add = Address(
          firstName: (user!.shipping!.firstName?.isNotEmpty ?? false)
              ? user!.shipping!.firstName
              : user!.firstName,
          lastName: (user!.shipping!.lastName?.isNotEmpty ?? false)
              ? user!.shipping!.lastName
              : user!.lastName,
          email: user!.email,
          street: user!.shipping!.address1,
          country: user!.shipping!.country,
          state: user!.shipping!.state,
          city: user!.shipping!.city,
          // zipCode: user!.shipping!.postCode,
          phoneNumber: user!.shipping!.phone,
        );
        Provider.of<CartModel>(context, listen: false).setAddress(add);
        Navigator.of(context).pop();
        widget.callback(add);
      },
      child: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).primaryColorLight,
            borderRadius: BorderRadius.circular(10)),
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              S.of(context).shippingAddress,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(userFullName),
            Text(user!.shipping!.address1 ?? ''),
            Text(user!.shipping!.city ?? ''),
            Text(user!.shipping!.postCode ?? '')
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColorLight,
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: const Icon(Icons.arrow_back_ios),
        ),
        title: Text(
          S.of(context).selectAddress,
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _renderBillingAddress(),
            _renderShippingAddress(),
            Column(
              children: [
                if (listAddress.isEmpty && !isLoading)
                  Center(
                    child: Image.asset(
                      kEmptySearch,
                      width: 120,
                      height: 120,
                    ),
                  ),
                if (listAddress.isEmpty && isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: kLoadingWidget(context),
                  ),
                ...List.generate(listAddress.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: GestureDetector(
                        onTap: () {
                          Provider.of<CartModel>(context, listen: false)
                              .setAddress(listAddress[index]);
                          Navigator.of(context).pop();
                          widget.callback(listAddress[index]);
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                              color: Theme.of(context).primaryColorLight),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: <Widget>[
                                // Padding(
                                //   padding: const EdgeInsets.symmetric(
                                //       horizontal: 10),
                                //   child: Icon(
                                //     Icons.home,
                                //     color: Theme.of(context).primaryColor,
                                //     size: 18,
                                //   ),
                                // ),
                                // const SizedBox(width: 10),
                                Expanded(
                                  child: convertToCard(
                                      context, listAddress[index]!),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    removeData(index);
                                  },
                                  child: Icon(
                                    Icons.delete,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                })
              ],
            ),
          ],
        ),
      ),
    );
  }
}
