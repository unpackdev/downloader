// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./PriceFeedWithoutRounds.sol";
import "./IRedstoneAdapter.sol";

contract PriceFeedVenusMainnetXvsXvs is PriceFeedWithoutRounds {
  function getDataFeedId() public view virtual override returns (bytes32) {
    return bytes32("XVS");
  }

  function getPriceFeedAdapter() public view virtual override returns (IRedstoneAdapter) {
    return IRedstoneAdapter(0x17350E8433f109e1Da3Dbd4f8B1E75759243572D);
  }
}
