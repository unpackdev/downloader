// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IServiceV18 {
  function doesNodeExist(address entity, uint128 nodeId) external view returns (bool);

  function hasNodeExpired(address entity, uint128 nodeId) external view returns (bool);

  function claim(uint128 nodeId, uint blockNumber, bool toStrongPool) external payable returns (uint);

  // @deprecated
  function isEntityActive(address entity) external view returns (bool);
}
