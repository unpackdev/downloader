// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./Initializable.sol";
import "./LibTransfer.sol";
import "./LibAsset.sol";

abstract contract TransferExecutor is
    Initializable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using LibTransfer for address;

    function __TransferExecutor_init_unchained() internal {}

    function _transfer(
        LibAsset.Asset memory asset,
        address from,
        address to
    ) internal {
        if (asset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS) {
            to._transferEth(asset.value);
        } else if (asset.assetType.assetClass == LibAsset.ERC20_ASSET_CLASS) {
            address token = abi.decode(asset.assetType.data, (address));
            SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(token), from, to, asset.value);
        } else if (asset.assetType.assetClass == LibAsset.ERC721_ASSET_CLASS) {
            require(asset.value == 1, "erc721 value error");
            IERC721Upgradeable(asset.token).safeTransferFrom(from, to, asset.tokenId, "");
        } else if (asset.assetType.assetClass == LibAsset.ERC1155_ASSET_CLASS) {
            IERC1155Upgradeable(asset.token).safeTransferFrom(
                from,
                to,
                asset.tokenId,
                asset.value,
                ""
            );
        } else {
            revert("asetClass is invalid");
        }
    }
}
