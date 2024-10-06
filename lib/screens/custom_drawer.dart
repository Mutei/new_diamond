import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../constants/colors.dart';
import '../widgets/item_drawer.dart';
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
              padding: EdgeInsets.only(top: 20), // Reduce space above image
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
                text: "Profile",
                icon: Icon(Icons.person, color: kDeepOrange),
                onTap: () {
                  // Navigator.of(context).push(MaterialPageRoute(
                  //     builder: (context) => const ProfileScreenUser()));
                },
                hint: "You can view your data here"),
            DrawerItem(
              text: "Posts",
              icon: Icon(Icons.person, color: kDeepOrange),
              onTap: () {
                // Navigator.of(context).push(MaterialPageRoute(
                //     builder: (context) => const AllPostsScreen()));
              },
              hint: "Show the Post ",
            ),
            DrawerItem(
              icon: Icon(Icons.point_of_sale, color: kDeepOrange),
              onTap: () {
                // Navigator.of(context).push(MaterialPageRoute(
                //     builder: (context) => const CustomerPoints()));
              },
              hint: "From here you can get points and discounts",
              text: "My Points",
            ),
            DrawerItem(
              icon: Icon(Icons.message, color: kDeepOrange),
              onTap: () {
                // Navigator.of(context).push(MaterialPageRoute(
                //     builder: (context) => const PrivateChatRequest()));
              },
              hint: "From here you can chat privately with other users",
              text: "Private Chat",
            ),
            DrawerItem(
              text: "Notification",
              icon: Icon(Icons.notification_add, color: kDeepOrange),
              onTap: () {
                // Navigator.of(context).push(MaterialPageRoute(
                //     builder: (context) => ProviderNotificationScreen()));
              },
              hint:
                  "You can see the notifications that come to you, such as booking confirmation",
            ),
            DrawerItem(
              text: "Upgrade account",
              icon: Icon(
                Icons.update,
                color: kDeepOrange,
              ),
              onTap: () {
                // Navigator.of(context).pop();
                // Navigator.of(context).push(
                //     MaterialPageRoute(builder: (context) => UpgradeAccount()));
              },
              hint: "From here you can upgrade account to Vip",
            ),
            DrawerItem(
              text: "Arabic",
              icon: Icon(Icons.language, color: kDeepOrange),
              onTap: () async {
                // SharedPreferences sharedPreferences =
                // await SharedPreferences.getInstance();
                // sharedPreferences.setString("Language", "ar");
                // Locale newLocale = const Locale("ar", "SA");
                // MyApp.setLocale(context, newLocale);
                // Provider.of<GeneralProvider>(context, listen: false)
                //     .updateLanguage(false);
              },
              hint: "",
            ),
            DrawerItem(
              text: "English",
              icon: Icon(Icons.language, color: kDeepOrange),
              onTap: () async {
                // SharedPreferences sharedPreferences =
                // await SharedPreferences.getInstance();
                // sharedPreferences.setString("Language", "en");
                // Locale newLocale = const Locale("en", "SA");
                // MyApp.setLocale(context, newLocale);
                // Provider.of<GeneralProvider>(context, listen: false)
                //     .updateLanguage(true);
              },
              hint: '',
            ),
            DrawerItem(
              text: "Logout",
              icon: Icon(Icons.logout, color: kDeepOrange),
              onTap: () async {
                // await AuthMethods().signOut(context);
              },
              hint: '',
            )
          ],
        ),
      ),
    );
  }
}
