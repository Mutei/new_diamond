import 'package:diamond_host_admin/widgets/search_text_form_field.dart';
import 'package:flutter/material.dart';
import '../constants/restaurant_options.dart';
import '../constants/styles.dart';
import '../localization/language_constants.dart';

class HotelFilterDialog extends StatefulWidget {
  final Map<String, dynamic> initialFilterState;

  const HotelFilterDialog({
    Key? key,
    required this.initialFilterState,
  }) : super(key: key);

  @override
  _HotelFilterDialogState createState() => _HotelFilterDialogState();
}

class _HotelFilterDialogState extends State<HotelFilterDialog> {
  late Map<String, dynamic> localFilterState;
  late TextEditingController typeSearchController;
  late List<String> filteredTypeOptions;

  @override
  void initState() {
    super.initState();
    localFilterState = Map<String, dynamic>.from(widget.initialFilterState);
    typeSearchController = TextEditingController();
    typeSearchController.addListener(_filterTypeOptions);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize filteredTypeOptions after the context is available
    filteredTypeOptions = _getLocalizedOptions();
  }

  @override
  void dispose() {
    typeSearchController.removeListener(_filterTypeOptions);
    typeSearchController.dispose();
    super.dispose();
  }

  List<String> _getLocalizedOptions() {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return restaurantOptions
        .map((e) => isArabic ? e['labelAr'] as String : e['label'] as String)
        .toList();
  }

  void _filterTypeOptions() {
    final query = typeSearchController.text.toLowerCase();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    setState(() {
      if (query.isNotEmpty) {
        filteredTypeOptions = restaurantOptions
            .map(
                (e) => isArabic ? e['labelAr'] as String : e['label'] as String)
            .where((label) => label.toLowerCase().contains(query))
            .toList();
      } else {
        filteredTypeOptions = _getLocalizedOptions();
      }
    });
  }

  void _clearFilters() {
    setState(() {
      localFilterState['entry'].clear();
      localFilterState['additionals'].clear();
      localFilterState['music'] = false;
      localFilterState['valet'] = null;
      localFilterState['kidsArea'] = false;
      localFilterState['swimmingPool'] = false;
      localFilterState['barber'] = false;
      localFilterState['massage'] = false;
      localFilterState['gym'] = false;
      localFilterState['isThereBreakfastLounge'] = false;
      localFilterState['isThereDinnerLounge'] = false;
      localFilterState['isThereLaunchLounge'] = false;
      typeSearchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16.0,
        left: 16.0,
        right: 16.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              getTranslated(context, "Filters"),
              style: kTeritary,
            ),
            const SizedBox(height: 10),
            _buildFilterSection(
              context,
              "Entry",
              localFilterState['entry'],
              [
                "Single",
                "Double",
                "Suite",
                "Hotel Apartments",
                "Grand Suite",
                "Business Suite"
              ],
            ),
            SwitchListTile(
              title: Text(getTranslated(context, "Is there Swimming Pool?")),
              value: localFilterState['swimmingPool'] ?? false,
              onChanged: (value) {
                setState(() {
                  localFilterState['swimmingPool'] = value;
                  if (!value) {
                    // Reset Valet with Fees when valet service is turned off
                    localFilterState['HasSwimmingPool'] = false;
                  }
                });
              },
            ),
            SwitchListTile(
              title: Text(getTranslated(context, "Is there Barber?")),
              value: localFilterState['barber'] ?? false,
              onChanged: (value) {
                setState(() {
                  localFilterState['barber'] = value;
                  if (!value) {
                    // Reset Valet with Fees when valet service is turned off
                    localFilterState['HasBarber'] = false;
                  }
                });
              },
            ),
            SwitchListTile(
              title: Text(getTranslated(context, "Is there Massage?")),
              value: localFilterState['massage'] ?? false,
              onChanged: (value) {
                setState(() {
                  localFilterState['massage'] = value;
                  if (!value) {
                    // Reset Valet with Fees when valet service is turned off
                    localFilterState['HasMassage'] = false;
                  }
                });
              },
            ),
            SwitchListTile(
              title: Text(getTranslated(context, "Is there Gym?")),
              value: localFilterState['gym'] ?? false,
              onChanged: (value) {
                setState(() {
                  localFilterState['gym'] = value;
                  if (!value) {
                    // Reset Valet with Fees when valet service is turned off
                    localFilterState['HasGym'] = false;
                  }
                });
              },
            ),
            SwitchListTile(
              title: Text(getTranslated(context, "Valet Service")),
              value: localFilterState['valet'] ?? false,
              onChanged: (value) {
                setState(() {
                  localFilterState['valet'] = value;
                  if (!value) {
                    // Reset Valet with Fees when valet service is turned off
                    localFilterState['valetWithFees'] = false;
                  }
                });
              },
            ),
            if (localFilterState['valet'] == true)
              SwitchListTile(
                title: Text(getTranslated(context, "Valet with Fees")),
                value: localFilterState['valetWithFees'] ?? false,
                onChanged: (value) {
                  setState(() {
                    localFilterState['valetWithFees'] = value;
                  });
                },
              ),
            SwitchListTile(
              title:
                  Text(getTranslated(context, "Is there a breakfast Lounge?")),
              value: localFilterState['isThereBreakfastLounge'] ?? false,
              onChanged: (value) {
                setState(() {
                  localFilterState['isThereBreakfastLounge'] = value;
                  if (!value) {
                    // Reset Valet with Fees when valet service is turned off
                    localFilterState['IsThereBreakfastLounge'] = false;
                  }
                });
              },
            ),
            SwitchListTile(
              title: Text(getTranslated(context, "Is there a launch Lounge?")),
              value: localFilterState['isThereLaunchLounge'] ?? false,
              onChanged: (value) {
                setState(() {
                  localFilterState['isThereLaunchLounge'] = value;
                  if (!value) {
                    // Reset Valet with Fees when valet service is turned off
                    localFilterState['isThereLaunchLounge'] = false;
                  }
                });
              },
            ),
            SwitchListTile(
              title: Text(getTranslated(context, "Is there a dinner Lounge?")),
              value: localFilterState['isThereDinnerLounge'] ?? false,
              onChanged: (value) {
                setState(() {
                  localFilterState['isThereDinnerLounge'] = value;
                  if (!value) {
                    // Reset Valet with Fees when valet service is turned off
                    localFilterState['isThereDinnerLounge'] = false;
                  }
                });
              },
            ),
            const SizedBox(height: 20),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    String title,
    List<String> selectedOptions,
    List<String> options,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslated(context, title),
          style: kSecondaryStyle,
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option);
            return ChoiceChip(
              label: Text(getTranslated(context, option)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedOptions.add(option);
                  } else {
                    selectedOptions.remove(option);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
          ),
          onPressed: _clearFilters,
          child: Text(
            getTranslated(context, "Clear Filters"),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
          ),
          onPressed: () {
            Navigator.pop(context, localFilterState);
          },
          child: Text(
            getTranslated(context, "Apply"),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
