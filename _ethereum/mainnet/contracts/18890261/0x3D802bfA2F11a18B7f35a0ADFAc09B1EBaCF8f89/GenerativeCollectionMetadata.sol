// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

struct GenerativeCollectionMetadata {
    string name;
    string symbol;
    uint256 maxMint;
    uint256 totalSupply;
    uint256 mintPrice;
    address currency;
    uint256 saleStartTime;
    uint256 saleEndTime;
    uint256 presaleMintPrice;
    uint256 presaleMaxMint;
    bytes32 merkleRoot;
    uint256 presaleStartTime;
    uint256 presaleEndTime;
    uint256 revealDate;
    bytes32 baseUriHash;
    string baseURI;
    string contractURI;
}