// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @dev Type for individual asset along with it's details
/// @param token token address
/// @param assetType type of asset represented by the address
/// @param tokenId tokenId in case of ERC721 and ERC1155 tokens. Set to 0 in case of ERC20 token
/// @param amount amount of token for ERC20 and ERC1155 tokens. Set to 1 in case of ERC721 token
struct AssetData {
    address token;
    AssetType assetType;
    uint256 tokenId;
    uint256 amount;
}

/// @dev Common Assets type, packing bundle of NFTs and FTs.
/// @param assets Array of individual tokens along with their details
struct Assets {
    AssetData[] assets;
}

/// @dev Broker and platform fee info
/// @param token Fee token address
/// @param broker Broker address
/// @param platform Platform address
/// @param brokerAmount Broker fee
/// @param platformAmount Platform fee
struct Fees {
    address token;
    address broker;
    address platform;
    uint256 brokerAmount;
    uint256 platformAmount;
}

/// @dev Common Trade data type used by broker while setting up trade
/// @param makerAssets Assets offered by the maker
/// @param takerAssets Assets offered by the taker
/// @param makerFees Fees offered by the maker
/// @param takerFees Fees offered by the taker
/// @param maker Maker's address
/// @param taker Taker's address
/// @param duration Trade duration
/// @param makerNonce Nonce of maker
/// @param takerNonce Nonce of taker
struct TradeInfo {
    Assets makerAssets;
    Assets takerAssets;
    Fees makerFees;
    Fees takerFees;
    address maker;
    address taker;
    uint256 duration;
    uint256 makerNonce;
    uint256 takerNonce;
}

enum AssetType {
    INVALID,
    ERC_20,
    ERC_721,
    ERC_1155,
    KITTIES,
    PUNK
}
