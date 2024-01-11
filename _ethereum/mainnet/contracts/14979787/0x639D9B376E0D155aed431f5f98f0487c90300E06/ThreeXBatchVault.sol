// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "./AbstractBatchStorage.sol";
import "./AbstractViewableBatchStorage.sol";
import "./ContractRegistryAccess.sol";

contract ThreeXBatchVault is AbstractBatchStorage {
  bytes32 public contractId = keccak256("ThreeXBatchStorage");
  string public name = "3X Batch Vault v1";

  constructor(IContractRegistry _contractRegistry, address client) AbstractBatchStorage(_contractRegistry, client) {}
}
