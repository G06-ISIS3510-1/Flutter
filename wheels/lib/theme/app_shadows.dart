import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  static const sm = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(26, 58, 92, 0.05),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const md = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(26, 58, 92, 0.08),
      blurRadius: 6,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color.fromRGBO(26, 58, 92, 0.04),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const lg = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(26, 58, 92, 0.1),
      blurRadius: 15,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color.fromRGBO(26, 58, 92, 0.05),
      blurRadius: 6,
      offset: Offset(0, 4),
    ),
  ];

  static const xl = <BoxShadow>[
    BoxShadow(
      color: Color.fromRGBO(26, 58, 92, 0.1),
      blurRadius: 25,
      offset: Offset(0, 20),
    ),
    BoxShadow(
      color: Color.fromRGBO(26, 58, 92, 0.04),
      blurRadius: 10,
      offset: Offset(0, 10),
    ),
  ];

  static Color get divider => AppColors.border;
}
