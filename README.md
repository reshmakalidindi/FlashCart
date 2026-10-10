# ⚡ FlashCart - Smart Supermarket Self-Checkout App

**FlashCart** is a modern, production-grade Flutter self-checkout application designed to eliminate long checkout queues in Indian supermarkets (e.g., D-Mart, Reliance Fresh). Customers scan product barcodes as they shop, add items to their digital cart, complete instant checkout via UPI/Cards, and generate a secure exit QR receipt for store staff verification.

---

## 📱 Features Summary

1. **Splash & Onboarding**: Animated logo with tagline *"Scan. Shop. Pay. Go."* and automatic state navigation.
2. **Firebase Auth**: Support for email/password registration, login, logout, and staff role toggle.
3. **Interactive Home Dashboard**: Greeting banner, quick-access camera barcode scanner, supermarket catalog filter pills, seed database action, and bottom sticky cart summary bar.
4. **Barcode Scanner (`mobile_scanner`)**: Dedicated scanner with camera torch control, scan frame overlay, debouncing mechanism to suppress camera repeat hits, and manual barcode fallback.
5. **Product Confirmation**: Modal sheet displaying product photo, category, weight, unit price, tax info, and quantity selector `[-] quantity [+]`.
6. **Shopping Cart (`CartProvider`)**: Live item list with instant total recalculation (Subtotal, GST, Discounts, Final Total) and swipe-to-remove.
7. **Zero-Trust Backend Price Revalidation**: Server-side price revalidation against Cloud Firestore database before checkout so modified client prices are rejected.
8. **Isolated Payment Architecture**: Ready for Razorpay/UPI integration with built-in `PaymentService` abstraction and animated mock authorization.
9. **QR Code Exit Pass (`qr_flutter`)**: Generates secure order verification string encoded into a high-density QR code.
10. **Digital Receipt**: Clean itemized bill showing order #, date, payment status, tax breakdown, and total paid.
11. **Staff Exit QR Scanner (`StaffScannerScreen`)**: Dedicated scanner for store guards/staff to verify customer exit passes, check payment status, update `exitVerified = true`, and block duplicate QR reuse attempts.

---

## 🏗️ Technical Architecture & Project Structure

```text
flash_cart/
├── lib/
│   ├── main.dart
│   │
│   ├── models/
│   │   ├── product.dart
│   │   ├── cart_item.dart
│   │   ├── order.dart
│   │   └── user_model.dart
│   │
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   ├── home_screen.dart
│   │   ├── scanner_screen.dart
│   │   ├── product_details_screen.dart
│   │   ├── cart_screen.dart
│   │   ├── checkout_screen.dart
│   │   ├── payment_screen.dart
│   │   ├── order_success_screen.dart
│   │   ├── order_history_screen.dart
│   │   └── staff_scanner_screen.dart
│   │
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── product_service.dart
│   │   ├── cart_service.dart
│   │   ├── order_service.dart
│   │   └── payment_service.dart
│   │
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── product_provider.dart
│   │   └── cart_provider.dart
│   │
│   ├── widgets/
│   │   ├── product_card.dart
│   │   ├── cart_item_card.dart
│   │   ├── primary_button.dart
│   │   ├── price_text.dart
│   │   └── empty_cart.dart
│   │
│   ├── theme/
│   │   └── app_theme.dart
│   │
│   └── utils/
│       ├── constants.dart
│       └── validators.dart
│
├── firestore.rules
└── pubspec.yaml
```

---

## 🗄️ Firestore Collections & Schemas

### 1. `products` Collection
Document ID: `prod_{barcode}`
```json
{
  "name": "Amul Taaza Toned Milk",
  "barcode": "8901234567890",
  "price": 68.0,
  "weight": "1 L",
  "unit": "L",
  "category": "Dairy",
  "imageUrl": "https://images.unsplash.com/...",
  "description": "Pasteurised Toned Milk by Amul",
  "stock": 100,
  "taxPercentage": 0.0,
  "isAvailable": true
}
```

### 2. `orders` Collection
Document ID: `FC{timestamp}`
```json
{
  "orderId": "FC123456789",
  "userId": "user_uid",
  "userName": "Rahul Sharma",
  "userEmail": "rahul@flashcart.com",
  "items": [ ... ],
  "subtotal": 450.0,
  "tax": 23.0,
  "discount": 0.0,
  "total": 473.0,
  "paymentStatus": "paid",
  "paymentId": "PAY_FC_849201",
  "orderStatus": "paid",
  "createdAt": "2026-10-06T14:30:00Z",
  "exitVerified": false,
  "verifiedAt": null,
  "verifiedBy": null
}
```

### 3. `users` Collection
Document ID: `{uid}`
```json
{
  "uid": "user_uid",
  "email": "customer@flashcart.com",
  "displayName": "Rahul Sharma",
  "isStaff": false,
  "createdAt": "2026-10-06T14:00:00Z"
}
```

---

## 🔒 Security & Firestore Rules (`firestore.rules`)

- **Price Integrity**: Client-submitted prices are ignored. Before payment, `CartService.revalidateCartWithBackend` queries Firestore to compute authoritative totals.
- **Verification Security**: Only authenticated staff (`isStaff == true` or staff token) can write `exitVerified = true` to prevent fraudulent order modifications.

---

## 🚀 How to Run & Test

### 1. Requirements
- Flutter SDK 3.x
- Dart 3.x

### 2. Run App
```bash
cd flash_cart
flutter pub get
flutter run
```

### 3. Testing Workflow
1. **Login Screen**:
   - Tap **"Quick Demo Login (Auto-fill)"** to log in as a customer.
   - Or toggle the **"Role: Store Staff / Cashier"** switch to test staff QR verification mode.

2. **Seeding Products**:
   - On the Home Screen, tap **"Seed Database"** to populate Firestore with 15 realistic Indian supermarket items (Amul Milk, Parle-G, Dove Soap, Aashirvaad Atta, Tata Salt, Maggi, Cadbury, Coca-Cola, etc.).

3. **Testing Barcode Scanning**:
   - Tap **"📷 Scan Product"** from the home dashboard.
   - Scan a physical barcode or tap **"Type Barcode or Select Demo Item"** to pick sample barcodes (`8901234567890`, `8901234567891`, etc.).
   - Choose quantity and tap **Add to Cart**.

4. **Cart & Checkout**:
   - Open Cart, review item breakdown (Subtotal, GST, Total), and tap **Proceed to Checkout**.
   - Notice the instant **Backend Price Revalidation** step.
   - Select UPI/Card payment and tap **Pay Now**.

5. **Exit Pass & Staff Verification**:
   - Upon successful payment, view the generated **Secure Exit QR Pass**.
   - Log into a second device (or switch role to **Store Staff**).
   - Open **Staff Scanner**, scan the customer's QR code (or enter the order # e.g. `FC...`).
   - The app verifies payment and marks the exit pass as **VERIFIED**. Scanning the same QR again will trigger an **ALREADY VERIFIED** alert!
