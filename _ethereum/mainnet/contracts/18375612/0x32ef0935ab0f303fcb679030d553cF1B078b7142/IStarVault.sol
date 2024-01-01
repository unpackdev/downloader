// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./EnumerableSet.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./LibDiamond.sol";
import "./LibStarVault.sol";

interface IStarVault {
  error EthTransferFailed();

  event Withdraw(address indexed partner, address indexed token, uint256 amount);

  function partnerTokens(address partner) external view returns (address[] memory tokens_);

  function partnerTokenBalance(address partner, address token) external view returns (uint256);

  function partnerWithdraw(address token) external;

  function ownerWithdraw(address token, uint256 amount, address payable to) external;
}
