// SPDX-License-Identifier: No License

pragma solidity ^0.7.3;

import "./ICoverERC20.sol";

/**
 * @title Cover contract interface. See {Cover}.
 * @author crypto-pumpkin@github
 */
interface ICover {
  function owner() external view returns (address);
  function expirationTimestamp() external view returns (uint48);
  function collateral() external view returns (address);
  function claimCovToken() external view returns (ICoverERC20);
  function noclaimCovToken() external view returns (ICoverERC20);
  function claimNonce() external view returns (uint256);

  function redeemClaim() external;
  function redeemNoclaim() external;
  function redeemCollateral(uint256 _amount) external;
}