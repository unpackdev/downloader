// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Address.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./ITransferProxy.sol";
import "./AssetLib.sol";
import "./AdminController.sol";

/**
 * @title MarketTransfer
 * MarketTransfer - This contract manages the transfer for Market.
 */
abstract contract MarketTransfer is
    ERC721Holder,
    ERC1155Holder,
    AdminController
{
    using Address for address;
    using SafeERC20 for IERC20;

    mapping(bytes4 => address) private _proxies;

    event ProxyUpdated(bytes4 indexed assetType, address proxy);
    event Transferred(AssetLib.AssetData asset, address from, address to);

    function setTransferProxy(bytes4 assetType, address proxy)
        external
        onlyAdmin
    {
        require(
            proxy.isContract(),
            "MarketTransfer: Address is not a contract"
        );
        _proxies[assetType] = proxy;
        emit ProxyUpdated(assetType, proxy);
    }

    function getTransferProxy(bytes4 assetType) public view returns (address) {
        return _proxies[assetType];
    }

    function _transfer(
        AssetLib.AssetData memory asset,
        address from,
        address to
    ) internal {
        if (asset.assetType.assetClass == AssetLib.ETH_ASSET_CLASS) {
            _ethTransfer(from, to, asset.value);
        } else if (asset.assetType.assetClass == AssetLib.ERC20_ASSET_CLASS) {
            (address token, ) = AssetLib.decodeAssetTypeData(asset.assetType);
            _erc20safeTransferFrom(token, from, to, asset.value);
        } else if (asset.assetType.assetClass == AssetLib.ERC721_ASSET_CLASS) {
            (address token, uint256 tokenId) = AssetLib.decodeAssetTypeData(
                asset.assetType
            );
            require(asset.value == 1, "MarketTransfer: erc721 value error");
            _erc721safeTransferFrom(token, from, to, tokenId);
        } else if (asset.assetType.assetClass == AssetLib.ERC1155_ASSET_CLASS) {
            (address token, uint256 tokenId) = AssetLib.decodeAssetTypeData(
                asset.assetType
            );
            _erc1155safeTransferFrom(token, from, to, tokenId, asset.value);
        } else {
            _transferProxyTransfer(asset, from, to);
        }
        emit Transferred(asset, from, to);
    }

    function _ethTransfer(
        address from,
        address to,
        uint256 value
    ) private {
        if (from == address(this)) {
            require(
                address(this).balance >= value,
                "MarketTransfer: insufficient balance"
            );
        } else {
            require(msg.value >= value, "MarketTransfer: insufficient balance");
        }
        if (to != address(this)) {
            (bool success, ) = to.call{value: value}("");
            require(
                success,
                "MarketTransfer: unable to send value, recipient may have reverted"
            );
        }
    }

    function _erc20safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        if (from == address(this)) {
            IERC20(token).safeTransfer(to, value);
        } else {
            IERC20(token).safeTransferFrom(from, to, value);
        }
    }

    function _erc721safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) private {
        IERC721(token).safeTransferFrom(from, to, tokenId);
    }

    function _erc1155safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 id,
        uint256 value
    ) private {
        IERC1155(token).safeTransferFrom(from, to, id, value, "");
    }

    function _transferProxyTransfer(
        AssetLib.AssetData memory asset,
        address from,
        address to
    ) private {
        ITransferProxy(getTransferProxy(asset.assetType.assetClass)).transfer(
            asset,
            from,
            to
        );
    }
}
