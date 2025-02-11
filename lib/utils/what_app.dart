import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Launches WhatsApp as an external app with a predefined message.
/// [phoneNumber] must include the country code (e.g., "1234567890").
Future<void> launchWhatsAppExternally(String phoneNumber) async {
  // Define the message
  const String initialMessage = "مرحباً بك ف دعم Excidia Academy !";

  // URL-encode the message
  final String encodedMessage = Uri.encodeComponent(initialMessage);

  // Construct the WhatsApp URL schema
  final String whatsappUrl = "https://wa.me/$phoneNumber?text=$encodedMessage";

  try {
    // Launch the URL with external handling
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(
        Uri.parse(whatsappUrl),
        mode: LaunchMode.externalApplication, // Ensures external app is used
      );
    } else {
      throw 'Could not launch WhatsApp. Ensure the app is installed and the phone number is valid.';
    }
  } catch (e) {
    // Handle any errors
    debugPrint('Error launching WhatsApp: $e');
    throw Exception("Failed to launch WhatsApp: $e");
  }
}

Future<void> launchWhatsAppGroup(String groupLink) async {
  try {
    // Validate the link format
    if (!(Uri.tryParse(groupLink)!.hasAbsolutePath ?? true)) {
      throw 'Invalid WhatsApp group link.';
    }

    // Launch the URL with external handling
    if (await canLaunchUrl(Uri.parse(groupLink))) {
      await launchUrl(
        Uri.parse(groupLink),
        mode: LaunchMode.externalApplication, // Ensures external app usage
      );
    } else {
      throw 'Could not open the WhatsApp group link. Ensure WhatsApp is installed.';
    }
  } catch (e) {
    // Handle errors gracefully
    debugPrint('Error launching WhatsApp group link: $e');
    throw Exception("Failed to open WhatsApp group: $e");
  }
}
