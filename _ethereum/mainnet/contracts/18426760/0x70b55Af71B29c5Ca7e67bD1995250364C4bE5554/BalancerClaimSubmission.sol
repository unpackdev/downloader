// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

contract BalancerClaimSubmission {
    uint256 public claimDeadline;

    event ClaimSubmitted(address indexed userAddress, string network, bytes32[] txHashes);
    
    error SubmissionDeadlinePassed();

    constructor(uint256 claimDuration) {
        claimDeadline = block.timestamp + claimDuration;
    }

    function submitClaim(string memory network, bytes32[] memory txHashes) public {
        if (block.timestamp > claimDeadline) {
            revert SubmissionDeadlinePassed();
        }

        emit ClaimSubmitted(msg.sender, network, txHashes);
    }
}