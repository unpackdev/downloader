// contracts/structs.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

struct Project {
    uint256 id;

    uint256 maxSupply;
    uint256 minted;

    uint256 burnFee;

    uint256[] attributeCategoryIds;
    string name;
    string description;
    string ipfs;
    bool mintable;
}

struct AttributeProbability {
    uint256 attributeId;
    uint256 probability;
}



