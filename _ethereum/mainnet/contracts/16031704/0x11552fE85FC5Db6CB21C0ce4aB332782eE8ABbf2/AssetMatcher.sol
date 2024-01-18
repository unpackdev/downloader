// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./LibOrder.sol";
import "./Initializable.sol";

abstract contract AssetMatcher is Initializable {
    
    // matchAssets
    function _matchAssets(
        LibAsset.AssetType calldata leftAssetType,
        LibAsset.AssetType calldata rightAssetType,
        LibOrder.Order calldata order
    ) internal view returns (LibAsset.AssetType memory) {
        LibAsset.AssetType memory result = _matchAssetOneSide(
            leftAssetType,
            rightAssetType,
            order
        );
        if (result.assetClass == 0) {
            return _matchAssetOneSide(rightAssetType, leftAssetType, order);

        } else {
            return result;
        }
    }

    function _matchAssetOneSide(
        LibAsset.AssetType calldata leftAssetType,
        LibAsset.AssetType calldata rightAssetType,
        LibOrder.Order calldata order
    ) private view returns (LibAsset.AssetType memory) {
        bytes4 classLeft = leftAssetType.assetClass;
        bytes4 classRight = rightAssetType.assetClass;
        if (classLeft == LibAsset.ETH_ASSET_CLASS) {
            if (classRight == LibAsset.ETH_ASSET_CLASS) {
                return leftAssetType;
            }
            if (
                msg.sender == order.maker &&
                classRight == LibAsset.ERC20_ASSET_CLASS
            ) {
                return rightAssetType;
            }
            return LibAsset.AssetType(0, "");
        }
        if (classLeft == LibAsset.ERC20_ASSET_CLASS) {
            if (classRight == LibAsset.ERC20_ASSET_CLASS) {
                return _simpleMatch(leftAssetType, rightAssetType);
            }
            return LibAsset.AssetType(0, "");
        }
        if (classLeft == LibAsset.ERC721_ASSET_CLASS) {
            if (classRight == LibAsset.ERC721_ASSET_CLASS) {
                return _simpleMatch(leftAssetType, rightAssetType);
            }
            return LibAsset.AssetType(0, "");
        }
        if (classLeft == LibAsset.ERC1155_ASSET_CLASS) {
            if (classRight == LibAsset.ERC1155_ASSET_CLASS) {
                return _simpleMatch(leftAssetType, rightAssetType);
            }
            return LibAsset.AssetType(0, "");
        }
        if (classLeft == classRight) {
            return _simpleMatch(leftAssetType, rightAssetType);
        }
        return _simpleMatch(leftAssetType, rightAssetType);
    }

    function _simpleMatch(
        LibAsset.AssetType calldata leftAssetType,
        LibAsset.AssetType calldata rightAssetType
    ) private pure returns (LibAsset.AssetType memory) {
        bytes32 leftHash = keccak256(leftAssetType.data);
        bytes32 rightHash = keccak256(rightAssetType.data);
        if (leftHash == rightHash) {
            return leftAssetType;
        }
        return LibAsset.AssetType(0, "");
    }
}
