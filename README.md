# LocalSend

Cross-platform Flutter application for file and message transfer between devices over a local area network (LAN)

The goal of the project is to enable easy transfer of messages between nearby devices without relying on online communicators or physical cables. While other solutions, such as Android's Quick Share offer similar service, they usually don't support Linux natively, while this project does.

The project was developed for a Flutter course on Warsaw University of Technology.

## Features
- Send and receive text messages over LAN
- Transfer files between devices
- Easy detection of nearby devices
- Android and Linux support
- Adjustable color theme
- Favorite devices and custom names
- English and Polish localization
- Online indicators

## Networking
The application detects nearby devices using UDP broadcast, while connection between two devices is handled by TCP. The app saves added devices between sessions and checks whether UDP broadcast detects them in order to determine if they are currently reachable. For each sent message, the app opens a TCP socket which connects to the TCP server of the recipient, sends the message with the metadata and closes the socket.

The networking layer was implemented and tested manually with real devices, including communication between different supported platforms.

## Screenshots 
TODO

## Technologies
- Flutter
- Dart
- LAN networking
- Android
- Linux
- Kotlin

## Running
TODO

## AI disclosure
ChatGPT and GitHub Copilot were used during development, primarily for code assistance and documentation. The application architecture and functionality was designed by me. The networking layer was manually designed, implemented and debugged by me, including message structure and networking scheme.
