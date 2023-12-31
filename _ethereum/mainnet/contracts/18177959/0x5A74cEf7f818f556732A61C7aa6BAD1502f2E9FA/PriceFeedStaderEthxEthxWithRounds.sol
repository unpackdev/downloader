// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./PriceFeedWithRounds.sol";

contract PriceFeedStaderEthxEthxWithRounds is PriceFeedWithRounds {
  function getDataFeedId() public view virtual override returns (bytes32) {
    return bytes32("ETHx");
  }

  function getPriceFeedAdapter() public view virtual override returns (IRedstoneAdapter) {
    return IRedstoneAdapter(0xF3eB387Ac1317fBc7E2EFD82214eE1E148f0Fe00);
  }
}
