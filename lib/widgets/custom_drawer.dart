import 'package:diamond_host_admin/extension/sized_box_extension.dart';
import 'package:diamond_host_admin/localization/language_constants.dart';
import 'package:diamond_host_admin/screens/notification_screen.dart';
import 'package:diamond_host_admin/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import '../backend/log_out_method.dart';
import '../constants/colors.dart';
import '../main.dart';
import '../state_management/general_provider.dart';
import '../utils/global_methods.dart';
import 'item_drawer.dart';
import 'package:badges/badges.dart' as badges;

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding:
                  const EdgeInsets.only(top: 20), // Reduce space above image
              child: Center(
                child: Image.asset(
                  "assets/images/logo.png",
                  width: 200, // Increase width to make the image larger
                  height: 200, // Maintain aspect ratio with width
                  fit: BoxFit.cover, // Make the image cover the area
                ),
              ),
            ),
            DrawerItem(
                text: getTranslated(context, "Profile"),
                icon: Icon(Icons.person, color: kDeepPurpleColor),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const ProfileScreenUser()));
                },
                hint: getTranslated(context, "You can view your data here")),
            DrawerItem(
              text: getTranslated(context, "Posts"),
              icon: Icon(Bootstrap.file_text, color: kDeepPurpleColor),
              onTap: () {},
              hint: getTranslated(context, "Show the Post"),
            ),
            DrawerItem(
              icon: Icon(Icons.point_of_sale, color: kDeepPurpleColor),
              onTap: () {},
              hint: getTranslated(
                  context, "From here you can get points and discounts"),
              text: getTranslated(context, "My Points"),
            ),
            DrawerItem(
              icon: Icon(Icons.message, color: kDeepPurpleColor),
              onTap: () {},
              hint: getTranslated(
                  context, "From here you can chat privately with other users"),
              text: getTranslated(context, "Private Chat"),
            ),
            DrawerItem(
              text: getTranslated(context, "Booking Status"),
              icon: Icon(Icons.notification_add, color: kDeepPurpleColor),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const NotificationScreen()));
              },
              hint: getTranslated(context,
                  "You can see the notifications that come to you, such as booking confirmation"),
            ),
            DrawerItem(
              text: getTranslated(context, "Upgrade account"),
              icon: Icon(
                Icons.update,
                color: kDeepPurpleColor,
              ),
              onTap: () {},
              hint: getTranslated(
                  context, "From here you can upgrade account to Vip"),
            ),
            DrawerItem(
              text: getTranslated(context, "Arabic"),
              icon: Icon(Icons.language, color: kDeepPurpleColor),
              onTap: () async {
                SharedPreferences sharedPreferences =
                    await SharedPreferences.getInstance();
                sharedPreferences.setString("Language", "ar");
                Locale newLocale = const Locale("ar", "SA");
                MyApp.setLocale(context, newLocale);
                Provider.of<GeneralProvider>(context, listen: false)
                    .updateLanguage(false);
              },
              hint: "",
            ),
            DrawerItem(
              text: getTranslated(context, "English"),
              icon: Icon(Icons.language, color: kDeepPurpleColor),
              onTap: () async {
                SharedPreferences sharedPreferences =
                    await SharedPreferences.getInstance();
                sharedPreferences.setString("Language", "en");
                Locale newLocale = const Locale("en", "SA");
                MyApp.setLocale(context, newLocale);
                Provider.of<GeneralProvider>(context, listen: false)
                    .updateLanguage(true);
              },
              hint: '',
            ),
            DrawerItem(
                text: Provider.of<GeneralProvider>(context).isDarkMode
                    ? getTranslated(context, "Light Mode")
                    : getTranslated(context, "Dark Mode"), // Text for dark mode
                icon: Icon(
                  Provider.of<GeneralProvider>(context).isDarkMode
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  color: kDeepPurpleColor,
                ),
                onTap: () {
                  Provider.of<GeneralProvider>(context, listen: false)
                      .toggleTheme();
                },
                hint: ''),
            DrawerItem(
              text: getTranslated(context, "Logout"),
              icon: Icon(Icons.logout, color: kDeepPurpleColor),
              onTap: () {
                showLogoutConfirmationDialog(context, () async {
                  await LogOutMethod().logOut(context);
                });
              },
              hint: '',
            ),
          ],
        ),
      ),
    );
  }
}
