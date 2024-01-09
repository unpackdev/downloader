// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";
import "./ICubTraitProvider.sol";

/// @title TwoBitCubs
abstract contract TwoBitCubs is IERC721Enumerable, ICubTraitProvider {

    /// @dev The number of blocks until a growing cub becomes an adult (roughly 1 week)
    uint256 public constant ADULT_AGE = 44000;
}
