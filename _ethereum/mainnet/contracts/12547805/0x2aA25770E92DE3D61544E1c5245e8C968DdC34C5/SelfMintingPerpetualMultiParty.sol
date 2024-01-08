// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SelfMintingPerpetualLiquidatableMultiParty.sol";

/**
 * @title SelfMintingPerpetualMultiParty Contract.
 * @notice Convenient wrapper for Liquidatable.
 */
contract SelfMintingPerpetualMultiParty is
  SelfMintingPerpetualLiquidatableMultiParty
{
  /**
   * @notice Constructs the self-minting perpetual contract.
   * @param params struct to define input parameters for construction of Liquidatable. Some params
   * are fed directly into the PositionManager's constructor within the inheritance tree.
   */
  constructor(ConstructorParams memory params)
    public
    SelfMintingPerpetualLiquidatableMultiParty(params)
  {}
}
