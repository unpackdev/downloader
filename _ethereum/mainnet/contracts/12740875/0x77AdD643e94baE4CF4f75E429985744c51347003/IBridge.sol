// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

interface IBridge {
  function executionPermit (address vault, bytes32 proposalId) external view returns (bytes32);
  function deposit (address token, uint256 amountOrId, address receiver) external;
}
