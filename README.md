<<<<<<< HEAD
# Test Checkout App

A Flutter-based checkout application deployed on Firebase.

## Project Structure

This project is organized as follows:
- Flutter application (main codebase)
- Temporary HTML fallbacks for testing (in build/web/checkout/)

## Development Workflow

1. Fix Flutter compilation issues in lib/pages/checkout_page.dart
2. Once fixed, the app will use Flutter for all UI rendering
3. The temporary HTML pages will be replaced by Flutter's web output

## Deployment Instructions

To deploy this application to Firebase:

1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login to Firebase: `firebase login`
3. Build the Flutter web app: `flutter build web`
4. Deploy to Firebase: `firebase deploy`

## URL Structure

The application is deployed at:
- Main URL: `https://test-checkout-daff3.web.app/`
- Checkout flow: `https://test-checkout-daff3.web.app/checkout/`

## Temporary Testing Pages

While the Flutter application is being fixed, you can test the basic flow using:
- Checkout page: `https://test-checkout-daff3.web.app/checkout/`
- Confirmation page: `https://test-checkout-daff3.web.app/checkout/confirmation.html`

## Troubleshooting

If the page is not visible:
- Check browser console for errors (F12 > Console)
- Verify Firebase hosting is properly configured
- Ensure index.html is properly deployed
- Check if the project has been built with `flutter build web` before deployment

## Resources

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
=======
# test_checkout
>>>>>>> 22526681ffe76a503e9b18d37df6c489133b767d
