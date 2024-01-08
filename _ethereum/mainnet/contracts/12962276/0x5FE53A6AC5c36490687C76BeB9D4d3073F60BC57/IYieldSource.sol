// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

interface IYieldSource {
  function depositToken() external view returns (address);
  function balanceOfToken(address addr) external returns (uint256);
  function supplyTokenTo(uint256 amount, address to) external;
  function redeemToken(uint256 amount) external returns (uint256);
}