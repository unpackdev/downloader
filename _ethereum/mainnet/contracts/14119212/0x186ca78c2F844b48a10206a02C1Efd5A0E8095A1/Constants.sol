// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

/**
 * @dev Constant values shared across mixins.
 */
abstract contract Constants {
    uint256 internal constant BASIS_POINTS = 10000;

    uint256 internal constant READ_ONLY_GAS_LIMIT = 40000;

    /**
     * @dev Support up to 5 royalty recipients. A cap is required to ensure gas costs are not too high
   * when an auction is finalized.
   */
    uint256 internal constant MAX_CREATOR_INDEX = 4;
}