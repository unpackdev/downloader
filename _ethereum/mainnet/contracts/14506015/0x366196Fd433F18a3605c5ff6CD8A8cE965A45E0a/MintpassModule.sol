// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IQuantumMintPass.sol";
import "./Auth.sol";

abstract contract MintpassModule is Auth {

    struct MPClaim {
        uint64 mpId;
        uint64 start;
        uint128 price;
    }

    mapping (uint256 => MPClaim) public mpClaims;
    IQuantumMintPass public mintpass;

    function setMintpass(address deployedMP) requiresAuth public {
        mintpass = IQuantumMintPass(deployedMP);
    }

    function createMPClaim(uint256 dropId, uint64 mpId, uint64 start, uint128 price) requiresAuth public {
        mpClaims[dropId] = MPClaim(mpId, start, price);
    }

    function flipMPClaimState(uint256 dropId) requiresAuth public {
        mpClaims[dropId].start = mpClaims[dropId].start > 0 ? 0 : type(uint64).max;
    }

    function _claimWithMintPass(uint256 dropId, uint256 amount) internal {
        MPClaim memory mpClaim = mpClaims[dropId];
        require(block.timestamp >= mpClaim.start, "MP: CLAIMING INACTIVE");
        require(msg.value == amount * mpClaim.price, "MP:WRONG MSG.VALUE");
        mintpass.burnFromRedeem(msg.sender, mpClaim.mpId, amount); //burn mintpasses
    }
}