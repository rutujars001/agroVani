import 'package:flutter/material.dart';

class BazaarScreen extends StatelessWidget {
  const BazaarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1E7),

      body: SafeArea(
        child: Column(
          children: [

            /// HEADER
            Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [

                  /// ✅ FIXED BACK BUTTON
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(width: 5),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("सोलापूर बाजारभाव",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text("सोलापूर कृषी उत्पन्न बाजार समिती",
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),

                  const CircleAvatar(
                    radius: 22,
                    backgroundImage:
                    AssetImage("assets/images/farmer.png"),
                  )
                ],
              ),
            ),

            const SizedBox(height: 15),

            /// VOICE CARD
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7D9),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 5)
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: const [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Color(0xFF2E7D32),
                        child: Icon(Icons.mic,
                            color: Colors.white, size: 28),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Text("आवाजात विचारा",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "आज सोलापुरमध्ये डाळिंबचा भाव काय आहे?",
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 15),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Colors.deepOrange],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mic, color: Colors.white),
                        SizedBox(width: 5),
                        Text("भाव विचारण्यासाठी टॅप करा",
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 15),

            /// MARKET TAG
            Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 8, horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.green.shade800,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text("बाजार समिती: सोलापूर",
                  style: TextStyle(color: Colors.white)),
            ),

            const SizedBox(height: 10),

            /// LIST HEADER
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("आजचे प्रमुख बाजारभाव",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("प्रति क्विंटल दर",
                      style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// PRICE LIST
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  buildItem("डाळिंब", "उत्तम प्रती", "₹ 2,850", true, "150",
                      "assets/images/img.png"),
                  buildItem("कांदा", "मध्यम प्रती", "₹ 1,200", false, "50",
                      "assets/images/img_1.png"),
                  buildItem("ज्वारी", "हायब्रिड", "₹ 3,400", true, "100",
                      "assets/images/img_2.png"),
                  buildItem("मका", "लोकल प्रती", "₹ 2,400", true, "80",
                      "assets/images/img_3.png"),
                ],
              ),
            ),

            /// FOOTER
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.green.shade900,
              child: const Text(
                "टीप: हे दर फक्त माहितीसाठी आहेत.",
                style: TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
      ),
    );
  }

  /// ITEM CARD
  static Widget buildItem(String name, String type, String price, bool isUp,
      String diff, String image) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5)
        ],
      ),
      child: Row(
        children: [
          Image.asset(image, height: 40, width: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style:
                      const TextStyle(fontWeight: FontWeight.bold)),
                  Text(type,
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 12))
                ]),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price,
                  style:
                  const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Icon(
                    isUp
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: isUp ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  Text(diff,
                      style: TextStyle(
                          color:
                          isUp ? Colors.green : Colors.red)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}