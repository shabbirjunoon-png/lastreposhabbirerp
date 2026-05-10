import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppHeaderAction {
  final IconData icon;
  final VoidCallback onPress;
  final bool destructive;
  const AppHeaderAction(
      {required this.icon, required this.onPress, this.destructive = false});
}

class ShabbirLogo extends StatelessWidget {
  final double size;
  final Color bgColor;
  final Color textColor;
  final Color badgeColor;
  final bool showBadge;

  const ShabbirLogo({
    super.key,
    this.size = 36,
    this.bgColor = AppColors.primary,
    this.textColor = AppColors.accent,
    this.badgeColor = AppColors.accent,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Center(
            child: Text(
              'S',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
                fontSize: size * 0.5,
                color: textColor,
                height: 1,
              ),
            ),
          ),
        ),
        if (showBadge)
          Positioned(
            top: -(size * 0.18),
            right: -(size * 0.18),
            child: Container(
              width: size * 0.44,
              height: size * 0.44,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: bgColor, width: 1.5),
              ),
              child: Center(
                child: Icon(
                  Icons.workspace_premium,
                  size: size * 0.24,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<AppHeaderAction>? actions;

  const AppHeader(
      {super.key,
      required this.title,
      this.subtitle,
      this.onBack,
      this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 20,
          right: 20,
          bottom: 14),
      decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: AppColors.border, width: 0.5))),
      child: Row(
        children: [
          if (onBack != null)
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: AppColors.foreground),
              ),
            )
          else
            const ShabbirLogo(size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          letterSpacing: -0.4,
                          color: AppColors.foreground),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(subtitle!,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: AppColors.mutedForeground),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ]),
          ),
          if (actions != null)
            Row(
                children: actions!
                    .map((action) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: GestureDetector(
                            onTap: action.onPress,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                  color: action.destructive
                                      ? const Color(0xFFFEE2E2)
                                      : AppColors.secondary,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Icon(action.icon,
                                  size: 18,
                                  color: action.destructive
                                      ? AppColors.destructive
                                      : AppColors.foreground),
                            ),
                          ),
                        ))
                    .toList()),
        ],
      ),
    );
  }
}
