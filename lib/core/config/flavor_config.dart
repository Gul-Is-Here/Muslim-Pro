enum Flavor { dev, staging, prod }

final class FlavorConfig {
  const FlavorConfig(this.flavor);

  final Flavor flavor;

  /// Set once in bootstrap(); defaults to dev so tests need no setup.
  static FlavorConfig instance = const FlavorConfig(Flavor.dev);

  bool get isDev => flavor == Flavor.dev;
  bool get isProd => flavor == Flavor.prod;
}
