// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MarketplaceFeeEngineStorage {
    uint256 public platformFee;
    address payable public feeReceipient;
    mapping(bytes32 => mapping(address => bool)) public validCollections;
    mapping(bytes32 => address payable[]) public marketplaceRecipients;
    mapping(bytes32 => uint256[]) public marketplaceFees;
    mapping(bytes32 => mapping(address => uint256[]))
        public marketplaceFeesByCurrency;
}
