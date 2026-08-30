// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:murmur/core/theme/app_theme.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  Future<void> _openEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Could not open email client';
    }
  }

  Widget termsSection(
      {required String title, required String body, String emailEnd = ''}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge,
            overflow: TextOverflow.visible,
            textAlign: TextAlign.center,
          ),
          Text(
            body,
            style: Theme.of(context).textTheme.labelMedium,
            overflow: TextOverflow.visible,
            textAlign: TextAlign.center,
          ),
          if (emailEnd != '')
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    _openEmail(emailEnd);
                  },
                  child: Text(
                    emailEnd,
                    style: TextStyle(
                        fontSize:
                            Theme.of(context).textTheme.labelLarge!.fontSize,
                        fontWeight:
                            Theme.of(context).textTheme.labelLarge!.fontWeight,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.copy_outlined,
                      size: 14,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: emailEnd))
                          .then((result) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      });
                    }),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            scrolledUnderElevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            floating: true,
            pinned: false,
            snap: false,
            elevation: 0,
            title: const Text('Terms and Conditions'),
          ),
          SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Text(
                  'Last updated: August 2, 2025',
                  style: Theme.of(context).textTheme.labelSmall,
                  overflow: TextOverflow.visible,
                  textAlign: TextAlign.end,
                )),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: termsSection(
                title: '1. Acceptance of Terms',
                body:
                    '\nBy downloading or using this application (“App”), you agree to be bound by these Terms and Conditions. If you do not accept these terms, do not use the App.',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: termsSection(
                title: '2. Intended Use',
                body:
                    '\nThis App is designed to support emotional awareness, mood tracking, and mental well-being reflection. It is not a medical or diagnostic tool and does not replace professional mental health care. All content and features are for informational and self-reflective purposes only.',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: termsSection(
                title: '3. No Diagnosis or Medical Advice',
                body:
                    '\nThe App does not provide medical or psychological diagnosis, therapy, or treatment. If you are experiencing distress or mental health concerns, consult a licensed professional. Use of the App is at your own discretion and responsibility.',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: termsSection(
                  title: '4. Privacy and Data Protection',
                  body:
                      '\n4.1. Data Collection\nWe respect your privacy and collect only the data you provide, including mood entries, emotional tags, notes, test responses, and app usage information. This data helps us deliver app features and personalized insights tailored to you.\n \n4.2. Use and Sharing of Data\nYour data is used exclusively to improve app functionality and your user experience. We do not sell or share your personal information with third parties, except when required by law. Aggregated and anonymized data may be used for app improvements.\n \n4.3. Security and Your Rights\nWe implement reasonable security measures to protect your data but cannot guarantee absolute security. You can update or delete your account information at any time via the App\'s account settings. You also have the right to request correction, or deletion of your data by contacting us at ',
                  emailEnd: 'support@murmur.app'),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: termsSection(
                title: '5. Intellectual Property',
                body:
                    '\nAll content, visuals, and source code of the App are the intellectual property of the developers and are protected under applicable copyright and trademark laws.',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: termsSection(
                title: '6. User Responsibilities',
                body:
                    '\nYou agree not to misuse the App, interfere with its normal operation, attempt to access other users\' data, or engage in any unlawful activity related to the App.',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: termsSection(
                title: '7. Disclaimer of Liability',
                body:
                    '\nThe App is provided "as is" without warranties of any kind. The developers are not liable for any direct or indirect damages arising from the use of the App.',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: termsSection(
                title: '8. Modifications',
                body:
                    '\nWe reserve the right to update or modify these Terms at any time. Continued use of the App after changes constitutes acceptance of the new terms.',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: termsSection(
                title: '9. Contact Information',
                body:
                    '\nFor questions, concerns, or requests related to these Terms, please contact us at:',
                emailEnd: 'support@murmur.app',
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 24,
            ),
          ),
        ],
      ),
    );
  }
}
