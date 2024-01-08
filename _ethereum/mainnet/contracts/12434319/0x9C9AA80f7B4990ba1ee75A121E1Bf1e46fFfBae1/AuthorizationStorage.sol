//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title AuthorizationStorage
 * @author Protofire
 * @dev Storage structure used by Authorization contract.
 *
 * All storage must be declared here
 * New storage must be appended to the end
 * Never remove items from this list
 */
abstract contract AuthorizationStorage {
    /// @dev Permissions module address
    address public permissions;
    /// @dev EurPriceFeed module address
    address public eurPriceFeed;
    /// @dev OperationsRegistry address
    address public operationsRegistry;
    /// @dev Balancer BFactory address
    address public poolFactory;
    /// @dev XTokenWrapper address
    address public xTokenWrapper;
    /// @dev Traiding limit value (in WEI) for some type of users
    uint256 public tradingLimit;

    /// @dev Indicates if protocol is paused
    bool public paused;

    bytes4 public constant ERC20_TRANSFER = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 public constant ERC20_TRANSFER_FROM = bytes4(keccak256("transferFrom(address,address,uint256)"));
    bytes4 public constant ERC20_APPROVE = bytes4(keccak256("approve(address,uint256)"));
    bytes4 public constant ERC20_MINT = bytes4(keccak256("mint(address,uint256)"));
    bytes4 public constant ERC20_BURN_FROM = bytes4(keccak256("burnFrom(address,uint256)"));
    bytes4 public constant BFACTORY_NEW_POOL = bytes4(keccak256("newBPool()"));

    // Constants for Permissions ID
    uint256 public constant SUSPENDED_ID = 0;
    uint256 public constant TIER_1_ID = 1;
    uint256 public constant TIER_2_ID = 2;
    uint256 public constant REJECTED_ID = 3;
    uint256 public constant PROTOCOL_CONTRACT = 4;
    uint256 public constant POOL_CREATOR = 5;
}
