// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Errors {
    // UniversalLiquidatorRegistry errors
    error InvalidLength();
    error DexExists();
    error DexDoesNotExist();
    error PathsNotExist();
    // UniversalLiquidator errors
    error InvalidAddress();
}
