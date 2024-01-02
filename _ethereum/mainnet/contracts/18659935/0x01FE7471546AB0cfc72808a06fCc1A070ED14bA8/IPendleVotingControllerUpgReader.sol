// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPendleVotingControllerUpgReader {
    struct VeBalance {
        uint128 bias;
        uint128 slope;
    }

    struct UserPoolData {
        uint64 weight;
        VeBalance vote;
    }

    function getUserData(
        address user,
        address[] calldata pools
    ) external view returns (uint64 totalVotedWeight, UserPoolData[] memory voteForPools);
}