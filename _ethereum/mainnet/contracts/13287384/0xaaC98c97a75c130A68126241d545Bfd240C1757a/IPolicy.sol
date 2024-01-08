// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./DataStruct.sol";

/**
 * @dev Interface of Policy in Elyfi governance
 */
interface IPolicy {
  function validateProposer(address account, uint256 blockNumber) external view returns (bool);

  function validateVoter(address account, uint256 blockNumber) external view returns (bool);

  function getVotes(address account, uint256 blockNumber) external view returns (uint256);

  function voteSucceeded(DataStruct.ProposalVote memory proposal) external view returns (bool);

  function quorumReached(DataStruct.ProposalVote memory proposal, uint256 blockNumber)
    external
    view
    returns (bool);

  function quorum(uint256 blockNumber) external view returns (uint256);
}
