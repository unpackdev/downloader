// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./CrossChainBridgeERC20LiquidityManagerV1.sol";
import "./IERC20.sol";

interface ICrossChainBridgeERC20LiquidityManager {
  function lpTokens(address spender) external returns (bool exists, IERC20 token);

  function createPool(address token) external returns (bool);

  function addLiquidityERC20(IERC20 token, uint256 amount) external;

  function withdrawLiquidityERC20(IERC20 token, uint256 amount) external;

  function defaultLiquidityWithdrawalFee() external returns (uint256);

  function liquidityWithdrawalFees(address token) external returns (uint256);
}
