// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface StrongNFTBonusInterface {
  function getBonus(address _entity, uint128 _nodeId, uint256 _fromBlock, uint256 _toBlock) external view returns (uint256);
}
