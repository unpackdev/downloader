// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.11;

interface IJokerRace {

    function castVote(uint256 proposalId, uint8 support, uint256 totalVotes, uint256 numVotes, bytes32[] calldata proof) external;
}
