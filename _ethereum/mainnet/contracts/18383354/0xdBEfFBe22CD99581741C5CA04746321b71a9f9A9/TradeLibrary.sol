// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./SafeERC20Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./IERC721Upgradeable.sol";

import "./Structs.sol";

library TradeLibrary {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using TradeLibrary for Structs.Asset;
    using TradeLibrary for Structs.Asset[];

    error TaxedAssetUnsupported();
    error UnknownAssetType();

    function safeTransfer721From(Structs.Asset storage asset, address from, address to) internal {
        IERC721Upgradeable(asset._address).safeTransferFrom(from, to, asset.id);
    }

    // Checks for token fees
    function safeTransfer1155From(Structs.Asset storage asset, address from, address to) internal {
        IERC1155Upgradeable t = IERC1155Upgradeable(asset._address);

        uint256 originalBalance = t.balanceOf(to, asset.id);
        t.safeTransferFrom(from, to, asset.id, asset.amount, "");
        uint256 newBalance = t.balanceOf(to, asset.id);

        if (newBalance - originalBalance != asset.amount) revert TaxedAssetUnsupported();
    }

    // Checks for token fees
    function safeTransfer20From(Structs.Asset storage asset, address from, address to) internal {
        IERC20Upgradeable t = IERC20Upgradeable(asset._address);

        uint256 originalBalance = t.balanceOf(to);
        t.safeTransferFrom(from, to, asset.amount);
        uint256 newBalance = t.balanceOf(to);

        if (newBalance - originalBalance != asset.amount) revert TaxedAssetUnsupported();
    }

    function safeTransfer(Structs.Asset storage asset, address from, address to) internal {
        if (asset.assetType == Structs.AssetType.ERC20) {
            asset.safeTransfer20From(from, to);
        } else if (asset.assetType == Structs.AssetType.ERC721) {
            asset.safeTransfer721From(from, to);
        } else if (asset.assetType == Structs.AssetType.ERC1155) {
            asset.safeTransfer1155From(from, to);
        } else {
            revert UnknownAssetType();
        }
    }

    function safeTransfer(Structs.Asset[] storage assets, address from, address to) internal {
        uint256 len = assets.length;
        for (uint256 i = 0; i < len ; i++) {
            safeTransfer(assets[i], from, to);
        }
    }

    function safeTransfer(Structs.Trade storage trade) internal {
        trade.partyAssets.safeTransfer(trade.party, trade.counterparty);
        trade.counterpartyAssets.safeTransfer(trade.counterparty, trade.party);
    }
}