// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;
pragma abicoder v2;

import "./IERC20.sol";

/**
 * Wrapped Ether (WETH) minting/burning interface.
 */
interface IWETH9 is IERC20 {
  function deposit() external payable;
  function withdraw(uint256) external;
}
