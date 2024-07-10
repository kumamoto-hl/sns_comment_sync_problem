# sns_comment_sync_problem

This repository was created to experiment and demonstrate whether multiple models, which should be considered identical, can be managed and retained as a single in-memory hash DB on the client side.

## Getting Started

It includes a server-side program for validation. It runs locally using Node.js and SQLite, achieving minimal functionality.

To run:

```
cd server
npm install
node server.js
```

For the client side, simply run the following in the root directory.​

```dart
flutter pub get
flutter run
```