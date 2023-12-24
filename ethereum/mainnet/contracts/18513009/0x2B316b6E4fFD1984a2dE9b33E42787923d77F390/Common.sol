// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;
import "./IERC20.sol";

/// @notice Thrown when updating an address with zero address
error ZeroAddress();

/// @notice Thrown when updating with an array of no values
error ZeroLengthArray();

/// @notice Thrown when updating with the same value as previously stored
error IdenticalValue();

/// @notice Thrown when two array lengths does not match
error ArrayLengthMismatch();

/// @dev The address of the Ethereum
IERC20 constant ETH = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
