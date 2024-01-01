// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface Structs {
    enum AssetType {
        ERC20,
        ERC1155,
        ERC721
    }

    enum Status {
        Open,
        Accepted,
        Rejected,
        Canceled
    }
    // Token struct to hold relevant data required to create and reference an ERC20/ERC1155/ERC721 token
    struct Asset {
        address _address;
        uint256 id;
        uint256 amount;
        AssetType assetType;
    }

    // Swap struct to hold the data for a single trade
    struct Trade {
        Status status;
        address party;
        address counterparty;
        Asset[] partyAssets;
        Asset[] counterpartyAssets;
    }
}