// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUnityCards {

  function allowListClaimedBy(address owner) external returns (uint256);

  function purchase(uint256 numberOfTokens) external;

  function freeClaimAllowList(uint256 index, uint256 numberOfTokens, bytes32[] calldata proof) external;

  function freeClaimAllowListBatch(uint256 index, uint256 numberOfTokens,uint256 numberOfTokensClaimed, bytes32[] calldata proof) external;

  function setBatchClaimState(address account, bool state) external;

  function setIsActive(bool isActive) external;

  function setIsAllowListActive(bool isAllowListActive) external;

  function setMerkleRoot(bytes32 root) external;

  function setPurchaseLimit(uint256 limit) external;

  function withdraw() external;
}