// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.6;

interface IFeeDistribution {

  function canSwap(address who) external returns(bool);

  function swapAndDistribute(uint usdpAmount, uint minDuckAmount) external returns(uint);

  // @dev This function should be manually changed to "view" in the ABI
  function viewDistribution() external returns(uint usdp_, uint duck_);
}
