import 'package:flutter/material.dart';
import 'package:inspireui/inspireui.dart';

import 'package:provider/provider.dart';

import '../../../../common/tools/tools.dart';
import '../../../../generated/l10n.dart';

import '../../widgets/common/common_safe_area.dart';
import '../../widgets/common/custom_text_form_field.dart';
import 'sms_model.dart';

class SMSInfo extends StatefulWidget {
  final Function onSuccess;
  const SMSInfo({Key? key, required this.onSuccess}) : super(key: key);

  @override
  State<SMSInfo> createState() => _SMSInfoState();
}

class _SMSInfoState extends State<SMSInfo> {
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';

  final _firstNameNode = FocusNode();
  final _lastNameNode = FocusNode();
  final _emailNode = FocusNode();
  final _passNode = FocusNode();
  final _confirmPassNode = FocusNode();

  final _userExists = 'user-exists';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ValueNotifier<bool> _enableButton = ValueNotifier<bool>(false);

  SMSModel get model => Provider.of<SMSModel>(context, listen: false);

  void _showMessage(err) {
    if (err == _userExists) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.of(context).userExists),
        duration: const Duration(seconds: 1),
      ));
    }
  }

  void _createAccount() async {
    if (model.state != SMSModelState.loading) {
      Tools.hideKeyboard(context);
      final result = await model.isUserExisted(_email);

      /// User is not registered. Create a user.
      if (!result) {
        final data = {
          'firstName': _firstName,
          'lastName': _lastName,
          'username': _email,
          'password': _password,
          'phoneNumber': model.phoneNumber,
        };
        widget.onSuccess(data);
      } else {
        _showMessage(_userExists);
      }
    }
  }

  String? _validateConfirmPassword(value) {
    if (value?.isEmpty ?? true) {
      return 'تأكيد كلمة السر مطلوبة';
    }
    if (value != _password) {
      return 'كلمات السر غير متطابقة';
    }
    return null;
  }

  String? _validatePassword(value) {
    if (value?.isEmpty ?? true) {
      return 'كلمة السر مطلوبة';
    }
    if (value.length < 8) {
      return 'يجب أن تكون كلمة السر من 8 أحرف على الأقل';
    }
    return null;
  }

  String? _validateUsername(value) {
    if (value?.isEmpty ?? true) {
      return 'الإيميل مطلوب';
    }
    return null;
  }

  String? _validateLastName(value) {
    if (value?.isEmpty ?? true) {
      return 'اللقب مطلوب';
    }
    return null;
  }

  String? _validateFirstName(value) {
    if (value?.isEmpty ?? true) {
      return 'الأسم الأول';
    }
    return null;
  }

  void _onFormChange() {
    if (_firstName.isEmpty ||
        _lastName.isEmpty ||
        _email.isEmpty ||
        _password.isEmpty ||
        _confirmPassword.isEmpty) {
      _enableButton.value = false;
      return;
    }
    _enableButton.value = _formKey.currentState?.validate() ?? false;
  }

  @override
  void dispose() {
    _firstNameNode.dispose();
    _lastNameNode.dispose();
    _emailNode.dispose();
    _passNode.dispose();
    _confirmPassNode.dispose();
    _enableButton.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AutoHideKeyboard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    S.of(context).accountSetup,
                    style: theme.textTheme.headline4,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    S.of(context).youNotBeAsked,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16.0),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 24,
                        ),
                        child: Form(
                          key: _formKey,
                          onChanged: _onFormChange,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextFormField(
                                focusNode: _firstNameNode,
                                validator: _validateFirstName,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                showCancelIcon: true,
                                autofillHints: const [AutofillHints.givenName],
                                nextNode: _lastNameNode,
                                onChanged: (value) => _firstName = value,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  labelText: S.of(context).firstName,
                                ),
                              ),
                              const SizedBox(height: 12.0),
                              CustomTextFormField(
                                focusNode: _lastNameNode,
                                validator: _validateLastName,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                showCancelIcon: true,
                                autofillHints: const [AutofillHints.familyName],
                                nextNode: _emailNode,
                                onChanged: (value) => _lastName = value,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  labelText: S.of(context).lastName,
                                ),
                              ),
                              const SizedBox(height: 12.0),
                              TextFormField(
                                focusNode: _emailNode,
                                validator: _validateUsername,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                // showCancelIcon: true,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                // nextNode: _passNode,
                                onChanged: (value) => _email = value,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText:
                                      S.of(context).enterYourEmailOrUsername,
                                ),
                                initialValue: '${model.phoneNumber}@br.com',
                                textDirection: TextDirection.ltr,
                              ),
                              const SizedBox(height: 12.0),
                              CustomTextFormField(
                                focusNode: _passNode,
                                validator: _validatePassword,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                nextNode: _confirmPassNode,
                                showEyeIcon: true,
                                autofillHints: const [AutofillHints.password],
                                onChanged: (value) => _password = value,
                                keyboardType: TextInputType.text,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: S.of(context).password,
                                ),
                              ),
                              CustomTextFormField(
                                focusNode: _confirmPassNode,
                                validator: _validateConfirmPassword,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                showEyeIcon: true,
                                onChanged: (value) => _confirmPassword = value,
                                keyboardType: TextInputType.text,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm password',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          CommonSafeArea(
            child: SizedBox(
              height: 48,
              child: ValueListenableBuilder<bool>(
                  valueListenable: _enableButton,
                  builder: (context, enable, _) {
                    return ElevatedButton.icon(
                      onPressed: enable ? _createAccount : null,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      label: Text(
                        S.of(context).done,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      icon: Icon(
                        Icons.done,
                        color: Theme.of(context).backgroundColor,
                      ),
                    );
                  }),
            ),
          ),
        ],
      ),
    );
  }
}


//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return SingleChildScrollView(
//       child: Form(
//         autovalidateMode: AutovalidateMode.onUserInteraction,
//         key: _formKey2,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(
//               height: 10.0,
//             ),
//             Text(
//               S.of(context).accountSetup,
//               style: theme.textTheme.headline5,
//             ),
//             Text(S.of(context).youNotBeAsked),
//             const SizedBox(height: 20.0),
//             TextFormField(
//               focusNode: _firstNameNode,
//               autofillHints: const [AutofillHints.givenName],
//               validator: (val) {
//                 return val!.isEmpty ? '*' : null;
//               },
//               onChanged: (value) => _firstName = value,
//               keyboardType: TextInputType.text,
//               decoration: InputDecoration(
//                 labelText: S.of(context).firstName,
//                 contentPadding: const EdgeInsets.all(6),
//                 border: const OutlineInputBorder(
//                   borderSide: BorderSide(color: Colors.grey, width: 1),
//                 ),
//                 focusedBorder: const OutlineInputBorder(
//                   borderSide: BorderSide(color: Colors.grey, width: 1),
//                 ),
//                 errorStyle: const TextStyle(fontSize: 3),
//               ),
//             ),
//             const SizedBox(height: 20.0),
//             TextFormField(
//               focusNode: _lastNameNode,
//               autofillHints: const [AutofillHints.familyName],
//               validator: (val) {
//                 return val!.isEmpty ? '*' : null;
//               },
//               onChanged: (value) => _lastName = value,
//               keyboardType: TextInputType.text,
//               decoration: InputDecoration(
//                 contentPadding: const EdgeInsets.all(6),
//                 labelText: S.of(context).lastName,
//                 border: const OutlineInputBorder(
//                   borderSide: BorderSide(color: Colors.grey, width: 1),
//                 ),
//                 focusedBorder: const OutlineInputBorder(
//                   borderSide: BorderSide(color: Colors.grey, width: 1),
//                 ),
//                 errorStyle: const TextStyle(fontSize: 3),
//               ),
//             ),
//             const SizedBox(height: 20.0),
//             Consumer<SMSModel>(builder: (_, model, __) {
//               return TextFormField(
//                 enabled: false,
//                 focusNode: _emailNode,
//                 textDirection: TextDirection.ltr,
//                 autofillHints: const [AutofillHints.email],
//                 // nextNode: _passNode,
//                 validator: (val) {
//                   return val!.isEmpty ? '*' : null;
//                 },
//                 initialValue: '${model.phoneNumber}@br.com',
//                 // onChanged: (value) => _email = value,
//                 keyboardType: TextInputType.emailAddress,
//                 decoration: InputDecoration(
//                     contentPadding: const EdgeInsets.all(6),
//                     border: const OutlineInputBorder(
//                       borderSide: BorderSide(color: Colors.grey, width: 1),
//                     ),
//                     focusedBorder: const OutlineInputBorder(
//                       borderSide: BorderSide(color: Colors.grey, width: 1),
//                     ),
//                     errorStyle: const TextStyle(fontSize: 3),
//                     labelText: S.of(context).email),
//                 // hintText: S.of(context).enterYourEmailOrUsername,
//               );
//             }),
//             const SizedBox(height: 20.0),
//             TextFormField(
//               focusNode: _passNode,
//               autofillHints: const [AutofillHints.password],
//               onChanged: (value) => _password = value,
//               keyboardType: TextInputType.text,
//               obscureText: true,
//               validator: (val) {
//                 if (val!.length < 8) {
//                   return 'يجب أن تكون كلمة السر من 8 أحرف على الأقل';
//                 }
//                 return null;
//               },
//               decoration: InputDecoration(
//                 labelText: S.of(context).password,
//                 contentPadding: const EdgeInsets.all(6),
//                 border: const OutlineInputBorder(
//                   borderSide: BorderSide(color: Colors.grey, width: 1),
//                 ),
//                 errorStyle: const TextStyle(fontSize: 10),
//                 focusedBorder: const OutlineInputBorder(
//                   borderSide: BorderSide(color: Colors.grey, width: 1),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20.0),
//             Center(
//               child: Consumer<SMSModel>(
//                 builder: (_, model, __) => TextButton(
//                     onPressed: () async {
//                       if (_formKey2.currentState!.validate()) {
//                         _formKey2.currentState!.save();

//                         if (model.state != SMSModelState.loading) {
//                           Tools.hideKeyboard(context);
//                           final result = await model.isUserExisted(_email);

//                           /// User is not registered. Create a user.
//                           if (!result) {
//                             final data = {
//                               'firstName': _firstName,
//                               'lastName': _lastName,
//                               'username': _email,
//                               'password': _password,
//                               'phoneNumber': model.phoneNumber,
//                             };
//                             widget.onSuccess(data);
//                           } else {
//                             _showMessage(_userExists);
//                           }
//                         }
//                       }
//                     },
//                     style: TextButton.styleFrom(
//                       backgroundColor: Theme.of(context).primaryColor,
//                     ),
//                     child: model.state == SMSModelState.loading
//                         ? const SizedBox(
//                             height: 20,
//                             width: 20,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 1.0,
//                               valueColor:
//                                   AlwaysStoppedAnimation<Color>(Colors.white),
//                             ),
//                           )
//                         : const Icon(
//                             Icons.check,
//                             color: Colors.white,
//                           )),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
