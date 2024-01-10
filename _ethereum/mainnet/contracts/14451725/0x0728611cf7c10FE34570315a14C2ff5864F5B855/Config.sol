// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

abstract contract Config {
    uint256 public constant MAX_SUPPLY = 444;

    string public constant UNREVEALED_URI = "ipfs://QmU7Tuzo5qFXqDTdyebNqHqaZG7afMwrfT2Ms7BGxpE268";

    /**
     * Buyers can verify that the collection was not altered prior to the mint.
     * This is a SHA256 hash of the IPFS URI hash of the metadata folder.
     */
    string public constant PROVENANCE_HASH =
        "4b31b1cdc093693c57927865e2ee21e74d0a2d9f3b6a7ea2b980346a5224dc26";

    string public constant ERROR_TOKEN_ID = "Invalid token id";
    string public constant ERROR_REVEALED = "Already revealed";
}
