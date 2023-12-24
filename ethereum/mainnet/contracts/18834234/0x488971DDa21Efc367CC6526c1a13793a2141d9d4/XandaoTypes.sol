// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

struct TokenInfo {
    string description;
    address creator;
    string creatorName;
    uint256 xn;
    string xnVersion;
    uint256 upgradedFrom;
    bool burnStatus;
}
