// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

struct NFTDataAttributes {
    string hashString;
    uint256 sold;
    address[] owners;
    uint256[] tokens;
}
struct Collection {
    string title;
    uint price;
    uint16 editions;
}

struct ContractData {
    string APIEndpoint;
    bool isActive;
    address payable beneficiary;
}
