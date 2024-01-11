// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AssetLib {
    bytes4 public constant ETH_ASSET_CLASS = bytes4(keccak256("ETH"));
    bytes4 public constant ERC20_ASSET_CLASS = bytes4(keccak256("ERC20"));
    bytes4 public constant ERC721_ASSET_CLASS = bytes4(keccak256("ERC721"));
    bytes4 public constant ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155"));
    bytes4 public constant COLLECTION = bytes4(keccak256("COLLECTION"));

    bytes32 constant ASSET_TYPE_TYPEHASH =
        keccak256("AssetType(bytes4 assetClass,bytes data)");
    bytes32 constant ASSET_TYPEHASH =
        keccak256(
            "AssetData(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)"
        );

    struct AssetType {
        bytes4 assetClass;
        bytes data;
    }
    struct AssetData {
        AssetType assetType;
        uint256 value;
    }

    function decodeAssetTypeData(AssetType memory assetType)
        internal
        pure
        returns (address, uint256)
    {
        if (assetType.assetClass == AssetLib.ERC20_ASSET_CLASS) {
            address token = abi.decode(assetType.data, (address));
            return (token, 0);
        } else if (
            assetType.assetClass == AssetLib.ERC721_ASSET_CLASS ||
            assetType.assetClass == AssetLib.ERC1155_ASSET_CLASS
        ) {
            (address token, uint256 tokenId) = abi.decode(
                assetType.data,
                (address, uint256)
            );
            return (token, tokenId);
        }
        return (address(0), 0);
    }

    function hash(AssetType memory assetType) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ASSET_TYPE_TYPEHASH,
                    assetType.assetClass,
                    keccak256(assetType.data)
                )
            );
    }

    function hash(AssetData memory asset) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(ASSET_TYPEHASH, hash(asset.assetType), asset.value)
            );
    }
}
