// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import "./IERC20.sol";

/// @title Interface for wrapped protocol tokens, such as WETH or WMATIC
interface IWrappedProtocolToken is IERC20 {
  /// @notice Deposit the protocol token to get wrapped version
  function deposit() external payable;

  /// @notice Unwrap to get the protocol token back
  function withdraw(uint256) external;
}
