# AI Photo Booth

AI Photo Booth is a feature-rich Flutter application that combines real-time face detection with augmented reality (AR) filters. Capture, share, and print your favorite moments with a touch of fun!

## 📸 Features

- **Real-time Face Detection:** Utilizes Google ML Kit to accurately detect faces and landmarks in real-time.
- **Fun AR Filters:** Overlay various filters on your face, including:
  - 🎩 Hat
  - 🎅 Christmas Cap
  - 🏴‍☠️ Eye-Patch
  - 🧔 Beard
- **Interactive Camera Controls:**
  - **Countdown Timer:** Set a delay (5s, 10s, 15s) before capturing.
  - **Gamma Correction:** Adjust image brightness in real-time.
  - **Customizable Overlays:** Fine-tune filter scale, position, and rotation through a hidden side menu.
- **Easy Sharing:** Share your captured and filtered photos instantly with other apps.
- **Bluetooth Thermal Printing:** Print your memories directly to compatible 80mm Bluetooth thermal printers.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>= 2.17.0)
- Android Studio or Xcode
- A physical device (recommended for camera and Bluetooth features)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd face_detection_app
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the app:**
    ```bash
    flutter run
    ```

## 📂 Project Structure

- `lib/main.dart`: Entry point of the application.
- `lib/landing_page.dart`: The home screen with a "Start Session" button.
- `lib/vision_detector_views/`:
  - `face_detector_view.dart`: The core camera and face detection logic.
  - `camera_view.dart` / `detector_view.dart`: Wrappers for camera management.
  - `painters/face_detector_painter.dart`: Custom painter for drawing AR filters on the camera feed.
- `lib/image_preview.dart`: Screen for previewing captured photos, sharing, and printing.
- `lib/face_ar_utils.dart`: Utility class for calculating AR filter positions and angles.
- `assets/`: Contains filter images and assets.

## 🛠️ Technologies Used

- **[Flutter](https://flutter.dev/):** UI framework.
- **[Google ML Kit Face Detection](https://developers.google.com/ml-kit/vision/face-detection):** Real-time face and landmark detection.
- **[Camera](https://pub.dev/packages/camera):** Access to device cameras.
- **[Share Plus](https://pub.dev/packages/share_plus):** For sharing captured images.
- **[Print Bluetooth Thermal](https://pub.dev/packages/print_bluetooth_thermal):** For Bluetooth printing support.
- **[ESC POS Utils Plus](https://pub.dev/packages/esc_pos_utils_plus):** For thermal printer command generation.
- **[Image](https://pub.dev/packages/image):** For image processing and decoding.

## 🔐 Permissions

The app requires the following permissions:
- **Camera:** To capture photos and detect faces.
- **Bluetooth & Location:** To scan for and connect to thermal printers.
- **Storage:** To save and share processed images.

## 🎨 How to Use

1.  Launch the app and tap **"START PHOTO SESSION"**.
2.  Select a filter from the bottom scrollable list.
3.  (Optional) Tap the right-side arrow to open advanced settings for filter adjustment.
4.  Adjust **Gamma** or set a **Timer** using the side buttons.
5.  Tap the **Camera** button to capture.
6.  In the preview screen, use the **Share** button or the **Print** button (ensure your printer is paired via Bluetooth).

---
Developed with ❤️ using Flutter.
