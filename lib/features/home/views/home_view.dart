import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_pro/core/theme/app_colors.dart';
import 'package:quran_pro/features/home/viewmodels/home_view_model.dart';
import 'package:quran_pro/features/home/views/widgets/ayah_card.dart';
import 'package:quran_pro/features/home/views/widgets/essentials_section.dart';
import 'package:quran_pro/features/home/views/widgets/home_bottom_nav.dart';
import 'package:quran_pro/features/home/views/widgets/home_header.dart';
import 'package:quran_pro/features/home/views/widgets/kids_banner.dart';
import 'package:quran_pro/features/home/views/widgets/prayer_hero_card.dart';
import 'package:quran_pro/features/home/views/widgets/streak_card.dart';
import 'package:quran_pro/features/home/views/widgets/today_prayers_strip.dart';

final class HomeView extends GetView<HomeViewModel> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppColors.surface,
    extendBody: true, // content scrolls under the floating nav
    bottomNavigationBar: HomeBottomNav(),
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          HomeHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsetsDirectional.fromSTEB(16, 8, 16, 120),
              child: Column(
                spacing: 20,
                children: [
                  PrayerHeroCard(),
                  TodayPrayersStrip(),
                  AyahCard(),
                  StreakCard(),
                  EssentialsSection(),
                  KidsBanner(),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
