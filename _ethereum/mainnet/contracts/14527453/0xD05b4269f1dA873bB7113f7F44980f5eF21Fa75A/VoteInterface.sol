// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface VoteInterface {
  function getPriorProposalVotes(address account, uint256 blockNumber) external view returns (uint96);

  function updateVotes(
    address voter,
    uint256 rawAmount,
    bool adding
  ) external;
}
