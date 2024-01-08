// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SelfMintingPerpetualMultiParty.sol";

/**
 * @title Provides convenient Self-minting Perpetual Multi Party contract utilities.
 * @dev Using this library to deploy Self-minting Perpetuals allows calling contracts to avoid importing the full bytecode.
 */
library SelfMintingPerpetualMultiPartyLib {
  /**
   * @notice Returns address of new Self-minting Perpetual deployed with given `params` configuration.
   * @dev Caller will need to register new Self-minting Perpetual with the Self-minting Registry to begin requesting prices. Caller is also
   * responsible for enforcing constraints on `params`.
   * @param params is a `ConstructorParams` object from SelfMintingPerpetual.
   * @return address of the deployed self-minting perpetual contract
   */
  function deploy(
    SelfMintingPerpetualMultiParty.ConstructorParams memory params
  ) external returns (address) {
    SelfMintingPerpetualMultiParty derivative =
      new SelfMintingPerpetualMultiParty(params);
    return address(derivative);
  }
}
