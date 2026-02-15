import 'package:flutter/material.dart';
import '../../models/tool_model.dart';
import '../../widgets/home/tool_card.dart';
import '../../widgets/home/search_bar_widget.dart';
import '../../widgets/responsive/responsive_builder.dart';

/// Home screen displaying all available tools
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  
  List<Tool> get _filteredTools {
    if (_searchQuery.isEmpty) {
      return ToolsData.allTools;
    }
    
    final query = _searchQuery.toLowerCase();
    return ToolsData.allTools.where((tool) {
      return tool.name.toLowerCase().contains(query) ||
             tool.description.toLowerCase().contains(query) ||
             tool.category.displayName.toLowerCase().contains(query);
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.getHorizontalPadding(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/icon/app_icon.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 12),
            const Text('ToolBox Pro', 
              style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: SearchBarWidget(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Tools grid
          Expanded(
            child: _filteredTools.isEmpty
                ? _buildEmptyState()
                : _buildToolsGrid(horizontalPadding),
          ),
        ],
      ),
    );
  }
  
  Widget _buildToolsGrid(double padding) {
    final columns = Responsive.getGridColumns(context);
    
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _filteredTools.length,
      itemBuilder: (context, index) {
        return ToolCard(tool: _filteredTools[index]);
      },
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No tools found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
