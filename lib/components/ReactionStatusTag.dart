import 'package:flutter/material.dart';
import 'package:glacier/resources/ReactionResource.dart';
import 'package:glacier/themes/app_colors.dart';

class ReactionStatusTag extends StatelessWidget {
  final ReactionResource reaction;
  final VoidCallback? loadReactions;

  const ReactionStatusTag({
    super.key,
    required this.reaction,
    this.loadReactions,
  });

  @override
  Widget build(BuildContext context) {
    switch (reaction.status) {
      case '-1':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.purple,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Waiting',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        );
      case '0':
        return GestureDetector(
          onTap: () {
            Navigator.of(
              context,
              rootNavigator: true,
            ).pushNamed('/reaction', arguments: reaction).then((value) {
              // loadReactions();
              if (value == true) {
                Navigator.of(
                  context,
                ).pushNamed('/reaction-detail', arguments: reaction).then((_) {
                  loadReactions?.call();
                });
              }
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.tertiary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'To record',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        );
      case '1':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Recorded',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        );
      case '10':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Completed',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        );
      case '-10':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Failed',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        );
      default:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Unknown',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        );
    }
  }
}
