import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../services/cloudinary_service.dart';

class ChatScreen extends StatefulWidget {
  final String receiverName;
  final String receiverId;

  const ChatScreen({
    super.key,
    required this.receiverName,
    required this.receiverId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController controller = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  late AnimationController _bgController;

  String get chatId {
    return currentUser!.uid.compareTo(widget.receiverId) > 0
        ? "${currentUser!.uid}_${widget.receiverId}"
        : "${widget.receiverId}_${currentUser!.uid}";
  }

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    markMessagesSeen();
  }

  @override
  void dispose() {
    _bgController.dispose();
    controller.dispose();
    super.dispose();
  }

  // 🔥 MARK SEEN
  Future<void> markMessagesSeen() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .where("senderId", isEqualTo: widget.receiverId)
        .get();

    for (var doc in snapshot.docs) {
      doc.reference.update({"seen": true});
    }
  }

  // 🔥 TYPING
  void updateTyping(bool isTyping) {
    FirebaseFirestore.instance.collection("chats").doc(chatId).set({
      "typing": isTyping ? currentUser!.uid : null,
    }, SetOptions(merge: true));
  }

  // 🔥 SEND MESSAGE
  void sendMessage() async {
    if (controller.text.trim().isEmpty) return;

    String text = controller.text;

    await FirebaseFirestore.instance
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .add({
      "text": text,
      "senderId": currentUser!.uid,
      "timestamp": FieldValue.serverTimestamp(),
      "seen": false,
    });

    await FirebaseFirestore.instance.collection("chats").doc(chatId).set({
      "lastMessage": text,
      "lastTime": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    controller.clear();
    updateTyping(false);
  }

  // 🔥 SEND IMAGE
  Future<void> sendImage() async {
    final picked =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    File file = File(picked.path);
    String? url = await CloudinaryService.uploadImage(file);
    if (url == null) return;

    await FirebaseFirestore.instance
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .add({
      "image": url,
      "senderId": currentUser!.uid,
      "timestamp": FieldValue.serverTimestamp(),
      "seen": false,
    });

    await FirebaseFirestore.instance.collection("chats").doc(chatId).set({
      "lastMessage": "📷 Photo",
      "lastTime": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true, // ✅ FIX

      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(widget.receiverName),
            const Text(
              "Online",
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Stack(
          children: [
            // 🔥 ANIMATED BACKGROUND
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _bgController,
                builder: (_, __) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.lerp(
                              const Color(0xFF0F2027),
                              const Color(0xFF2C5364),
                              _bgController.value)!,
                          const Color(0xFF203A43),
                          const Color(0xFF000000),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const RepaintBoundary(child: ParticleLayer()),

            Column(
              children: [
                // 🔥 TYPING INDICATOR
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection("chats")
                      .doc(chatId)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData || !snap.data!.exists) {
                      return const SizedBox();
                    }

                    final data = snap.data!.data();

                    if (data?["typing"] == widget.receiverId) {
                      return const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Typing...",
                            style: TextStyle(color: Colors.grey)),
                      );
                    }
                    return const SizedBox();
                  },
                ),

                // 🔥 CHAT LIST
                Expanded(
                  child: StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection("chats")
                        .doc(chatId)
                        .collection("messages")
                        .orderBy("timestamp", descending: true)
                        .snapshots(),

                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data!.docs;

                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index].data();
                          final isMe =
                              msg["senderId"] == currentUser!.uid;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4),
                              child: ClipRRect(
                                borderRadius:
                                BorderRadius.circular(18),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 6, sigmaY: 6),
                                  child: Container(
                                    padding:
                                    const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? Colors.blue
                                          .withOpacity(0.75)
                                          : Colors.white
                                          .withOpacity(0.08),
                                      borderRadius:
                                      BorderRadius.circular(18),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                      children: [
                                        msg.containsKey("image")
                                            ? Image.network(
                                          msg["image"],
                                          width: 200,
                                        )
                                            : Text(
                                          msg["text"] ?? "",
                                          style:
                                          const TextStyle(
                                              color: Colors
                                                  .white),
                                        ),

                                        const SizedBox(height: 4),

                                        Row(
                                          mainAxisSize:
                                          MainAxisSize.min,
                                          children: [
                                            Text(
                                              msg["timestamp"] !=
                                                  null
                                                  ? TimeOfDay.fromDateTime(
                                                  msg["timestamp"]
                                                      .toDate())
                                                  .format(context)
                                                  : "",
                                              style:
                                              const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors
                                                      .white70),
                                            ),
                                            const SizedBox(width: 4),
                                            if (isMe)
                                              Icon(
                                                msg["seen"] ==
                                                    true
                                                    ? Icons.done_all
                                                    : Icons.done,
                                                size: 14,
                                                color: msg["seen"] ==
                                                    true
                                                    ? Colors.blue
                                                    : Colors.white70,
                                              ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // 🔥 INPUT BAR FIXED
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 10,
                      right: 10,
                      bottom:
                      MediaQuery.of(context).viewInsets.bottom >
                          0
                          ? 10
                          : 20,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                            sigmaX: 6, sigmaY: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10),
                          color: Colors.white.withOpacity(0.08),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add,
                                    color: Colors.white),
                                onPressed: sendImage,
                              ),
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  onChanged: (text) {
                                    updateTyping(
                                        text.isNotEmpty);
                                  },
                                  style: const TextStyle(
                                      color: Colors.white),
                                  decoration:
                                  const InputDecoration(
                                    hintText: "Message...",
                                    hintStyle: TextStyle(
                                        color: Colors.grey),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send,
                                    color: Colors.blue),
                                onPressed: sendMessage,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 🔥 PARTICLES
class ParticleLayer extends StatefulWidget {
  const ParticleLayer({super.key});

  @override
  State<ParticleLayer> createState() => _ParticleLayerState();
}

class _ParticleLayerState extends State<ParticleLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  final List<Offset> particles = List.generate(
    20,
        (_) => Offset(Random().nextDouble(), Random().nextDouble()),
  );

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return CustomPaint(
          painter: ParticlePainter(particles, controller.value),
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Offset> particles;
  final double progress;

  ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04);

    for (var p in particles) {
      final dx = (p.dx * size.width + progress * 40) % size.width;
      final dy = (p.dy * size.height + progress * 25) % size.height;

      canvas.drawCircle(Offset(dx, dy), 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}