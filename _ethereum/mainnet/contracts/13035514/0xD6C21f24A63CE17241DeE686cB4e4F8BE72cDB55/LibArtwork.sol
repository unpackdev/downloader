// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibArtwork {
    struct Artwork {
        address creator;
        uint32 printIndex;
        uint32 totalSupply;
        string metadataPath;
        address royaltyReceiver;
        uint256 royaltyBps; // royaltyBps is a value between 0 to 10000
    }

    struct ArtworkRelease {
        // The unique edition number of this artwork release
        uint32 printEdition;
        // Reference ID to the artwork metadata
        uint256 artworkId;
    }

    struct ArtworkOnSaleInfo {
        address takeTokenAddress; // only accept erc20, should use WETH
        uint256 takeAmount;
        uint256 startBlock;
        uint256 endBlock;
        uint256 purchaseLimit;
    }
}
