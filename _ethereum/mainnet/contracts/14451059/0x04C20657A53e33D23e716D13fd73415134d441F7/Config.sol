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
        "c37f91a7b0f2dcc96856ce0dc44fe975252a28e2bf04d53a72c858922478452d";

    string public constant ERROR_TOKEN_ID = "Invalid token id";
    string public constant ERROR_REVEALED = "Already revealed";
}
