# HydroMate – Smart Water Bottle with Hydration Monitoring

Hydromate is an IoT-based smart water bottle designed to monitor real-time water levels, provide hydration reminders through voice alerts, and display hydration status on a mobile application. The system helps users maintain healthy hydration habits using ultrasonic sensing, embedded processing, and wireless communication.

---

## Features

- Real-time water level measurement using ultrasonic sensor  
- ESP32-based embedded processing and wireless communication  
- Voice-based hydration reminders using JQ6500 module and speaker  
- Refill alert when bottle becomes empty  
- Mobile application to display water level percentage  
- User-configurable reminder intervals  
- Hygienic non-contact sensing method  

---

## Hardware Components

- ESP32 Microcontroller  
- Ultrasonic Sensor (HC-SR04)  
- JQ6500 Voice Playback Module  
- Speaker Module  
- USB Power and Data Cable  
- Smart Bottle Enclosure  

---

## Software Requirements

- Arduino IDE (for ESP32 firmware)  
- Embedded C / Arduino C  
- Flutter (Mobile Application)  
- MQTT Protocol for communication  
- Android OS (for mobile app testing)  

---

## System Architecture

The Hydromate system consists of three layers:

1. **Sensing Layer** – Ultrasonic sensor measures water level.  
2. **Processing & Communication Layer** – ESP32 processes data and manages reminders.  
3. **Application Layer** – Mobile app displays hydration information and alerts.

---

## Firmware Execution Flow

1. Initialize ESP32 and peripherals  
2. Trigger ultrasonic sensor and measure distance  
3. Calculate water level percentage  
4. Check for empty bottle condition  
5. Verify reminder interval timing  
6. Trigger voice alert if required  
7. Transmit data to mobile application  
8. Repeat the process continuously  

---

## Mobile Application (mqtt_ser)

### mqtt_ser – Flutter Application

This Flutter application acts as the mobile interface for the Hydromate smart bottle. It receives real-time water-level data via MQTT, displays hydration status, and delivers notifications to the user.

### Getting Started

This project is a starting point for a Flutter application.

### Helpful Resources

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)  
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)  

For help getting started with Flutter development, view the  
[online documentation](https://docs.flutter.dev/), which offers tutorials,  
samples, guidance on mobile development, and a full API reference.

---

## How to Run the Project

### Firmware Setup (ESP32)

1. Install Arduino IDE  
2. Install ESP32 board package  
3. Connect ESP32 via USB cable  
4. Open firmware source code  
5. Upload the code to ESP32  

### Mobile App Setup (Flutter – mqtt_ser)

1. Install Flutter SDK  
2. Navigate to `mqtt_ser` project folder  
3. Run `flutter pub get`  
4. Connect Android device or emulator  
5. Run `flutter run`  

---

## Testing

- Unit Testing of sensors, ESP32, and voice module  
- Integration Testing of hardware–software communication  
- System Testing for real-time operation and alerts  
- Acceptance Testing for user experience and reliability  

---

