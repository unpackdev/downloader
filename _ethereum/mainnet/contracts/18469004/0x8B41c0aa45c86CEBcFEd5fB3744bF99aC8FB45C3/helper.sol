// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

error InvalidAmount();
error InvalidTime();
error AlreadyClaimed();
error ClaimNotStarted();
error ClaimClosed();
error ClaimLimitReached();
error IncorrectProof();
error IncorrectUserAddress();
error InsufficientBalance();
error HasAllowanceMechanism();
error MaxReached();
error InvalidAddress();

bytes32 constant MODERATOR = keccak256("MODERATOR");

enum CLAIM_PERMISSION {
    TokenGated,
    Whitelisted,
    FreeForAll,
    Prorata
}

struct ClaimSettings {
    string name; //Claim name
    address creatorAddress; //Address of claim creator
    address walletAddress; //Address of Safe/EOA
    address airdropToken; //Address of token to airdrop
    address daoToken; //Address of DAO token
    uint256 tokenGatingValue; //Minimum amount required for token gating
    uint256 startTime; //Start time of claim
    uint256 endTime; //End time of claim
    uint256 cooldownTime; //Time period after which users can receive tokens
    bool hasAllowanceMechanism; //To check if token transfer is based on allowance
    bool isEnabled; //To check if claim is enabled or not
    bytes32 merkleRoot; //Merkle root to validate proof
    CLAIM_PERMISSION permission;
    ClaimAmountDetails claimAmountDetails;
}

struct ClaimAmountDetails {
    uint256 maxClaimable; //fixed claimable amount
    uint256 totalClaimAmount; //Total claim amount
}

struct CoolDownClaimDetails {
    uint256 unlockTime; //Time to unlock
    uint256 unlockAmount; //Amount to unlock
}
