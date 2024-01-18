// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @title Base contract for managing commonly-used constants
 * @author Jonas Sota
 */

// TODO deprecate for Constants library
abstract contract Constants {
    uint256 public constant FEE_PRECISION = 1e6;
    uint256 public constant SLIPPAGE_PRECISION = 1e6;
    uint256 public constant USD_DECIMALS = 8;
}
