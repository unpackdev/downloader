// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
/* Gambulls LibAsset 2023 */

library LibAsset {
    bytes4 constant public ETH_ASSET_CLASS = bytes4(keccak256("ETH"));
    bytes4 constant public ERC20_ASSET_CLASS = bytes4(keccak256("ERC20")); // wrappedTokenAddress
    bytes4 constant public ERC721_ASSET_CLASS = bytes4(keccak256("ERC721")); // tokenAddress, tokenId
    bytes4 constant public ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155")); // tokenAddress, tokenId
    bytes4 constant public COLLECTION = bytes4(keccak256("COLLECTION")); // tokenAddress

    bytes32 constant ASSET_TYPE_TYPEHASH = keccak256(
        "AssetType(bytes4 assetClass,bytes data)"
    );

    bytes32 constant ASSET_TYPEHASH = keccak256(
        "Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)"
    );

    struct AssetType {
        bytes4 assetClass;
        bytes data;
    }

    struct Asset {
        AssetType assetType;
        uint256 value;
    }

    function hash(AssetType memory assetType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            ASSET_TYPE_TYPEHASH,
            assetType.assetClass,
            keccak256(assetType.data)
        ));
    }

    function hash(Asset memory asset) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            ASSET_TYPEHASH,
            hash(asset.assetType),
            asset.value
        ));
    }

}