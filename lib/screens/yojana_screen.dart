import 'package:flutter/material.dart';

class YojanaScreen extends StatefulWidget {
  const YojanaScreen({super.key});

  @override
  State<YojanaScreen> createState() => _YojanaScreenState();
}

class _YojanaScreenState extends State<YojanaScreen> {
  final Color darkGreen = const Color(0xFF2E7D32);

  final List<Map<String, String>> yojanaList = [
    {
      "title": "प्रधानमंत्री किसान योजना",
      "subtitle": "₹6000 वार्षिक मदत",
      "details":
      "ही योजना लहान व मध्यम शेतकऱ्यांना दरवर्षी ₹6000 आर्थिक मदत देते. ही रक्कम थेट बँक खात्यात जमा होते.",
      "image": "assets/images/yojana1.png"
    },
    {
      "title": "महाडीबीटी यांत्रिकीकरण",
      "subtitle": "ट्रॅक्टर व उपकरण अनुदान",
      "details":
      "या योजनेद्वारे ट्रॅक्टर, शेती उपकरणे आणि यांत्रिकीकरणासाठी सरकारकडून अनुदान दिले जाते.",
      "image": "assets/images/yojana2.png"
    },
    {
      "title": "ठिबक सिंचन योजना",
      "subtitle": "सिंचनासाठी सबसिडी",
      "details":
      "ही योजना शेतकऱ्यांना ठिबक सिंचनासाठी आर्थिक मदत देते.",
      "image": "assets/images/yojana3.png"
    },
    {
      "title": "पीक विमा योजना",
      "subtitle": "नुकसान भरपाई संरक्षण",
      "details":
      "नैसर्गिक आपत्तीमुळे झालेले नुकसान भरून काढण्यासाठी ही योजना मदत करते.",
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
      backgroundColor: Colors.green.shade100,
      appBar: AppBar(
        backgroundColor: darkGreen,
        title: const Text("शासकीय योजना"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// SEARCH BAR
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "योजना शोधा...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            /// VOICE BUTTON
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: darkGreen,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, color: Colors.white, size: 28),
                  SizedBox(width: 10),
                  Text(
                    "योजना विचारण्यासाठी बोला",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            /// YOJANA LIST
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: yojanaList.length,
              itemBuilder: (context, index) {
                return buildCard(index);
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// CARD UI
  Widget buildCard(int index) {
    final item = yojanaList[index];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// IMAGE TOP (FIXED HEIGHT)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
            child: SizedBox(
              height: 150, // fixed height
              width: double.infinity,
              child: Image.asset(
                item["image"]!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),

          /// TEXT CONTENT
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TITLE
                Text(
                  item["title"]!,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                /// SUBTITLE
                Text(
                  item["subtitle"]!,
                  style: const TextStyle(color: Colors.black54),
                ),

                const SizedBox(height: 12),

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
                        backgroundColor: Colors.white,
                        foregroundColor: darkGreen,
                        side: BorderSide(color: darkGreen),
                      ),
                      child: const Text("अधिक वाचा"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: darkGreen,
                        side: BorderSide(color: darkGreen),
                      ),
                      child: const Text("अर्ज करा"),
                    ),
                  ],
                ),

                /// DETAILS
                if (expanded[index]) ...[
                  const SizedBox(height: 12),
                  Text(
                    item["details"]!,
                    style: const TextStyle(fontSize: 14),
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