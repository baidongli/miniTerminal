/// Built-in terminal color themes.
enum TerminalThemeId { dark, light, solarizedDark, nord }

extension TerminalThemeIdLabel on TerminalThemeId {
  String get label => switch (this) {
        TerminalThemeId.dark => 'Dark',
        TerminalThemeId.light => 'Light',
        TerminalThemeId.solarizedDark => 'Solarized Dark',
        TerminalThemeId.nord => 'Nord',
      };
}

class AppSettings {
  const AppSettings({
    this.terminalTheme = TerminalThemeId.dark,
    this.fontSize = 14,
    this.scrollback = 10000,
    this.appLockEnabled = false,
    this.defaultKeepAliveSeconds = 30,
  });

  final TerminalThemeId terminalTheme;
  final double fontSize;
  final int scrollback;
  final bool appLockEnabled;
  final int defaultKeepAliveSeconds;

  AppSettings copyWith({
    TerminalThemeId? terminalTheme,
    double? fontSize,
    int? scrollback,
    bool? appLockEnabled,
    int? defaultKeepAliveSeconds,
  }) =>
      AppSettings(
        terminalTheme: terminalTheme ?? this.terminalTheme,
        fontSize: fontSize ?? this.fontSize,
        scrollback: scrollback ?? this.scrollback,
        appLockEnabled: appLockEnabled ?? this.appLockEnabled,
        defaultKeepAliveSeconds:
            defaultKeepAliveSeconds ?? this.defaultKeepAliveSeconds,
      );

  Map<String, dynamic> toJson() => {
        'terminalTheme': terminalTheme.name,
        'fontSize': fontSize,
        'scrollback': scrollback,
        'appLockEnabled': appLockEnabled,
        'defaultKeepAliveSeconds': defaultKeepAliveSeconds,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        terminalTheme: TerminalThemeId.values.firstWhere(
          (e) => e.name == json['terminalTheme'],
          orElse: () => TerminalThemeId.dark,
        ),
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14,
        scrollback: (json['scrollback'] as num?)?.toInt() ?? 10000,
        appLockEnabled: json['appLockEnabled'] as bool? ?? false,
        defaultKeepAliveSeconds:
            (json['defaultKeepAliveSeconds'] as num?)?.toInt() ?? 30,
      );
}
