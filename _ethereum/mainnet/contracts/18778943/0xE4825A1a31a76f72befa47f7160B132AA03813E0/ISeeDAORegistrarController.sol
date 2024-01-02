// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ISeeDAORegistrarController {
  error CommitmentTooNew(bytes32);
  error CommitmentTooOld(bytes32);

  error ReachedMaxOwnedNumberLimit(uint256 value, uint256 max);

  event MinterChanged(address indexed addr, bool enabled);

  event NameRegistered(uint256 indexed id, string name, address owner);

  event NameReclaimed(uint256 indexed id, string name, address newSNSOwner);

  function available(string memory name) external returns (bool);

  function valid(string memory name) external pure returns (bool);

  function balanceOf(address owner) external view returns (uint256);

  function maxOwnedNumberReached(address owner) external view returns (bool);

  function nextTokenId() external returns (uint256);

  function makeCommitment(
    string memory name,
    address owner,
    address resolver,
    bytes32 secret
  ) external returns (bytes32);

  function commit(bytes32 commitment) external;

  function registerWithCommitment(
    string memory name,
    address owner,
    address resolver,
    bytes32 secret
  ) external;

  function register(
    string memory name,
    address owner,
    address resolver
  ) external;

  function reclaim(
    string memory name,
    address newSNSOwner,
    address resolver
  ) external;

  function setDefaultName(string memory destName, address resolver) external;

  function setDefaultAddr(
    string memory name,
    address destAddr,
    address resolver
  ) external;
}
