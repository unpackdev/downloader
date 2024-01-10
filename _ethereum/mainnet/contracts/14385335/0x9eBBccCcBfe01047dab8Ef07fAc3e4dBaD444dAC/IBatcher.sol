// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title IPeripheryBatcher
 * @notice A batcher to resolve router deposits/withdrawals in batches
 * @dev Provides an interface for Batcher
 */
interface IBatcher {
  /**
   * @notice Stores the deposits for future batching via periphery
   * @param amountIn Value of token to be deposited
   * @param routerAddress address of router to deposit into
   * @param signature signature verifying that depositor has enough karma and is authorized to deposit by brahma
   */
  function depositFunds(
    uint256 amountIn,
    address routerAddress,
    bytes memory signature
  ) external;

  /**
   * @notice Stores the deposits for future batching via periphery
   * @param amountIn Value of Lp token to be deposited
   * @param routerAddress address of router to deposit into
   * @param signature signature verifying that depositor has enough karma and is authorized to deposit by brahma
   */
  function depositFundsInCurveLpToken(
    uint256 amountIn,
    address routerAddress,
    bytes memory signature
  ) external;

  /**
   * @notice Stores the deposits for future batching via periphery
   * @param amountOut Value of token to be deposited
   * @param routerAddress address of router to deposit into
   */
  function withdrawFunds(uint256 amountOut, address routerAddress) external;

  /**
   * @notice Performs deposits on the periphery for the supplied users in batch
   * @param routerAddress address of router to deposit inton
   * @param users array of users whose deposits must be resolved
   */
  function batchDeposit(address routerAddress, address[] memory users) external;

  /**
   * @notice Performs withdraws on the periphery for the supplied users in batch
   * @param routerAddress address of router to deposit inton
   * @param users array of users whose deposits must be resolved
   */
  function batchWithdraw(address routerAddress, address[] memory users)
    external;

  /**
   * @notice To set a token address as the deposit token for a router
   * @param routerAddress address of router to deposit inton
   * @param token address of token which is to be deposited into router
   */
  function setRouterParams(address routerAddress, address token, uint256 maxLimit) external;


  /**
   * @notice To set slippage param for curve lp token conversion
   * @param slippage for curve lp token to usdc conversion
   */
  function setSlippage(uint256 slippage) external;
}
