    import 'package:flutter/material.dart';
    import 'screens/home_screen.dart'; // We will create this file next

    void main() {
      runApp(const MyApp());
    }

    class MyApp extends StatelessWidget {
      const MyApp({super.key});

      // This widget is the root of your application.
      @override
      Widget build(BuildContext context) {
        return MaterialApp(
          title: 'Card Scanner',
          // Removes the debug banner from the top right corner
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 12, 14, 113)),
            useMaterial3: true,
          ),
          // This sets our HomeScreen as the first page the user sees.
          home: const HomeScreen(),
        );
      }
    }
    
