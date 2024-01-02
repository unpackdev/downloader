// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface ToVInfos {
    struct ToV {
        uint64 season;
        uint64 seasonTraitCount;
        uint256 dna;
    }
    
    struct ContractData {
        string name;
        string collectionName;
        string description;
        string image;
        string banner;
        string website;
        string royalties;
        string royaltiesRecipient;
    }
}