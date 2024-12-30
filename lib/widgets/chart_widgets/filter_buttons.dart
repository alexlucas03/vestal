import 'package:flutter/material.dart';
import '../../utils/chart_colors.dart';

class FilterButtons extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final bool showUserData;
  final bool showPartnerData;
  final VoidCallback onUserDataToggled;
  final VoidCallback onPartnerDataToggled;
  final bool isPinkPreference;

  const FilterButtons({
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.showUserData,
    required this.showPartnerData,
    required this.onUserDataToggled,
    required this.onPartnerDataToggled,
    required this.isPinkPreference,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTimeFilters(),
        SizedBox(height: 16),
        _buildDataToggleButtons(),
      ],
    );
  }

  Widget _buildTimeFilters() {
    return SizedBox(
      height: 40,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Expanded(child: _buildFilterButton('week')),
            SizedBox(width: 8),
            Expanded(child: _buildFilterButton('month')),
            SizedBox(width: 8),
            Expanded(child: _buildFilterButton('year')),
            SizedBox(width: 8),
            Expanded(child: _buildFilterButton('all')),
          ],
        ),
      ),
    );
  }

  Widget _buildDataToggleButtons() {
    return SizedBox(
      height: 40,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              child: _buildVisibilityButton(
                'You',
                showUserData,
                onUserDataToggled,
                ChartColors.getUserColor(isPinkPreference),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildVisibilityButton(
                'Partner',
                showPartnerData,
                onPartnerDataToggled,
                ChartColors.getPartnerColor(isPinkPreference),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String filter) {
    bool isSelected = selectedFilter == filter;
    return ElevatedButton(
      onPressed: () => onFilterChanged(filter),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.white : Color(0xFF3A4C7A),
        foregroundColor: isSelected ? Color(0xFF3A4C7A) : Colors.white,
        side: BorderSide(
          color: isSelected ? Color(0xFF3A4C7A) : Colors.transparent,
        ),
        padding: EdgeInsets.symmetric(horizontal: 4),
      ),
      child: Text(filter.toUpperCase()),
    );
  }

  Widget _buildVisibilityButton(
    String label,
    bool isSelected,
    VoidCallback onPressed,
    Color color,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.white : Colors.grey[200],
        foregroundColor: isSelected ? color : Colors.grey,
        side: BorderSide(
          color: isSelected ? color : Colors.transparent,
        ),
        padding: EdgeInsets.symmetric(horizontal: 4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? Icons.visibility : Icons.visibility_off,
            size: 20,
            color: isSelected ? color : Colors.grey,
          ),
          SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}