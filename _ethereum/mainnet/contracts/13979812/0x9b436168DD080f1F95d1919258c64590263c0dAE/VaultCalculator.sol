// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title IVaultCalculator Interface
interface IVaultCalculator {
    function calculate(address) external returns (uint256);
}

/// @title VaultCalculator abstract contract
abstract contract VaultCalculator {
    function calculate(address) external virtual returns (uint256);
}
