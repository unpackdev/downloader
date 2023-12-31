// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./PriceFeedWithRounds.sol";

contract PriceFeedSwellSwetheth is PriceFeedWithRounds {
  function getDataFeedId() public view virtual override returns (bytes32) {
    return bytes32("SWETH/ETH");
  }

  function getPriceFeedAdapter() public view virtual override returns (IRedstoneAdapter) {
    return IRedstoneAdapter(0x68ba9602B2AeE30847412109D2eE89063bf08Ec2);
  }
}
