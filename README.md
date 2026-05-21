# Skill Shift

Skill Shift is a platform to connect and exchange skills!

## Features
- **Real-time Chat**: Connect with users seamlessly.
- **Push Notifications**: Receive instant push notifications powered by Vercel Serverless Functions and Firebase Cloud Messaging when you get a message or reaction.
- **Unread Indicators**: See unread chat badges in the navigation bar and red dot indicators in your chat list.

## Backend Setup (Vercel)
If you want to deploy the notification backend yourself:
1. Navigate to the `vercel_backend` folder.
2. Run `vercel` or `vercel --prod` to deploy.
3. Configure your `FIREBASE_SERVICE_ACCOUNT_KEY` environment variable in the Vercel dashboard.
4. Update the `VercelURL` inside `lib/services/firebase_notification_service.dart`.
