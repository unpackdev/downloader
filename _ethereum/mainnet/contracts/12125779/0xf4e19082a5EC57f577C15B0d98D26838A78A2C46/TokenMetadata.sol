pragma solidity >=0.6.0 <0.9.0;
//SPDX-License-Identifier: MIT

struct TokenMetadata {
    bool exists;
    uint256 tokenId;
    address erc20ContractAddress;
    uint256 jNumber;
    uint256 claimableRenameFees;
    bool hasFreeRename;
    string name;
    address ownerAddress;
}
