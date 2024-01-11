// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "./IBatchStorage.sol";
import "./AbstractBatchStorage.sol";

abstract contract AbstractViewableBatchStorage {
  AbstractBatchStorage public batchStorage;

  constructor() {}

  /**
   * @notice Get ids for all batches that a user has interacted with
   * @param _account The address for whom we want to retrieve batches
   */
  function getAccountBatches(address _account) external view returns (bytes32[] memory) {
    return batchStorage.getAccountBatches(_account);
  }

  function getAccountBalance(bytes32 _id, address _owner) public view virtual returns (uint256) {
    return batchStorage.accountBalances(_id, _owner);
  }

  function getAccountBatchIds(address account) public view returns (bytes32[] memory) {
    return batchStorage.getAccountBatches(account);
  }

  function getBatch(bytes32 batchId) public view virtual returns (Batch memory) {
    return batchStorage.getBatch(batchId);
  }

  /* ========== VIEWS ========== */

  function getBatchType(bytes32 batchId) external view virtual returns (BatchType) {
    Batch memory batch = batchStorage.getBatch(batchId);
    require(batch.batchId != "");
    return batch.batchType;
  }
}
