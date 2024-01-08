// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./CountersUpgradeable.sol";
import "./AggregatorV3Interface.sol";

// Storage is append only and never to be modified
// To upgrade:
//
// contract CMCLayerStorageV1 is LayerStorageV0 {...}
// contract CMCLayerV1 is LayerStorageV1 ... {...}

contract CMCLayerStorageV0 {
  /**
   * Layer contains a `currentState` from 0 to `maxState` (exclusive)
   * if `modularLayer` is set to true, the layer state is driven by `module`
   */
  struct Layer {
    // cids for ipfs content identifier
    string[] cids;
  }

  /**
   * @dev The current id of Layer. Auto increment.
   */
  CountersUpgradeable.Counter public id;

  /**
   * @dev tokenID to Layer
   */
  mapping(uint256 => Layer) layers;

  /**
   * @dev chainlink oracle.
   */
  AggregatorV3Interface internal priceFeed;

  /**
   * @dev last price updated time
   */
  uint256 public lastUpdatedAt;

  /**
   * @dev last updated price
   */
  int256 public lastPrice;

  /**
   * @dev update interval in seconds;
   */
  uint256 public updateInterval;

  /**
   * @dev threshold for updating state in basis point
   */
  int256 public threshold;

  // globally used maximum state
  uint32 internal globalStateCount;

  // globally current state [0, maxState)
  uint32 internal globalCurrentState;
}
