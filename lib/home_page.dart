import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:outdoor_clothing_picker/core/configs/settings.dart';
import 'package:outdoor_clothing_picker/core/ui/app_page.dart';
import 'package:outdoor_clothing_picker/core/ui/navigation.dart';
import 'package:outdoor_clothing_picker/features/clother/clothing_page.dart';
import 'package:outdoor_clothing_picker/features/clother/weather_viewmodel.dart';
import 'package:outdoor_clothing_picker/features/clother/clothing_viewmodel.dart';
import 'package:outdoor_clothing_picker/features/database_editor/data_visualization_page.dart';
import 'package:outdoor_clothing_picker/features/settings/settings_page.dart';
import 'package:outdoor_clothing_picker/features/settings/settings_viewmodel.dart';
import 'package:provider/provider.dart';

typedef AppPageBuilder = AppPage Function(BuildContext context, NavigationBar? navBar);

/// Parent widget for the real UI pages, managing navigation.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPageIndex = 1; // Initial value is the landing page (in pages variable)
  bool isWideScreen = false;

  late final List<AppPageBuilder> pages = [
    //     (context, navBar) {
    //   final dataRepo = Provider.of<DataRepo>(context, listen: false);
    //   final vm = DataVisualizationViewModel(dataRepo);
    //   return DataVisualizationPage(bottomNavigationBar: navBar, viewModel: vm);
    // },
    (context, navBar) {
      return DataVisualizationPage(bottomNavigationBar: navBar);
    },
    (context, navBar) {
      final weatherVM = WeatherViewModel(weatherRepository: context.read());
      final clothingVM = ClothingViewModel(
        clothingRepository: context.read(),
        weatherViewModel: weatherVM,
      );
      return ClothingPage(bottomNavigationBar: navBar, viewModel: clothingVM);
    },
    (context, navBar) {
      final settingsVM = SettingsViewModel(settingsRepository: context.read());
      return SettingsPage(bottomNavigationBar: navBar, viewModel: settingsVM);
    },
  ];

  void onIndexChanged(int index) {
    setState(() {
      currentPageIndex = index;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kIsWeb) {
      final double width = MediaQuery.of(context).size.width;
      isWideScreen = width > 600;
    } else {
      isWideScreen = MediaQuery.orientationOf(context) == Orientation.landscape;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomNavigationBar = isWideScreen
        ? null
        : buildNavigationBar(context, onIndexChanged, currentPageIndex);
    final page = pages[currentPageIndex](context, bottomNavigationBar);

    // Setting Directionality at this level does not affect widgets such as alert dialogs and
    // MaterialPageRoutes, but most of their contents should not change anyway for left-handed
    // mode, rather, buttons and such should be modified manually
    return Selector<SettingsProvider, TextDirection>(
      selector: (_, p) => p.textDirection,
      builder: (context, textDirection, _) {
        return Directionality(
          textDirection: textDirection,
          child: isWideScreen
              ? Row(
                  children: [
                    buildNavigationRail(context, onIndexChanged, currentPageIndex),
                    Expanded(child: page),
                  ],
                )
              : page,
        );
      },
    );
  }
}
