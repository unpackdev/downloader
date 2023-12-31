// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

struct FeeData {
    address receiverFeeAddr;
    uint256 platformFee;
    uint256 ownerFee;
    uint256 creatorFee;
    address creatorFeeAddr;
}

struct Transfer20FeeData {
    uint256 platformFee;
    uint256 creatorFee;
    address creatorFeeAddr;
}

struct AssetIdentifierData {
    address registry;
    uint256 tokenId;
}

struct Transfer1155WithSignData {
    AssetIdentifierData assetIdentifierData;
    address from;
    address to;
    uint256 value;
    FeeData feeData;
    uint256 nonce;
    uint256 deadline;
    uint256 salt;
    uint32 metadata;
    bytes data;
    bytes signature;
}

struct Transfer721WithSignData {
    AssetIdentifierData assetIdentifierData;
    address to;
    FeeData feeData;
    uint256 nonce;
    uint256 deadline;
    uint256 salt;
    uint32 metadata;
    bytes signature;
}
