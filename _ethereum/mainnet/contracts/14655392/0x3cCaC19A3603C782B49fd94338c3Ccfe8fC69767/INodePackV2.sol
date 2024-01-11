// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface INodePackV2 {
  function doesPackExist(address entity, uint packId) external view returns (bool);

  function hasPackExpired(address entity, uint packId) external view returns (bool);

  function claim(uint packId, uint timestamp, address toStrongPool) external payable returns (uint);

  function getPackId(address _entity, uint _packType) external pure returns (bytes memory);

  function getEntityPackTotalNodeCount(address _entity, uint _packType) external view returns (uint);

  function getEntityPackActiveNodeCount(address _entity, uint _packType) external view returns (uint);

  function migrateNode(address _entity, uint _nodeType, uint _nodeCount, uint _lastPaidAt) external returns (bool);
}
