// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./IWETH.sol";

library LibWarp {
  bytes32 constant DIAMOND_STORAGE_SLOT = keccak256('diamond.storage.LibWarp');

  struct State {
    IWETH weth;
  }

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
