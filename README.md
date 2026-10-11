# SabZr: Grocery Delivery App

A Flutter + Firebase grocery delivery app for vegetables, fruits, dairy and chicken, with a built-in admin panel for managing inventory and orders.

Previously published on Google Play (currently unpublished). Run it locally using the steps below.

---

## Screenshots

### Customer app

| Sign up (OTP) | Home | Item details |
|:---:|:---:|:---:|
| <img src="screenshots/signup.png" width="220"> | <img src="screenshots/home.png" width="220"> | <img src="screenshots/details.png" width="220"> |

| Cart | Place order | My orders |
|:---:|:---:|:---:|
| <img src="screenshots/cart.png" width="220"> | <img src="screenshots/checkout.png" width="220"> | <img src="screenshots/orders.png" width="220"> |

### Admin panel

| Admin home | Add / edit items | Manage orders |
|:---:|:---:|:---:|
| <img src="screenshots/admin_home.png" width="220"> | <img src="screenshots/admin_items.png" width="220"> | <img src="screenshots/admin_orders.png" width="220"> |

---

## Features

### Customer
- Phone number sign up and login with OTP (Firebase Authentication)
- Browse items by category: Vegetable, Fruit, Dairy, Chicken
- Item details, discounted prices and out-of-stock indicators
- Cart with quantity controls and a "you saved ₹X" summary
- Pincode-based delivery address with a flat delivery fee
- Free item on orders above an admin-set amount
- Stock check before an order is placed
- Cash on Delivery checkout
- Order history with status (Pending, Delivered, Cancelled) and order cancellation
- Profile page and logout
- Push notification setup with Firebase Cloud Messaging

### Admin
- Separate admin login
- Add food items with images (uploaded to Firebase Storage)
- Edit items and toggle stock availability
- Set the free-item threshold
- View orders by status, mark them delivered, and clean up delivered orders

---

## Tech Stack

| Area | Tools |
|---|---|
| Framework | Flutter, Dart |
| Auth | Firebase Authentication (phone OTP) |
| Database | Cloud Firestore |
| Storage | Firebase Storage (item images) |
| Notifications | Firebase Cloud Messaging |
| Security | Firebase App Check |
| Other packages | image_picker, shared_preferences, url_launcher, curved_navigation_bar |

---

## Project Structure

```
lib/
├── main.dart              # App entry, Firebase and FCM init
├── firebase_msg.dart      # FCM setup
├── pages/                 # Customer screens (home, details, cart, orders, profile, auth)
├── admin/                 # Admin screens (login, add/edit items, orders, thresholds)
├── service/               # Firestore helpers, auth, SharedPreferences
└── widgets/               # Shared widgets and models
```

---

## Getting Started

**Prerequisites:** Flutter SDK (3.8+), an Android device or emulator, and a Firebase project.

```bash
git clone https://github.com/Syed-Farzan/food_delivery.git
cd food_delivery
flutter pub get
```

1. Create a Firebase project and add an Android app.
2. Enable **Phone** sign-in under Authentication.
3. Create a Firestore database and a Storage bucket.
4. Download `google-services.json` and place it in `android/app/`.
5. Run:

```bash
flutter run
```

---

## What I Learned

- Building a full customer and admin flow on one Firebase backend
- Phone OTP authentication and keeping users signed in with an auth state stream
- Batch writes in Firestore when turning a cart into an order
- Uploading images to Firebase Storage and taking an app through a Google Play release

## Planned Improvements

- Move state to Provider or Riverpod instead of `setState`
- Secure the admin login with Firebase Auth and Firestore security rules
- Validate prices server-side with Cloud Functions
- Add online payments (UPI) and complete the push notification flow
- Add tests

---

## Author

**Syed Farzan**
GitHub: [@Syed-Farzan](https://github.com/Syed-Farzan)
