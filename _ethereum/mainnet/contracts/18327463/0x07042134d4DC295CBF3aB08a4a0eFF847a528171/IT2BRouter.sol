// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title IT2BRouter
 * @notice Interface for T2B Router.
 * @dev functions can be added here for invocation from external contracts or off-chain
 * @author Socket dot tech.
 */
abstract contract IT2BRouter {
    // tokenlist in IT2BRouter
    address[] public supportedTokens;
}
