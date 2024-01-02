// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./PriceFeedsAdapterStaderEthxWithRounds.sol";
import "./Addresses.sol";

contract PriceFeedsAdapterStaderEthxWithRoundsV2 is PriceFeedsAdapterStaderEthxWithRounds {
  address internal constant MAIN_UPDATER_ADDRESS = 0x378AB7B007b0Cf1AF7E10b78F3287d6F2Bb4955F;
  address internal constant FALLBACK_UPDATER_ADDRESS = 0xF639b67317bB049607Ef15b68184fE19c60895fC;
  address internal constant MANUAL_UPDATER_ADDRESS = 0xB182f6A8E931b586Bb02f7100645Fd2bA0ab0D0D;

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
