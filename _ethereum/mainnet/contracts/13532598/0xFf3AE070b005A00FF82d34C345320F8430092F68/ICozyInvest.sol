// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @notice Interfaces for developing on-chain scripts for borrowing from the Cozy markets then supplying to
 * investment opportunities in a single transaction
 * @dev Contract developed from this interface are intended to be used by delegatecalling to it from a DSProxy
 * @dev For interactions with the Cozy Protocol, ensure the return value is zero and revert otherwise. See
 * the Cozy Protocol documentation on error codes for more info
 */
interface ICozyInvest1 {
  function invest(
    address _ethMarket,
    uint256 _borrowAmount,
    uint256 _minAmountOut
  ) external payable;
}

interface ICozyInvest2 {
  function invest(address _ethMarket, uint256 _borrowAmount) external;
}

interface ICozyDivest1 {
  function divest(
    address _marketAddress,
    address _recipient,
    uint256 _redeemAmount,
    uint256 _curveMinAmountOut
  ) external payable;
}

interface ICozyDivest2 {
  // NOTE: Same signature as above (except for the payable part), but with different meanings of each input
  function divest(
    address _marketAddress,
    address _recipient,
    uint256 _withdrawAmount,
    uint256 _excessTokens
  ) external;
}
