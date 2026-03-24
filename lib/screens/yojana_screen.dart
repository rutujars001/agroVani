import 'package:flutter/material.dart';

class YojanaScreen extends StatefulWidget {
  const YojanaScreen({super.key});

  @override
  State<YojanaScreen> createState() => _YojanaScreenState();
}

class _YojanaScreenState extends State<YojanaScreen> {
  final Color darkGreen = const Color(0xFF2E7D32);
  final Color creamColor = const Color(0xFFF3F1E7);

  final List<Map<String, String>> yojanaList = [
    {
      "title": "प्रधानमंत्री किसान योजना",
      "subtitle": "₹6000 वार्षिक मदत",
      "details":
      "ही योजना लहान व मध्यम शेतकऱ्यांना दरवर्षी ₹6000 आर्थिक मदत देते.",
      "image": "assets/images/yojana1.png"
    },
    {
      "title": "महाडीबीटी यांत्रिकीकरण",
      "subtitle": "ट्रॅक्टर व उपकरण अनुदान",
      "details":
      "या योजनेद्वारे ट्रॅक्टर व उपकरणांसाठी अनुदान दिले जाते.",
      "image": "assets/images/yojana2.png"
    },
    {
      "title": "ठिबक सिंचन योजना",
      "subtitle": "सिंचनासाठी सबसिडी",
      "details": "ठिबक सिंचनासाठी आर्थिक मदत मिळते.",
      "image": "assets/images/yojana3.png"
    },
    {
      "title": "पीक विमा योजना",
      "subtitle": "नुकसान भरपाई",
      "details": "नैसर्गिक आपत्तीमुळे नुकसान भरपाई मिळते.",
      "image": "assets/images/yojana4.png"
    },
  ];

  List<bool> expanded = [];

  @override
  void initState() {
    super.initState();
    expanded = List.generate(yojanaList.length, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamColor, // ✅ UPDATED

      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,
        title: const Text("शासकीय योजना"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            /// SEARCH BAR
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "योजना शोधा...",
                  prefixIcon: Icon(Icons.search, color: darkGreen),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            /// VOICE BUTTON
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: darkGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    "योजना विचारण्यासाठी बोला",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// YOJANA LIST
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: yojanaList.length,
              itemBuilder: (context, index) {
                return buildCard(index);
              },
            ),

            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  /// 📦 COMPACT CARD
  Widget buildCard(int index) {
    final item = yojanaList[index];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// 🔽 SMALL IMAGE
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
            ),
            child: SizedBox(
              height: 110, // ✅ REDUCED HEIGHT
              width: double.infinity,
              child: Image.asset(
                item["image"]!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  "assets/images/placeholder.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          /// TEXT
          Padding(
            padding: const EdgeInsets.all(10), // ✅ REDUCED
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["title"]!,
                  style: TextStyle(
                    fontSize: 15, // ✅ SMALLER
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item["subtitle"]!,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),

                const SizedBox(height: 8),

                /// BUTTONS
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          expanded[index] = !expanded[index];
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        minimumSize: const Size(80, 32), // ✅ SMALL BUTTON
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: const Text("वाचा", style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(80, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        side: BorderSide(color: darkGreen),
                      ),
                      child: Text("अर्ज", style: TextStyle(fontSize: 12, color: darkGreen)),
                    ),
                  ],
                ),

                if (expanded[index]) ...[
                  const SizedBox(height: 8),
                  Text(
                    item["details"]!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}