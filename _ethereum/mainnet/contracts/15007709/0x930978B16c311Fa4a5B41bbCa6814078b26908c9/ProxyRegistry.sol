// SPDX-License-Identifier: MIT
// Creator: https://github.com/cowlony-org

pragma solidity ^0.8.4;

/**
 @dev Helpers to implement free listings on OpenSea
 *    implementation is based on the official guideline:
 *    https://docs.opensea.io/docs/1-structuring-your-smart-contract
 */

contract OwnableDelegateProxy { }

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}