// SPDX-License-Identifier: Unlicense

pragma solidity >=0.6.0 <0.8.0;

import "./SatelliteMultiBridge.sol";

/**
 * wSCC Bridge
 *
 * Attributes:
 * - Mints wSCC tokens from an authorized member after a cross-chain migration
 * - Burns wSCC tokens from the bridge and emits a cross-chain fee migration event
 */
contract Bridge is SatelliteMultiBridge {
  constructor(ISatelliteWSCC wSCC, uint256[] memory chainList) public SatelliteMultiBridge(wSCC, chainList) {}
}
