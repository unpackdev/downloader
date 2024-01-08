// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

/// @notice Contains event declarations related to NutBerry.
// Audit-1: ok
interface NutBerryEvents {
  event BlockBeacon();
  event CustomBlockBeacon();
  event NewSolution();
  event RollupUpgrade(address target);
}
