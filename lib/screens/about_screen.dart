import 'package:flutter/material.dart';

const String kAppVersion = '0.9.1';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/icon/icon.png',
                      width: 88, height: 88),
                ),
                const SizedBox(height: 12),
                Text('MiniTerminal',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Version $kAppVersion',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'A fast, secure SSH client for your pocket.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Text(
            'MiniTerminal lets you manage your servers and connect over '
            'SSH from your phone — with password or SSH-key '
            'authentication, a full interactive terminal, SFTP file '
            'transfer, port forwarding, and jump-host support.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),
          _Section(
            title: 'Features',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _Bullet('Host management with groups, tags, and search'),
                _Bullet('Password and SSH key authentication (ed25519)'),
                _Bullet('Interactive terminal with color themes'),
                _Bullet('SFTP file browser — upload and download'),
                _Bullet('Local and remote port forwarding'),
                _Bullet('Jump-host (bastion) connections'),
                _Bullet('Multiple concurrent sessions'),
                _Bullet('Reusable command snippets'),
                _Bullet('Biometric app lock'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _Section(
            title: 'Privacy',
            child: Text(
              'Your passwords and private keys are stored only on this '
              'device, in the system keychain (iOS Keychain / Android '
              'Keystore). MiniTerminal has no accounts and sends none of '
              'your data to any server.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Built with Flutter · Open source',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 10),
            child: Icon(Icons.circle, size: 6),
          ),
          Expanded(
            child: Text(text,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.4)),
          ),
        ],
      ),
    );
  }
}
