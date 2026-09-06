class AppLaunchOptions {
  AppLaunchOptions._();

  static bool tvMode = false;

  static void read(List<String> arguments) {
    tvMode = arguments.contains('--tv-mode');
  }
}
