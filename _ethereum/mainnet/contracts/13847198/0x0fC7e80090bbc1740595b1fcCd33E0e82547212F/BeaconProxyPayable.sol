// SPDX-License-Identifier: UNLICENSED

// Copyright (c) WildCredit - All rights reserved
// https://twitter.com/WildCredit

pragma solidity 0.8.6;

import "BeaconProxy.sol";

contract BeaconProxyPayable is BeaconProxy {

  receive() external payable override {
    // Only from the WETH contract
    require(msg.sender == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, "LendingPair: not WETH");
  }

  constructor(address beacon, bytes memory data) payable BeaconProxy(beacon, data) { }
}
