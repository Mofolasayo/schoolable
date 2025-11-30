import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:schoolable/app/app.locator.dart';
import 'package:schoolable/app/app.router.dart';
import 'package:stacked_services/stacked_services.dart';

class OnboardingSlide {
  OnboardingSlide({
    required this.title,
    required this.description,
    required this.imagePath,
  });

  final String title;
  final String description;
  final String imagePath;
}

class OnboardingViewModel extends BaseViewModel {
  final _nav = locator<NavigationService>();

  final PageController controller = PageController();
  final slides = <OnboardingSlide>[
    OnboardingSlide(
      title: 'Track tasks & KPIs',
      description:
          'See assigned work, mark tasks done, and watch your performance update in real time.',
      imagePath: 'assets/images/onboarding1.jpg',
    ),
    OnboardingSlide(
      title: 'Smart attendance check-in',
      description:
          'Tap once to capture selfie + GPS so managers can trust the record without friction.',
      imagePath: 'assets/images/onboarding2.jpg',
    ),
    OnboardingSlide(
      title: 'Stay aligned with updates',
      description:
          'Chat with your team, read announcements, and never miss the next action item.',
      imagePath: 'assets/images/onboarding3.jpg',
    ),
  ];

  int currentPage = 0;
  bool get isLastPage => currentPage == slides.length - 1;

  void updatePage(int index) {
    currentPage = index;
    rebuildUi();
  }

  void next() {
    if (isLastPage) {
      _nav.replaceWithLoginView();
    } else {
      controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void skip() {
    _nav.replaceWithLoginView();
  }
}
