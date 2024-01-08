// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

contract Constants {
    // Initializer keys
    bytes32 public constant INITIALIZED = keccak256("storage.basket.initialized");
    bytes32 public constant INITIALIZED_BURNER_FIX = keccak256("storage.basket.initializedBurnerFix2");

    // K/V Stores
    // Mint/Burn fees and fee recipient
    // For example a MINT_FEE of:
    // * 0.50e18 = 50%
    // * 0.04e18 =  4%
    // * 0.01e18 =  1%
    uint256 public constant FEE_DIVISOR = 1e18; // Because we only work in Integers
    bytes32 public constant MINT_FEE = keccak256("storage.fees.mint");
    bytes32 public constant BURN_FEE = keccak256("storage.fees.burn");
    bytes32 public constant FEE_RECIPIENT = keccak256("storage.fees.recipient");

    // Access roles
    bytes32 public constant MARKET_MAKER = keccak256("storage.access.marketMaker");
    bytes32 public constant MARKET_MAKER_ADMIN = keccak256("storage.access.marketMaker.admin");

    bytes32 public constant MIGRATOR = keccak256("storage.access.migrator");
    bytes32 public constant TIMELOCK = keccak256("storage.access.timelock");
    bytes32 public constant TIMELOCK_ADMIN = keccak256("storage.access.timelock.admin");

    bytes32 public constant GOVERNANCE = keccak256("storage.access.governance");
    bytes32 public constant GOVERNANCE_ADMIN = keccak256("storage.access.governance.admin");
}
