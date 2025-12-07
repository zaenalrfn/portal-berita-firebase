import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/news_provider.dart';
import '../widgets/news_card.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_dialog.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isGridView = false;
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newsProv = Provider.of<NewsProvider>(context, listen: false);
      if (newsProv.items.isEmpty && !newsProv.loading) {
        newsProv.fetchFirstPage();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTimeAgo(dynamic createdAt) {
    if (createdAt == null) return '';
    if (createdAt is! Timestamp) return '';
    final dt = createdAt.toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat.yMMMd().format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final newsProv = Provider.of<NewsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    // Filter items locally
    final filteredItems = _searchQuery.isEmpty
        ? newsProv.items
        : newsProv.items.where((news) {
            final title = news.title.toLowerCase();
            return title.contains(_searchQuery);
          }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: _isSearchVisible
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search news...',
                  border: InputBorder.none,
                ),
              )
            : Text(
                'Portal',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchVisible ? Icons.close : Icons.search,
              color: Colors.black87,
            ),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                if (!auth.isAuthenticated) {
                  showDialog(context: context, builder: (_) => AuthDialog());
                } else {
                  Navigator.pushNamed(context, '/profile');
                }
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.deepOrange.shade100,
                backgroundImage: (user?.photoUrl != null)
                    ? NetworkImage(user!.photoUrl!)
                    : null,
                child: (user?.photoUrl == null)
                    ? Icon(Icons.person, color: Colors.deepOrange, size: 18)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: newsProv.loading && newsProv.items.isEmpty
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => newsProv.fetchFirstPage(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            final name =
                                auth.user?.name?.split(' ').first ?? 'Guest';
                            return Text(
                              'Welcome, $name!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Here's what's happening today.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 16),
                        // View Toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.list),
                                    color: !_isGridView
                                        ? Colors.blue
                                        : Colors.grey,
                                    onPressed: () =>
                                        setState(() => _isGridView = false),
                                    tooltip: 'List View',
                                    constraints: BoxConstraints(
                                      minHeight: 36,
                                      minWidth: 36,
                                    ),
                                    padding: EdgeInsets.zero,
                                    iconSize: 20,
                                  ),
                                  Container(
                                    width: 1,
                                    height: 20,
                                    color: Colors.grey[400],
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.grid_view),
                                    color: _isGridView
                                        ? Colors.blue
                                        : Colors.grey,
                                    onPressed: () =>
                                        setState(() => _isGridView = true),
                                    tooltip: 'Grid View',
                                    constraints: BoxConstraints(
                                      minHeight: 36,
                                      minWidth: 36,
                                    ),
                                    padding: EdgeInsets.zero,
                                    iconSize: 20,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Content List/Grid
                  Expanded(
                    child: filteredItems.isEmpty
                        ? Center(child: Text("No items found"))
                        : _isGridView
                        ? GridView.builder(
                            padding: EdgeInsets.all(16),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.75,
                                ),
                            itemCount:
                                filteredItems.length +
                                (newsProv.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == filteredItems.length) {
                                if (_searchQuery.isNotEmpty) return SizedBox();
                                Future.microtask(
                                  () => newsProv.fetchNextPage(),
                                );
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final news = filteredItems[index];
                              return _buildGridItem(news);
                            },
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount:
                                filteredItems.length +
                                (newsProv.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == filteredItems.length) {
                                if (_searchQuery.isNotEmpty) return SizedBox();
                                Future.microtask(
                                  () => newsProv.fetchNextPage(),
                                );
                                return Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final news = filteredItems[index];
                              return _buildListItem(news);
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!auth.isAuthenticated) {
            showDialog(context: context, builder: (_) => AuthDialog());
            return;
          }
          Navigator.pushNamed(context, '/add');
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildListItem(dynamic news) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () =>
            Navigator.pushNamed(context, '/detail', arguments: {'id': news.id}),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: news.coverUrl != null
                    ? Image.network(
                        news.coverUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: Icon(Icons.image, color: Colors.grey),
                      ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news.authorName,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      news.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      news.content.replaceAll('\n', ' '),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    Text(
                      _formatTimeAgo(Timestamp.fromDate(news.createdAt)),
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(dynamic news) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            Navigator.pushNamed(context, '/detail', arguments: {'id': news.id}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: news.coverUrl != null
                  ? Image.network(
                      news.coverUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Center(child: Icon(Icons.image)),
                    ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatTimeAgo(Timestamp.fromDate(news.createdAt)),
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
