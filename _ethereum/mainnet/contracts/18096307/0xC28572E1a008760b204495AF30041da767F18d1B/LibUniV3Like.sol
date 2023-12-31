// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

library LibUniV3Like {
  bytes32 constant DIAMOND_STORAGE_SLOT = keccak256('diamond.storage.LibUniV3Like');

  /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
  uint160 internal constant MIN_SQRT_RATIO = 4295128739 + 1;

  /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
  uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342 - 1;

  struct State {
    /**
     * Transient. Set to zero when not using
     */
    address callbackPool;
  }

  function state() internal pure returns (State storage s) {
    bytes32 slot = DIAMOND_STORAGE_SLOT;

    assembly {
      s.slot := slot
    }
  }
}
