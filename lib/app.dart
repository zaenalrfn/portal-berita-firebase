import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'providers/auth_provider.dart';
import 'providers/news_provider.dart';

import 'screens/add_news_page.dart';
import 'screens/edit_news_page.dart';
import 'screens/my_news_page.dart';
import 'screens/profile_page.dart';
import 'screens/news_detail_page.dart';
import 'providers/bookmark_provider.dart';
import 'screens/bookmarks_page.dart';
import 'screens/main_page.dart';

import 'providers/theme_provider.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<AuthProvider, BookmarkProvider>(
          create: (_) => BookmarkProvider(),
          update: (ctx, auth, previous) {
            final provider = previous ?? BookmarkProvider();
            provider.setUid(auth.user?.id);
            return provider;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Portal Berita',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: MainPage(),
            routes: {
              '/add': (_) => AddNewsPage(),
              '/mynews': (_) => MyNewsPage(),
              '/profile': (_) => ProfilePage(),
              '/bookmarks': (_) => BookmarksPage(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/detail') {
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => NewsDetailPage(newsId: args['id']),
                );
              }
              if (settings.name == '/edit_news') {
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (_) => EditNewsPage(
                    newsId: args['id'],
                    currentTitle: args['title'],
                    currentContent: args['content'],
                    currentCoverUrl: args['coverUrl'],
                  ),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
