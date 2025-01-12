// lib/widgets/custom_drawer.dart

import 'package:diamond_host_admin/screens/accepted_private_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../screens/private_chat_request_screen.dart';
import '../state_management/general_provider.dart';
import '../localization/language_constants.dart';
import '../screens/notification_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/upgrade_account_screen.dart';
import '../screens/all_posts_screen.dart';
import '../screens/customer_points_screen.dart';
import '../screens/settings_screen.dart';
import '../backend/log_out_method.dart';
import '../constants/colors.dart';
import '../utils/global_methods.dart';
import 'item_drawer.dart';
import '../extension/sized_box_extension.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GeneralProvider>(context);

    return Drawer(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? kDarkModeColor
          : Colors.white,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding:
                  const EdgeInsets.only(top: 20), // Reduce space above image
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 100, // Radius of the outer circle
                      backgroundColor:
                          Colors.transparent, // Transparent background
                    ),
                    ClipOval(
                      child: Image.asset(
                        "assets/images/logo.png",
                        width: 160, // Exact width for the image
                        height: 160, // Exact height for the image
                        fit: BoxFit
                            .cover, // Ensures the image covers the circle area
                      ),
                    ),
                  ],
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
              hint: getTranslated(context, "You can view your data here"),
            ),
            DrawerItem(
              text: getTranslated(context, "Posts"),
              icon: Icon(Bootstrap.file_text, color: kDeepPurpleColor),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const AllPostsScreen()));
              },
              hint: getTranslated(context, "Show the Post"),
            ),
            DrawerItem(
              icon: Icon(Icons.point_of_sale, color: kDeepPurpleColor),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CustomerPoints(),
                  ),
                );
              },
              hint: getTranslated(
                  context, "From here you can get points and discounts"),
              text: getTranslated(context, "My Points"),
            ),
            DrawerItem(
              icon: Icon(Icons.message, color: kDeepPurpleColor),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const PrivateChatRequestsScreen()));
              },
              hint: getTranslated(
                  context, "From here you can receive chat request."),
              text: getTranslated(context, "Private Chat Request."),
            ),
            DrawerItem(
              icon: Icon(Icons.message, color: kDeepPurpleColor),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const AcceptedPrivateChatScreen()));
              },
              hint: getTranslated(
                  context, "From here you can chat privately with other users"),
              text: getTranslated(context, "Private Chat"),
            ),
            DrawerItem(
              text: getTranslated(context, "Booking Status"),
              icon: Icon(Icons.notification_add, color: kPurpleColor),
              badge: provider.approvalCount > 0
                  ? badges.Badge(
                      badgeContent: Text(
                        provider.approvalCount.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      child: Icon(Icons.notification_add, color: kPurpleColor),
                    )
                  : null,
              onTap: () {
                // Reset the approval count when navigating to the NotificationScreen
                provider.resetApprovalCount();
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
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => UpgradeAccountScreen()));
              },
              hint: getTranslated(
                  context, "From here you can upgrade account to Vip"),
            ),
            DrawerItem(
              text: getTranslated(context, "Settings"),
              icon: Icon(Icons.settings, color: kDeepPurpleColor),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const SettingsScreen()));
              },
              hint: '',
            ),
            // New DrawerItem for Private Chat Requests

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
