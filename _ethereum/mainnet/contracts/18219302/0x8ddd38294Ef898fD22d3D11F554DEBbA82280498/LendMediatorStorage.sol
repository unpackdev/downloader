// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./LendManager.sol";

/**
 * @title MetaLend's Lend Mediator proxy storage
 * @author MetaLend
 * @notice defines the proxy storage layout
 * @dev this should be inherited by `LendMediator` so that implementation and proxy have same layouts
 */
abstract contract LendMediatorProxyStorage {
    /// @notice Indicator that this is a LendMediator contract (for inspection)
    /// @return bool true this is lend mediator
    bool public constant IS_LEND_MEDIATOR = true;

    /// @notice manager which holds all data for LendMediator that is shared among all mediator contracts
    /// @return address of the LendManager
    LendManager public lendManager;

    /// @notice the owner (user) of the mediator, each mediating contact belongs to EOA
    /// @return address of the owner
    address payable public owner;
}

/**
 * @title MetaLend's Lend Mediator storage
 * @author MetaLend
 * @notice defines the initial storage layout
 * @dev use for both proxy and implementation contracts
 */
abstract contract LendMediatorStorage {
    /// @notice funds deposited by owner mapped to token contract address
    /// @return uint256 value of given token address
    mapping(address => uint256) public depositedFunds;
}
