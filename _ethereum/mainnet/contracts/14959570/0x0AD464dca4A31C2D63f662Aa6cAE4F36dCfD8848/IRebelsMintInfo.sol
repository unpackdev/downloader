// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRebelsMintInfo {
  function getMintName() external view returns (string memory);
  function getMintActive() external view returns (bool);
  function getMintStartTime() external view returns (uint256);
  function getMintEndTime() external view returns (uint256);

  function getProofRequired() external view returns (bool);
  function getTotalMintLimit() external view returns (uint256);
  function getTotalMintCount() external view returns (uint256);

  function getUserMintPrice(address user, bytes32[] memory senderData) external view returns (uint256);
  function getUserMintLimit(address user, bytes32[] memory senderData) external view returns (uint256);
  function getUserMintCount(address user) external view returns (uint256);
}
