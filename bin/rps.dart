import 'dart:io';

import 'package:rps/src/cli/cli.dart';
import 'package:rps/src/cli/cli_options/help.dart';
import 'package:rps/src/cli/cli_options/upgrade.dart';
import 'package:rps/src/cli/cli_options/version.dart';
import 'package:rps/src/cli/commands/list.dart';
import 'package:rps/src/cli/exceptions/cli_exception.dart';
import 'package:rps/src/scripts.dart';
import 'package:rps/src/utils/rps_package.dart';
import 'package:rps/src/bindings/execute.dart' as bindings;
import 'package:rps/rps.dart';

void main(List<String> args) async {
  final console = Console(sink: stdout);

  try {
    final package = await RpsPackage.load();
    try {
      final versions = await package.getVersions();
      if (versions.hasUpdate) {
        console.writeBordered([
          'Update available ${gray(versions.current.toString())} → ${green(versions.latest.toString())}',
          'Run ${lightBlue('dart pub global activate rps')} to update',
        ]);
        await Future.delayed(const Duration(seconds: 2));
      }
    } on Exception {
      // ignore
    }

    ScriptsSource load() {
      try {
        return ScriptsYaml.load(Directory.current);
      } catch (e) {
        return Pubspec.load(Directory.current);
      }
    }

    final help = HelpOption(console: console, package: package);
    final cli = Cli(
      package: package,
      console: console,
      commands: [
        LsCommand(getScriptsSource: load),
        RunCommand(
          getScriptsSource: load,
          execute: bindings.execute,
        ),
      ],
      options: [
        help,
        const VersionOption(),
        const UpgradeOption(),
      ],
      fallback: help,
    );

    await cli.run(args);
  } on RpsException catch (err) {
    stderr.writeln("${boldRed('Error!')} ${err.message}");
    await stderr.flush();
    exit(1);
  } on CliException catch (err) {
    stderr.writeln("${boldRed('Error!')} ${err.message}");
    await stderr.flush();
    exit(err.exitCode);
  } catch (err, st) {
    stderr.writeln("${boldRed('Error!')} $err\n$st");
    await stderr.flush();
    exit(1);
  }
}
