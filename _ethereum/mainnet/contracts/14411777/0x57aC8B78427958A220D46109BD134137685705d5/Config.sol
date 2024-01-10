// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

abstract contract Config {
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant RESERVED_TOKENS = 50;
    uint256 public constant PRICE = 0.05 ether;
    uint256 public constant MAX_PER_MINT = 3;
    uint256 public constant MAX_PRE_SALE_MINT = 3;

    string public constant UNREVEALED_URI = "ipfs://QmU7Tuzo5qFXqDTdyebNqHqaZG7afMwrfT2Ms7BGxpE268";

    /**
     * Buyers can verify that the collection was not altered prior to the mint.
     * This is a SHA256 hash of the concatenation of each image SHA256 hashes, arranged in the mint order
     */
    string public constant PROVENANCE_HASH =
        "071f617adfb22c0aa60c0a8df9f6dcf1970707f7736bddc7d9e9098452eb7e70";

    string public constant ERROR_FUNDS = "Not enough ether";
    string public constant ERROR_MAX_PER_MINT = "Max per mint reached";
    string public constant ERROR_MAX_PRE_SALE_MINT = "Max pre-sale mint reached";
    string public constant ERROR_MAX_SUPPLY = "Max supply reached";
    string public constant ERROR_SALE = "Invalid sale status";
    string public constant ERROR_PRE_SALE_SIGNATURE = "Invalid pre-sale signature";
    string public constant ERROR_RESERVED_MINTED = "Reserved tokens already minted";
    string public constant ERROR_CONTRACT_MINT = "Can't mint from contract";
    string public constant ERROR_TOKEN_ID = "Invalid token id";
    string public constant ERROR_REVEALED = "Already revealed";
}
