// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import "./IDerivative.sol";

interface ISynthereumPoolInteraction {
  /**
   * @notice Called by a source Pool's `exchange` function to mint destination tokens
   * @notice This functon can be called only by a pool registred in the PoolRegister contract
   * @param srcDerivative Derivative used by the source pool
   * @param derivative The derivative of the destination pool to use for mint
   * @param collateralAmount The amount of collateral to use from the source Pool
   * @param numTokens The number of new tokens to mint
   */
  function exchangeMint(
    IDerivative srcDerivative,
    IDerivative derivative,
    uint256 collateralAmount,
    uint256 numTokens
  ) external;

  /**
   * @notice Check if a derivative is in the whitelist of this pool
   * @param derivative Perpetual derivative
   * @return isAdmitted Return true if in the whitelist, otherwise false
   */
  function isDerivativeAdmitted(IDerivative derivative)
    external
    view
    returns (bool isAdmitted);

  /**
   * @notice Returns price identifier of the pool
   * @return identifier Price identifier
   */
  function getPriceFeedIdentifier() external view returns (bytes32 identifier);
}
