// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./AggregatorV3Interface.sol";
import "./IPriceFeedLegacy.sol";

interface IPriceFeed is IPriceFeedLegacy, AggregatorV3Interface {
  function getDataFeedId() external view returns (bytes32);
}
