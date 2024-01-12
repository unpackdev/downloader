// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RoyaltyEngineStorage {
    bytes32 public constant UPGRADE_ROLE = keccak256("UPGRADE_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    struct RoyaltyConfig {
        address setter;
        address payable[] receivers;
        uint256[] fees;
    }
    mapping(address => RoyaltyConfig) public royaltyConfigs;
    address public manifoldRoyaltyEngine;
}
