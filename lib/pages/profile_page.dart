import 'package:ripto/constants/color_constants.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final peerId, peerAvatar, peerUsername, peerName, peerAbout;
  const ProfilePage(
      {super.key,
      required this.peerId,
      this.peerAvatar,
      this.peerUsername,
      this.peerName,
      this.peerAbout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
          child: Column(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20, right: 15, top: 15),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                        margin: const EdgeInsets.all(20),
                        child: peerAvatar.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.network(
                                  peerAvatar,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                  errorBuilder: (context, object, stackTrace) {
                                    return const Icon(
                                      Icons.account_circle,
                                      size: 100,
                                      color: ColorConstants.greyColor,
                                    );
                                  },
                                  loadingBuilder: (BuildContext context,
                                      Widget child,
                                      ImageChunkEvent? loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return SizedBox(
                                      width: 100,
                                      height: 100,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: ColorConstants.themeColor,
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.account_circle,
                                size: 90,
                                color: ColorConstants.greyColor,
                              )),
                    SizedBox(
                      width: 20,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          peerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 27),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '@$peerUsername',
                          style: const TextStyle(fontSize: 17),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  //crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      checkAbout(peerAbout),
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      )),
    );
  }

  checkAbout(peerAbout) {
    if (peerAbout == null || peerAbout == '' || peerAbout == ' ') {
      return 'Hey! there is nothing...';
    } else {
      return peerAbout;
    }
  }
}
