// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./MergedPriceFeedAdapterWithRoundsPrimaryProd.sol";
import "./Addresses.sol";

contract MergedAdapterWithRoundsWeethV1 is MergedPriceFeedAdapterWithRoundsPrimaryProd {

  address internal constant MAIN_UPDATER_ADDRESS = 0x517a67D809549093bD3Ef7C6195546B8BDF24C04;
  address internal constant FALLBACK_UPDATER_ADDRESS = 0xF7a4CEAf91583d2256B5D1ca6C5962764669169d;
  address internal constant MANUAL_UPDATER_ADDRESS = 0x9E2B758ed85d9d8DD68d3F22fb8e30f7Ed0e3f28;

  error UpdaterNotAuthorised(address signer);

  function getDataFeedId() public pure virtual override returns (bytes32) {
    return bytes32("weETH");
  }

  function requireAuthorisedUpdater(address updater) public view override virtual {
    if (
      updater != MAIN_UPDATER_ADDRESS &&
      updater != FALLBACK_UPDATER_ADDRESS &&
      updater != MANUAL_UPDATER_ADDRESS &&
      updater != GelatoAddress.ADDR &&
      updater != OldGelatoAddress.ADDR
    ) {
      revert UpdaterNotAuthorised(updater);
    }
  }
}
