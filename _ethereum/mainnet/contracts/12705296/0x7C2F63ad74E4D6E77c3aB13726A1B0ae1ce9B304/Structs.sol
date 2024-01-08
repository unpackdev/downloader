// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Structs {
    struct RoyaltyReceiver {
        address payable wallet;
        string role;
        uint256 percentage;
        uint256 resalePercentage;
        uint256 CAPPS;
        uint256 fixedCut;
    }

    struct Party {
        string role;
        address wallet;
    }

    struct Policy {
        string action;
        uint256 target;
        Party permission;
    }

    struct SupportedAction {
        string action;
        string group;
    }

    struct BasicOperation {
        string operation;
    }
}