// lib/widgets/filter_dialog.dart

import 'package:flutter/material.dart';
import '../localization/language_constants.dart';
import '../constants/restaurant_options.dart';

class FilterDialog extends StatefulWidget {
  final Map<String, dynamic> initialFilterState;

  const FilterDialog({
    Key? key,
    required this.initialFilterState,
  }) : super(key: key);

  @override
  _FilterDialogState createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late Map<String, dynamic> localFilterState;
  late TextEditingController typeSearchController;
  late List<String> filteredTypeOptions;

  @override
  void initState() {
    super.initState();
    // Initialize local filter state
    localFilterState = Map<String, dynamic>.from(widget.initialFilterState);

    // Initialize search controller for "Type of Restaurant"
    typeSearchController = TextEditingController();

    // Initialize filtered list with all restaurant types
    filteredTypeOptions =
        restaurantOptions.map((e) => e['label'] as String).toList();

    // Add listener to handle search input
    typeSearchController.addListener(_filterTypeOptions);
  }

  @override
  void dispose() {
    typeSearchController.removeListener(_filterTypeOptions);
    typeSearchController.dispose();
    super.dispose();
  }

  void _filterTypeOptions() {
    final query = typeSearchController.text.toLowerCase();
    setState(() {
      if (query.isNotEmpty) {
        filteredTypeOptions = restaurantOptions
            .map((e) => e['label'] as String)
            .where((label) => label.toLowerCase().contains(query))
            .toList();
      } else {
        filteredTypeOptions =
            restaurantOptions.map((e) => e['label'] as String).toList();
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

      // Reset search field
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
            // Header
            Text(
              getTranslated(context, "Filters"),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Type of Restaurant with Search
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getTranslated(context, "Type of Restaurant"),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: typeSearchController,
                  decoration: InputDecoration(
                    labelText: getTranslated(context, "Search"),
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: typeSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              typeSearchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                  ),
                ),
                const SizedBox(height: 10),
                // Horizontally scrollable ChoiceChips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filteredTypeOptions.map((option) {
                      final isSelected =
                          localFilterState['typeOfRestaurant'].contains(option);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(option),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                localFilterState['typeOfRestaurant']
                                    .add(option);
                              } else {
                                localFilterState['typeOfRestaurant']
                                    .remove(option);
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Other Filter Sections
            _buildFilterSection(
              context,
              "Entry",
              localFilterState['entry'],
              ["Single", "Familial", "Mixed"],
            ),
            // _buildFilterSection(
            //   context,
            //   "Sessions",
            //   localFilterState['sessions'],
            //   ["Morning", "Afternoon", "Evening"],
            // ),
            // _buildFilterSection(
            //   context,
            //   "Additionals",
            //   localFilterState['additionals'],
            //   ["Free Wi-Fi", "Outdoor Seating", "Live Sports"],
            // ),
            SwitchListTile(
              title: Text(getTranslated(context, "Music")),
              value: localFilterState['music'],
              onChanged: (value) {
                setState(() {
                  localFilterState['music'] = value;
                });
              },
            ),
            // Add more filters as needed
            const SizedBox(height: 10),

            // Buttons: Clear Filters & Apply
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey, // Clear filters color
                  ),
                  onPressed: _clearFilters,
                  child: Text(getTranslated(context, "Clear Filters")),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, localFilterState);
                  },
                  child: Text(getTranslated(context, "Apply")),
                ),
              ],
            ),
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option);
            return ChoiceChip(
              label: Text(option),
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
}
