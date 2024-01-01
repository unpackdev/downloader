// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IWETH.sol";
import "./IPermit2.sol";
import "./IStargateComposer.sol";

/**
 * NOTE: Events and errors must be copied to ILibWarp
 */
library LibWarp {
  event Warp(
    address indexed partner,
    address indexed tokenIn,
    address indexed tokenOut,
    uint256 amountIn,
    uint256 amountOut
  );

  struct State {
    IWETH weth;
    IPermit2 permit2;
    IStargateComposer stargateComposer;
  }

  bytes32 constant DIAMOND_STORAGE_SLOT = keccak256('diamond.storage.LibWarp');

  function state() internal pure returns (State storage s) {
    bytes32 slot = DIAMOND_STORAGE_SLOT;

    assembly {
      s.slot := slot
    }
  }

  function applySlippage(uint256 amount, uint16 slippage) internal pure returns (uint256) {
    return (amount * (10_000 - slippage)) / 10_000;
  }
}
