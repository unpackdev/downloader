// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AggregatorV2V3Interface.sol";

interface PriceFeedProxy is AggregatorV2V3Interface {
  function aggregator() external view returns (address);

  function phaseId() external view returns (uint16);
}
