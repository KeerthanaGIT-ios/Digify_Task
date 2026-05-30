# 🎬 Movie Discovery Platform

A modern Flutter application for discovering movies with real-time content management powered by Firebase Firestore.

## 🚀 Features

* Browse movies with beautiful UI
* Movie details screen with poster, overview, genres, and ratings
* Optional video trailer playback
* Favorites management
* Real-time Firestore updates
* Admin Dashboard

  * Add new movies
  * Edit existing movies
  * Delete movies
* Firebase-backed dynamic content
* Responsive design
* Loading and error states

## 🏗️ Architecture

The application follows a feature-based architecture using Riverpod for state management.

```text
lib/
├── features/
│   ├── home/
│   ├── movie_details/
│   ├── favorites/
│   └── admin/
├── models/
├── services/
├── providers/
├── widgets/
└── core/
```

## 🛠️ Tech Stack

* Flutter
* Dart
* Riverpod
* Firebase Core
* Cloud Firestore
* Go Router
* Video Player
* Shimmer

## 📱 Screenshots

### Home Screen

<img width="1080" height="2400" alt="home" src="https://github.com/user-attachments/assets/0c30c3f0-c4d6-4350-b3f1-ff412ba2e840" />


### Movie Details

![Details](screenshots/details.png)

### Admin Dashboard

![Admin](screenshots/admin.png)

### Add Movie Screen

![Add Movie](screenshots/add_movie.png)

## 🔥 Firebase Integration

* Cloud Firestore acts as the single source of truth.
* Movies are streamed in real time.
* Admin updates instantly reflect on the Home screen.
* Supports optional video trailer URLs.

## 🎯 Problem Solving Highlights

* Migrated from static JSON data to Firestore.
* Implemented real-time UI updates using Firestore streams.
* Added fallback image/video handling.
* Built an in-app admin dashboard instead of a separate web portal.
* Designed scalable feature-based architecture.

## 📦 Installation

```bash
git clone <repository-url>
cd DigiFyce_Task
flutter pub get
flutter run
```

## 👩‍💻 Developer

Keerthana G

* Flutter Developer
* iOS Developer

GitHub: https://github.com/KeerthanaGIT-ios

