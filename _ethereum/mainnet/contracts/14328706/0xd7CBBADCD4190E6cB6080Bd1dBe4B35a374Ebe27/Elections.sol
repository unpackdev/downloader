// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./EnumerableSet.sol";

import "./ElectionsPrincipal.sol";

library Elections {
    using EnumerableSet for EnumerableSet.AddressSet;

    function findTop2(
        EnumerableSet.AddressSet storage voters,
        ElectionsPrincipal principal
    )
        public
        view
        returns (
            address winningCandidate,
            uint256 winningCandidateVotes,
            uint256 runnerUpCandidateVotes,
            uint256 totalVotes
        )
    {
        (
            address[2500] memory candidatesList,
            uint256[2500] memory candidatesVotes,
            uint256 candidatesCount,
            uint256 totalVotes_
        ) = _convertVotersList(voters, principal);

        require(candidatesCount > 0, "no candidates");

        totalVotes = totalVotes_;

        for (uint256 j = 0; j < candidatesCount; j++) {
            uint256 votes = candidatesVotes[j];

            if (votes > winningCandidateVotes) {
                runnerUpCandidateVotes = winningCandidateVotes;

                winningCandidate = candidatesList[j];
                winningCandidateVotes = votes;
            } else if (votes > runnerUpCandidateVotes) {
                runnerUpCandidateVotes = votes;
            }
        }
    }

    function sumVotesFor(
        address expectedCandidate,
        address[] memory selectedVoters,
        ElectionsPrincipal principal
    ) public view returns (uint256 votes) {
        address prevVoter;
        for (uint256 j = 0; j < selectedVoters.length; j++) {
            address voter = selectedVoters[j];
            address candidate = principal.candidateOf(voter);
            if (
                candidate == expectedCandidate &&
                prevVoter < voter
            ) {
                votes += principal.votesOf(voter);
                prevVoter = voter;
            }
        }
    }

    function sumVotesExceptZeroAnd(
        address excludedCandidate,
        address[] memory selectedVoters,
        ElectionsPrincipal principal
    ) public view returns (uint256 votes) {
        address prevVoter;
        for (uint256 i = 0; i < selectedVoters.length; i++) {
            address voter = selectedVoters[i];
            address candidate = principal.candidateOf(voter);
            if (
                candidate != excludedCandidate &&
                candidate != address(0) &&
                prevVoter < voter
            ) {
                votes += principal.votesOf(voter);
                prevVoter = voter;
            }
        }
    }

    function calcConsensus(uint256 votes, uint256 totalVotes)
        public
        pure
        returns (bool)
    {
        return votes > (totalVotes / 2);
    }

    function _convertVotersList(
        EnumerableSet.AddressSet storage voters,
        ElectionsPrincipal principal
    )
        private
        view
        returns (
            address[2500] memory candidatesList,
            uint256[2500] memory candidatesVotes,
            uint256 candidatesCount,
            uint256 totalVotes
        )
    {
        for (uint256 i = 0; i < voters.length(); i++) {
            address voter = voters.at(i);
            uint256 voterBalance = principal.votesOf(voter);
            address candidate = principal.candidateOf(voter);

            if (voterBalance > 0 && candidate != address(0)) {
                totalVotes += voterBalance;

                (bool found, uint256 foundIndex) = _findIndex(
                    candidate,
                    candidatesList,
                    candidatesCount
                );

                if (found) {
                    candidatesVotes[foundIndex] += voterBalance;
                } else {
                    candidatesList[candidatesCount] = candidate;
                    candidatesVotes[candidatesCount] = voterBalance;
                    candidatesCount++;
                }
            }
        }
    }

    function _findIndex(
        address predicate,
        address[2500] memory array,
        uint256 length
    ) private pure returns (bool found, uint256 index) {
        for (uint256 j = 0; j < length; j++) {
            if (predicate == array[j]) {
                return (true, j);
            }
        }
    }
}
