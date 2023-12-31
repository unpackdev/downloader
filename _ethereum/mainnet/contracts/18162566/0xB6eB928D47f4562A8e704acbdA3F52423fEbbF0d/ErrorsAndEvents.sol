// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract ErrorsAndEvents {
  bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  bytes32 public constant UPGRADER_ROLE = keccak256('UPGRADER_ROLE');

  event BaseUriUpdated(string tokenURI);
  event ContractUriUpdated(string contractURI);
  event MaxLimitChanged(uint256 maxLimit);

  event ManagerAdded(address manager);
  event ManagerRemoved(address manager);
  event MinterAdded(address minter);
  event MinterRemoved(address minter);
  event UpgraderAdded(address upgrader);
  event UpgraderRemoved(address upgrader);

  error NotManager();
  error NotMinter();
  error NotUpgrader();
  error MaxLimitReached(uint256 limit);
}
