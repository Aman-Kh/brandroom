import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

TextTheme buildTextTheme(
  TextTheme base,
  String? language, [
  String fontFamily = 'Roboto',
  String fontHeader = 'Raleway',
]) {
  switch (language) {

    /// Duplicate this part & change 'en'
    /// to support multiple fonts for multiple languages.
    /// ---- copy this part below, from:
    case 'en':
      fontFamily = 'Roboto';
      fontHeader = 'Raleway';

      break;

    /// ---- to here.
    case 'ar':
      fontFamily = 'Noto Sans Arabic';
      fontHeader = 'Noto Sans Arabic';

      break;
    default:
      fontFamily = 'Roboto';
      fontHeader = 'Raleway';
  }
  return base
      .copyWith(
        headline1: GoogleFonts.getFont(
          fontHeader,
          textStyle: base.headline1!.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ).copyWith(

            /// If using the custom font
            /// un-comment below and clone to other headline.., bodyText..
            // fontFamily: 'Your Custom Font',
            ),
        headline2: GoogleFonts.getFont(
          fontHeader,
          textStyle: base.headline1!.copyWith(fontWeight: FontWeight.w700),
        ),
        headline3: GoogleFonts.getFont(
          fontHeader,
          textStyle: base.headline3!.copyWith(fontWeight: FontWeight.w700),
        ),
        headline4: GoogleFonts.getFont(
          fontHeader,
          textStyle: base.headline4!.copyWith(fontWeight: FontWeight.w700),
        ),
        headline5: GoogleFonts.getFont(
          fontHeader,
          textStyle: base.headline5!.copyWith(fontWeight: FontWeight.w500),
        ),
        headline6: GoogleFonts.getFont(
          fontHeader,
          textStyle: base.headline6!.copyWith(
            fontWeight: FontWeight.normal,
          ),
        ).copyWith(
            // fontFamily: 'Your Custom Font',
            ),
        caption: GoogleFonts.getFont(
          fontFamily,
          textStyle: base.caption!
              .copyWith(fontWeight: FontWeight.w400, fontSize: 14.0),
        ),
        subtitle1: GoogleFonts.getFont(
          fontFamily,
          textStyle: base.subtitle1!.copyWith(),
        ),
        subtitle2: GoogleFonts.getFont(
          fontFamily,
          textStyle: base.subtitle2!.copyWith(),
        ),
        bodyText1: GoogleFonts.getFont(
          fontFamily,
          textStyle: base.bodyText1!.copyWith(),
        ),
        bodyText2: GoogleFonts.getFont(
          fontFamily,
          textStyle: base.bodyText1!.copyWith(),
        ),
        button: GoogleFonts.getFont(
          fontFamily,
          textStyle: base.button!
              .copyWith(fontWeight: FontWeight.w400, fontSize: 14.0),
        ),
      )
      .apply(
        displayColor: kGrey900,
        bodyColor: kGrey900,
      );
}
