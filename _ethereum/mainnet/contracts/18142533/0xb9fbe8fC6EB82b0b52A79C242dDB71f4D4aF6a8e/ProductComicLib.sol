// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library ProductComicLib {
    /// @notice Keeps track of comic purchase to be updated upon VRF fullfil call
    struct Request {
        address owner;
        bool isAssigned;
        uint256 numComicsToSend;
        uint256 transactionId;
    }
}
