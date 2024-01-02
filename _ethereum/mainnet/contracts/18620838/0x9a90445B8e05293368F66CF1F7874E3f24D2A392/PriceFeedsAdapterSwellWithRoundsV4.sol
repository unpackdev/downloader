// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./PriceFeedsAdapterSwellWithRoundsV3.sol";
import "./Addresses.sol";

contract PriceFeedsAdapterSwellWithRoundsV4 is PriceFeedsAdapterSwellWithRoundsV3 {
  address internal constant MAIN_UPDATER_ADDRESS = 0xFcDE1D8c09C9FE0182Fe37b980B843f6388E12b1;
  address internal constant FALLBACK_UPDATER_ADDRESS = 0x9A75b06aaCd895047fF67bC49e0571920C40BB3D;
  address internal constant MANUAL_UPDATER_ADDRESS = 0x251400225400426cecaE5892804e10821a9644eA;

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
