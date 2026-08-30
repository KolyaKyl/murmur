import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:self_screen/models/psychological_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:self_screen/models/test_result.dart';

class TestCard extends StatelessWidget {
  final PsychologicalTest test;
  final TestResult? testresult;
  final VoidCallback onTap;

  const TestCard({
    super.key,
    required this.test,
    required this.onTap,
    this.testresult,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        color: theme.colorScheme.surfaceContainer,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                bottom: 0,
                right: 0,
                child: SizedBox(
                  width: MediaQuery.of(context).size.height / 4.5,
                  height: MediaQuery.of(context).size.height / 4.5,
                  child: Image(
                      fit: BoxFit.contain,
                      image: CachedNetworkImageProvider(test.logoUrl)),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          test.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                          textScaler: TextScaler.linear(1.0),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          test.subname,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                          ),
                          textScaler: TextScaler.linear(1.0),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          test.description,
                          style: theme.textTheme.labelMedium?.copyWith(
                            // color: Colors.grey,
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                          textScaler: TextScaler.linear(1.0),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                      testresult == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 20, 12, 20),
                                  child: Text(
                                    'Tap to start',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontSize: 24,
                                      color: Colors.grey,
                                    ),
                                    textScaler: TextScaler.linear(1.0),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text(
                                    'Last result: ${testresult!.result}',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontSize: 18,
                                    ),
                                    textScaler: TextScaler.linear(1.0),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text(
                                    testresult!.recommendation,
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      // color: Colors.grey,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    textScaler: TextScaler.linear(1.0),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text(
                                    DateFormat('yyyy-MM-dd HH:mm')
                                        .format(testresult!.timestamp),
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    textScaler: TextScaler.linear(1.0),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],
                            ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainer,
                                      title: Text('Source:'),
                                      content: Text(
                                        test.sourceFull,
                                      ),
                                      actions: [
                                        TextButton(
                                          child: Text('Ok'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Text(
                                'Source: ${test.source}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                    ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                textScaler: TextScaler.linear(1.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
