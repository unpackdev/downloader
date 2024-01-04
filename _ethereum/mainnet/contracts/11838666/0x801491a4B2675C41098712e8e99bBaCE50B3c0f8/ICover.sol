// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface ICover {
  function claimCovToken() external view returns (IERC20);
  function noclaimCovToken() external view returns (IERC20);
  function redeemCollateral(uint256 _amount) external;
}