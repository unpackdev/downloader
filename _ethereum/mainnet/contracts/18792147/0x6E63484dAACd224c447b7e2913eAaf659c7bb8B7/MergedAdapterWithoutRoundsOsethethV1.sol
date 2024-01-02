// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./MergedPriceFeedAdapterWithoutRoundsPrimaryProd.sol";
import "./Addresses.sol";

contract MergedAdapterWithoutRoundsOsethethV1 is MergedPriceFeedAdapterWithoutRoundsPrimaryProd {

  address internal constant MAIN_UPDATER_ADDRESS = 0xcd1435F09c411FCBc44DA4A51f5C1a2e1b32fF47;
  address internal constant FALLBACK_UPDATER_ADDRESS = 0x9Abfefd388ae17E0B8a9F865EB1cCb137bf436cF;
  address internal constant MANUAL_UPDATER_ADDRESS = 0xc1c090658937107675cBFe4494E6b63519538B62;

  error UpdaterNotAuthorised(address signer);

  function getDataFeedId() public pure virtual override returns (bytes32) {
    return bytes32("osETH/ETH");
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
