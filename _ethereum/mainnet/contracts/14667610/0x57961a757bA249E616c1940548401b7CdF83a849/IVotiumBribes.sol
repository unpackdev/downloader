// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IVotiumBribes {
    struct claimParam {
        address token;
        uint256 index;
        uint256 amount;
        bytes32[] merkleProof;
    }

    function claimMulti(address account, claimParam[] calldata claims) external;
    function claim(address token, uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external;
}