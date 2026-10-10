import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../utils/constants.dart';

/// Reusable profile avatar icon/button for top-right headers and app bars.
class ProfileAvatarButton extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const ProfileAvatarButton({
    super.key,
    this.size = 36.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final name = (user?.displayName.isNotEmpty == true)
        ? user!.displayName
        : (user?.email.isNotEmpty == true ? user!.email : 'Shopper');
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'S';

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Center(
        child: Tooltip(
          message: 'Customer Profile',
          child: InkWell(
            borderRadius: BorderRadius.circular(size),
            onTap: onTap ??
                () {
                  final homeState = HomeScreen.of(context);
                  if (homeState != null && ModalRoute.of(context)?.isFirst == true) {
                    HomeScreen.switchTab(context, 2);
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(showAppBar: true),
                      ),
                    );
                  }
                },
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.inter(
                    fontSize: size * 0.44,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Standardized FlashCart AppBar with consistent title and top-right profile button.
class FlashCartAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final String? titleText;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool showProfile;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const FlashCartAppBar({
    super.key,
    this.title,
    this.titleText,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.actions,
    this.bottom,
    this.showProfile = true,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title ?? (titleText != null ? Text(titleText!) : null),
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      bottom: bottom,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      actions: [
        ...?actions,
        if (showProfile) const ProfileAvatarButton(),
      ],
    );
  }
}
