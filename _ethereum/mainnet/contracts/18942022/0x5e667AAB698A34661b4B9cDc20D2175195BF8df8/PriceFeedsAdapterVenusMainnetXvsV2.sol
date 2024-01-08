// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./PriceFeedsAdapterVenusMainnetXvs.sol";
import "./Addresses.sol";

contract PriceFeedsAdapterVenusMainnetXvsV2 is PriceFeedsAdapterVenusMainnetXvs {
  address internal constant MAIN_UPDATER_ADDRESS = 0xE76A94749f1Debb6a8823CDdf44f1e51CC95600e;
  address internal constant FALLBACK_UPDATER_ADDRESS = 0xEcc980B49C8011730d1DeC540586E235C81F9b45;
  address internal constant MANUAL_UPDATER_ADDRESS = 0x742733EbA44c03C0A491967A414EE7E3F2C2fA5a;

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
