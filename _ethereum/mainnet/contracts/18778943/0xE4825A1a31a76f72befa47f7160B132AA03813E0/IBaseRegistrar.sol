// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IBaseRegistrar {
  event NameRegistered(uint256 indexed id, address indexed owner);

  event NameReclaimed(uint256 indexed id, address indexed newSNSOwner);

  function available(bytes32 label) external view returns (bool);

  function nextTokenId() external view returns (uint256);

  function register(bytes32 label, address owner, address resolver) external;

  function reclaim(bytes32 label, address newSNSOwner) external;
}
