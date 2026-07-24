# skillmatch

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Chatbot API setup

1. Go to [backend/.env.example](backend/.env.example) and create `backend/.env`.
2. Add your key:

	```env
	OPENAI_API_KEY=your_key_here
	PORT=5000
	```

3. Start backend:

	```bash
	cd backend
	npm start
	```

4. Run Flutter app as usual.

Optional: override API URL when needed:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:5000
```
