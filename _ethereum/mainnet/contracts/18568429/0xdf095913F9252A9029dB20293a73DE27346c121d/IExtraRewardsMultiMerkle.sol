// SPDX-License-Identifier: AGPLv3

pragma solidity ^0.8.13;

interface IExtraRewardsMultiMerkle {
    struct ClaimParams {
        address token;
        uint256 index;
        uint256 amount;
        bytes32[] merkleProof;
    }

    function multiClaim(address account, ClaimParams[] calldata claims) external;
}
