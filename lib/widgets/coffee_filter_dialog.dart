import 'package:diamond_host_admin/widgets/search_text_form_field.dart';
import 'package:flutter/material.dart';
import '../constants/restaurant_options.dart';
import '../constants/styles.dart';
import '../localization/language_constants.dart';

class CoffeeFilterDialog extends StatefulWidget {
  final Map<String, dynamic> initialFilterState;

  const CoffeeFilterDialog({
    Key? key,
    required this.initialFilterState,
  }) : super(key: key);

  @override
  _CoffeeFilterDialogState createState() => _CoffeeFilterDialogState();
}

class _CoffeeFilterDialogState extends State<CoffeeFilterDialog> {
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
      localFilterState['typeOfRestaurant'].clear();
      localFilterState['entry'].clear();
      localFilterState['sessions'].clear();
      localFilterState['additionals'].clear();
      localFilterState['music'] = false;
      localFilterState['valet'] = null;
      localFilterState['kidsArea'] = false;
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
              ["Single", "Familial", "mixed"],
            ),
            _buildFilterSection(
              context,
              "Sessions",
              localFilterState['sessions'],
              ["Internal sessions", "External sessions", "Private sessions"],
            ),
            _buildFilterSection(
              context,
              "Additionals",
              localFilterState['additionals'],
              [
                "Is there Hookah?",
                "Is there Buffet?",
                "Is there a dinner buffet?",
                "Is there a lunch buffet?",
                "Is there a breakfast buffet?"
              ],
            ),
            SwitchListTile(
              title: Text(getTranslated(context, "Music")),
              value: localFilterState['music'],
              onChanged: (value) {
                setState(() {
                  localFilterState['music'] = value;
                  if (!value) {
                    // Reset Lstmusic options when music is turned off
                    localFilterState['lstMusic'] = [];
                  }
                });
              },
            ),
            if (localFilterState['music'] == true)
              _buildFilterSection(
                context,
                "List of musics",
                localFilterState['lstMusic'],
                [
                  "singer",
                  "Oud",
                  "DJ",
                ],
              ),
            SwitchListTile(
              title: Text(getTranslated(context, "Kids Area")),
              value: localFilterState['kidsArea'],
              onChanged: (value) {
                setState(() {
                  localFilterState['kidsArea'] = value;
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
