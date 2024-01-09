// SPDX-License-Identifier: MIT LICENSE
pragma solidity =0.8.11;

enum SalesState {
    Closed,
    Active,
    AccessToken,
    Maintenance,
    Finalized
}

struct GaucheSale {
    SalesState saleState;
    uint16 maxPublicTokens;
    uint64 pricePerToken;
    address accessTokenAddress;
}
struct GaucheToken {
    uint256 tokenId;
    uint256 free;
    uint256 spent;
    bool burned;
    bytes32[] ownedHashes;
}

struct GaucheLevel {
    uint8 wordPrice;
    uint64 price;
    address artistAddress;
    string baseURI;
}
