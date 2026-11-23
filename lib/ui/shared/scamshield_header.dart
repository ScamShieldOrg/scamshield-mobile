import 'package:flutter/material.dart';

class ScamShieldHeader extends StatelessWidget implements PreferredSizeWidget {
  const ScamShieldHeader({super.key, this.pageTitle});

  final String? pageTitle;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: preferredSize.height,
      automaticallyImplyLeading: false,
      title: pageTitle != null
          ? Text(
              pageTitle!,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            )
          : const Row(
              children: [
                Icon(Icons.verified_user_outlined, size: 18),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'ScamShield',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                  ),
                ),
              ],
            ),
      actions: [
        IconButton(
          tooltip: 'Thông Báo',
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Thông Báo'),
              content: const Text(
                'Thông báo chưa khả dụng trên ứng dụng di động.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}
