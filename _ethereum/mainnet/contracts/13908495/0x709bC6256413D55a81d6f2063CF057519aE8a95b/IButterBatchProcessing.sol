// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

enum BatchType {
  Mint,
  Redeem
}

struct Batch {
  BatchType batchType;
  bytes32 batchId;
  bool claimable;
  uint256 unclaimedShares;
  uint256 suppliedTokenBalance;
  uint256 claimableTokenBalance;
  address suppliedTokenAddress;
  address claimableTokenAddress;
}

interface IButterBatchProcessing {
  function batches(bytes32 batchId) external view returns (Batch memory);

  function depositForMint(uint256 amount_, address account_) external;

  function claim(bytes32 batchId_, address account_) external returns (uint256);

  function withdrawFromBatch(
    bytes32 batchId_,
    uint256 amountToWithdraw_,
    address account_
  ) external;
}
