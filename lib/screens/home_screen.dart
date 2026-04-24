import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String search = "";

  String getChatId(String a, String b) {
    return a.compareTo(b) > 0 ? "${a}_$b" : "${b}_$a";
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.black,

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF2C5364),
              Color(0xFF000000),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: SafeArea(
          child: Column(
            children: [
              // ================= HEADER =================
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Chatu 💬",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.more_vert, color: Colors.white),
                  ],
                ),
              ),

              // ================= SEARCH =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      color: Colors.white.withOpacity(0.08),
                      child: TextField(
                        onChanged: (val) {
                          setState(() {
                            search = val.toLowerCase();
                          });
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          icon: Icon(Icons.search, color: Colors.white70),
                          hintText: "Search chats...",
                          hintStyle: TextStyle(color: Colors.white60),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ================= CHAT LIST =================
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection("users")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    // 🔥 FILTER USERS
                    final users = snapshot.data!.docs.where((doc) {
                      final data = doc.data();
                      return data["uid"] != currentUserId &&
                          (data["name"]
                              ?.toString()
                              .toLowerCase()
                              .contains(search) ??
                              false);
                    }).toList();

                    if (users.isEmpty) {
                      return const Center(
                        child: Text(
                          "No chats yet 🚀",
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index].data();
                        final chatId =
                        getChatId(currentUserId, user["uid"]);

                        return TweenAnimationBuilder(
                          duration:
                          Duration(milliseconds: 200 + index * 40),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 15 * (1 - value)),
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },

                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) => ChatScreen(
                                    receiverName: user["name"],
                                    receiverId: user["uid"],
                                  ),
                                  transitionsBuilder:
                                      (_, anim, __, child) {
                                    return SlideTransition(
                                      position: Tween(
                                        begin: const Offset(1, 0),
                                        end: Offset.zero,
                                      ).animate(anim),
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },

                            child: Container(
                              margin:
                              const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(12),

                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.white.withOpacity(0.05),
                              ),

                              child: Row(
                                children: [
                                  // ================= AVATAR =================
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundImage: NetworkImage(
                                            user["photoUrl"] ?? ""),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          height: 12,
                                          width: 12,
                                          decoration: BoxDecoration(
                                            color: user["isOnline"] == true
                                                ? Colors.green
                                                : Colors.grey,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.black,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(width: 12),

                                  // ================= TEXT =================
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user["name"] ?? "",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),

                                        StreamBuilder<
                                            DocumentSnapshot<
                                                Map<String, dynamic>>>(
                                          stream: FirebaseFirestore.instance
                                              .collection("chats")
                                              .doc(chatId)
                                              .snapshots(),
                                          builder:
                                              (context, chatSnapshot) {
                                            if (!chatSnapshot.hasData ||
                                                !chatSnapshot.data!.exists) {
                                              return const Text(
                                                "Say hi 👋",
                                                style: TextStyle(
                                                    color:
                                                    Colors.white60),
                                              );
                                            }

                                            final data =
                                            chatSnapshot.data!.data()!;

                                            String lastMessage =
                                                data["lastMessage"] ?? "";

                                            // 🔥 TYPING INDICATOR
                                            if (data["typing"] ==
                                                user["uid"]) {
                                              lastMessage = "Typing...";
                                            }

                                            Timestamp? time =
                                            data["lastTime"];

                                            String formattedTime = "";
                                            if (time != null) {
                                              formattedTime =
                                                  TimeOfDay.fromDateTime(
                                                      time.toDate())
                                                      .format(context);
                                            }

                                            return Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    lastMessage,
                                                    maxLines: 1,
                                                    overflow:
                                                    TextOverflow
                                                        .ellipsis,
                                                    style:
                                                    const TextStyle(
                                                        color: Colors
                                                            .white60),
                                                  ),
                                                ),
                                                Text(
                                                  formattedTime,
                                                  style:
                                                  const TextStyle(
                                                    color: Colors.white38,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // ================= FAB =================
      floatingActionButton: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Color(0xFF833AB4),
              Color(0xFFFD1D1D),
              Color(0xFFFCAF45),
            ],
          ),
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () {},
          child: const Icon(Icons.chat, color: Colors.white),
        ),
      ),
    );
  }
}