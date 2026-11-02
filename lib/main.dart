import 'package:flutter/material.dart';

void main() {
  runApp(const StrideApp());
}

class StrideApp extends StatelessWidget {
  const StrideApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0B0D12);
    const surface = Color(0xFF151923);
    const accent = Color(0xFF8B7CFF);

    return MaterialApp(
      title: 'Stride',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
          surface: surface,
        ),
        useMaterial3: true,
      ),
      home: const StrideHomePage(),
    );
  }
}

class StrideHomePage extends StatelessWidget {
  const StrideHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            _StrideMark(),
            SizedBox(width: 10),
            Text('Stride', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        backgroundColor: const Color(0xFF0B0D12),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const _StatusPanel(),
          const SizedBox(height: 24),
          Text('Your library', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          const _EmptyLibrary(),
          const SizedBox(height: 24),
          Text('Runtime components',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          const _ComponentTile(
            title: 'APK inspection',
            detail: 'Native package and ELF analysis foundations imported',
            state: 'Foundation',
          ),
          const _ComponentTile(
            title: 'Android runtime',
            detail: 'ART, JNI and framework integration are not connected yet',
            state: 'Not ready',
          ),
          const _ComponentTile(
            title: 'Graphics and audio',
            detail: 'iOS platform bridges are planned',
            state: 'Planned',
          ),
          const SizedBox(height: 24),
          const Text(
            'Stride is an experimental translation-layer project. '
            'APK execution is not available in this build.',
            style: TextStyle(color: Color(0xFF9AA3B2), height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _StrideMark extends StatelessWidget {
  const _StrideMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF8B7CFF), width: 2.2),
      ),
      child: const Center(
        child: Text(
          'S',
          style: TextStyle(
            color: Color(0xFFB8AEFF),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151923),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF282E3B)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TRANSLATION LAYER',
              style: TextStyle(
                color: Color(0xFFB8AEFF),
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              )),
          SizedBox(height: 10),
          Text(
            'Building the native runtime',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 7),
          Text(
            'No Android VM. No full Android OS. Native arm64 compatibility is '
            'the target.',
            style: TextStyle(color: Color(0xFF9AA3B2), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF151923),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF282E3B)),
      ),
      child: const Column(
        children: [
          Icon(Icons.android_rounded, size: 34, color: Color(0xFF777F91)),
          SizedBox(height: 10),
          Text('No apps imported'),
          SizedBox(height: 5),
          Text(
            'APK importing will be connected after the package pipeline is integrated.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9AA3B2), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ComponentTile extends StatelessWidget {
  const _ComponentTile({
    required this.title,
    required this.detail,
    required this.state,
  });

  final String title;
  final String detail;
  final String state;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF151923),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF282E3B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.memory_rounded, color: Color(0xFFB8AEFF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0xFF9AA3B2),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            state,
            style: const TextStyle(
              color: Color(0xFFB8AEFF),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
