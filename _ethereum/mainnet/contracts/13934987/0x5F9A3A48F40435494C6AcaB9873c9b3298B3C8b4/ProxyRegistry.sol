// contracts/ProxyRegistry.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract OwnableDelegateProxy {}

/// @notice Used to delegate ownership of a contract to another address,
/// to save on unneeded transactions to approve contract use for users.
contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}
