// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Registry.sol";
import "./IFinder.sol";

/**
 * @title Register and track all the self-minting derivatives deployed
 */
contract SelfMintingRegistry is SynthereumRegistry {
  /**
   * @notice Constructs the SelfMintingRegistry contract
   * @param _synthereumFinder Synthereum finder contract
   */
  constructor(ISynthereumFinder _synthereumFinder)
    public
    SynthereumRegistry('SELF MINTING REGISTRY', _synthereumFinder)
  {}
}
