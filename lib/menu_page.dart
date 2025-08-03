import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/ascii/ascii_logo.dart';
import 'pages/start_program_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int? selectedOption;

  void _selectOption(int option) {
    setState(() {
      selectedOption = option;
    });
  }

  void _executeOption() {
    if (selectedOption != null) {
      switch (selectedOption) {
        case 1:
          print('Start Program selected');
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const StartProgramPage()));
          break;
        case 2:
          print('Settings selected');
          // Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
          break;
        case 3:
          print('Exit selected');
          // SystemNavigator.pop(); // Voor echte exit
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _executeOption,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // WUNEO ASCII Art Logo
              const AsciiLogo(fontSize: 6),
              const SizedBox(height: 20),
              Text(
                'WUNEO MENU',
                style: GoogleFonts.pressStart2p(
                  color: Colors.grey[400],
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => _selectOption(1),
                child: Text(
                  '1. Start Program',
                  style: GoogleFonts.pressStart2p(
                    color:
                        selectedOption == 1 ? Colors.green : Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _selectOption(2),
                child: Text(
                  '2. Settings',
                  style: GoogleFonts.pressStart2p(
                    color:
                        selectedOption == 2 ? Colors.green : Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _selectOption(3),
                child: Text(
                  '3. Exit',
                  style: GoogleFonts.pressStart2p(
                    color:
                        selectedOption == 3 ? Colors.green : Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Select option: ${selectedOption ?? ''}',
                style: GoogleFonts.pressStart2p(
                  color: Colors.grey[400],
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Tap screen to execute',
                style: GoogleFonts.pressStart2p(
                  color: Colors.grey[600],
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
