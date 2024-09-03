// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import '../../build_runner_core.dart';

import '../generate/phase.dart';
import '../package_graph/target_graph.dart';
import '../util/build_dirs.dart';
import 'graph.dart';
import 'node.dart';

/// A cache of the results of checking whether outputs from optional build steps
/// were required by in the current build.
///
/// An optional output becomes required if:
/// - Any of it's transitive outputs is required (based on the criteria below).
/// - It was output by the same build step as any required output.
///
/// Any outputs from non-optional phases are considered required, unless the
/// following are all true.
///  - [_buildDirs] is non-empty.
///  - The output lives in a non-lib directory.
///  - The outputs path is not prefixed by one of [_buildDirs].
///  - If [_buildFilters] is non-empty and the output doesn't match one of the
///    filters.
///
/// Non-required optional output might still exist in the generated directory
/// and the asset graph but we should avoid serving them, outputting them in
/// the merged directories, or considering a failed output as an overall.
class OptionalOutputTracker {
  final _checkedOutputs = <AssetId, bool>{};
  final AssetGraph _assetGraph;
  final TargetGraph _targetGraph;
  final Set<String> _buildDirs;
  final Set<BuildFilter> _buildFilters;
  final List<BuildPhase> _buildPhases;

  OptionalOutputTracker(
    this._assetGraph,
    this._targetGraph,
    this._buildDirs,
    this._buildFilters,
    this._buildPhases,
  );

  /// Returns whether [output] is required.
  ///
  /// If necessary crawls transitive outputs that read [output] or any other
  /// assets generated by the same phase until it finds one which is required.
  ///
  /// [currentlyChecking] is used to aovid repeatedly checking the same outputs.
  bool isRequired(AssetId output, [Set<AssetId>? currentlyChecking]) {
    currentlyChecking ??= <AssetId>{};
    if (currentlyChecking.contains(output)) return false;
    currentlyChecking.add(output);

    final node = _assetGraph.get(output);
    if (node is! GeneratedAssetNode) return true;
    final phase = _buildPhases[node.phaseNumber];
    if (!phase.isOptional &&
        shouldBuildForDirs(
          output,
          buildDirs: _buildDirs,
          buildFilters: _buildFilters,
          phase: phase,
          targetGraph: _targetGraph,
        )) {
      return true;
    }
    return _checkedOutputs.putIfAbsent(
      output,
      () =>
          node.outputs.any((o) => isRequired(o, currentlyChecking)) ||
          _assetGraph
              .outputsForPhase(output.package, node.phaseNumber)
              .where((n) => n.primaryInput == node.primaryInput)
              .map((n) => n.id)
              .any((o) => isRequired(o, currentlyChecking)),
    );
  }

  /// Clears the cache of which assets were required.
  ///
  /// If the tracker is used across multiple builds it must be reset in between
  /// each one.
  void reset() {
    _checkedOutputs.clear();
  }
}
