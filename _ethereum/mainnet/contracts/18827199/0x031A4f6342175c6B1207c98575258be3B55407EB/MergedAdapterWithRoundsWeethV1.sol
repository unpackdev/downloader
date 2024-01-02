// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./MergedPriceFeedAdapterWithoutRoundsPrimaryProd.sol";
import "./Addresses.sol";

contract MergedAdapterWithRoundsWeethethV1 is MergedPriceFeedAdapterWithoutRoundsPrimaryProd {

  address internal constant MAIN_UPDATER_ADDRESS = 0xd9A4426Fb88F8919F9B6bb619E6c344D435Aa51e;
  address internal constant FALLBACK_UPDATER_ADDRESS = 0x8845188a541C6C2d54907Ee5a7b0f54FDeD33311;
  address internal constant MANUAL_UPDATER_ADDRESS = 0xdAfda97D234326556350f6e40B65D1233199e725;

  error UpdaterNotAuthorised(address signer);

  function getDataFeedId() public pure virtual override returns (bytes32) {
    return bytes32("weETH/ETH");
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
