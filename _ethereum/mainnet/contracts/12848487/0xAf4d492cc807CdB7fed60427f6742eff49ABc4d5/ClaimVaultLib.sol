//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/// @title Function for getting the current chain ID
library ClaimVaultLib {
    struct ClaimedInfo {
        bool joined;
        uint256 claimedTime;
    }

    struct TgeInfo {
        bool allocated;
        bool started;
        uint256 allocatedAmount;
        uint256 claimedCount;
        uint256 amount;
        address[] whitelist;
        mapping(address => ClaimedInfo) claimedTime;
    }
}
