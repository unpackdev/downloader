// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./LibAsset.sol";
import "./LibTransfer.sol";
import "./ITransferProxy.sol";
import "./ITransferExecutor.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC1155Upgradeable.sol";

abstract contract TransferExecutor is Initializable, OwnableUpgradeable, ITransferExecutor {
    using LibTransfer for address;

    mapping (bytes4 => address) proxies;

    uint256 public maxBundleSize;
    uint256 public maxBatchTransferSize;

    event ProxyChange(bytes4 indexed assetType, address proxy);

    function __TransferExecutor_init_unchained(uint256 _maxBundleSize, uint256 _maxBatchTransferSize) internal {
        maxBundleSize = _maxBundleSize;
        maxBatchTransferSize = _maxBatchTransferSize;
    }

    function setTransferProxy(bytes4 assetType, address proxy) external onlyOwner {
        proxies[assetType] = proxy;
        emit ProxyChange(assetType, proxy);
    }

    function setMaxBundleSize(uint256 _maxBundleSize) external onlyOwner {
        require(_maxBundleSize > 0, "Bundle size should be > 0");
        maxBundleSize = _maxBundleSize;
    }

    function setMaxBatchTransferSize(uint256 _maxBatchTransferSize) external onlyOwner {
        require(_maxBatchTransferSize > 0, "Batch size should be > 0");
        maxBatchTransferSize = _maxBatchTransferSize;
    }

    function erc721BatchTransfer(ERC721Item[] calldata erc721Items, address to) override external {
        require(erc721Items.length <= maxBatchTransferSize, "Cannot transfer more than configured");
        for (uint256 i = 0; i < erc721Items.length; i++) {
            IERC721Upgradeable(erc721Items[i].tokenAddress).safeTransferFrom(msg.sender, to, erc721Items[i].tokenId);
        }
    }

    function transfer(
        LibAsset.Asset memory asset,
        address from,
        address to,
        bytes4 transferDirection,
        bytes4 transferType
    ) internal override {
        if (asset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS) {
            to.transferEth(asset.value);
        } else if (asset.assetType.assetClass == LibAsset.ERC20_ASSET_CLASS) {
            (address token) = abi.decode(asset.assetType.data, (address));
            SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(token), from, to, asset.value);            
        } else if (asset.assetType.assetClass == LibAsset.ERC721_ASSET_CLASS) {
            (address token, uint tokenId) = abi.decode(asset.assetType.data, (address, uint256));
            require(asset.value == 1, "erc721 value error");            
            IERC721Upgradeable(token).safeTransferFrom( from, to, tokenId);
        } else if (asset.assetType.assetClass == LibAsset.ERC1155_ASSET_CLASS) {
            (address token, uint tokenId) = abi.decode(asset.assetType.data, (address, uint256));            
            IERC1155Upgradeable(token).safeTransferFrom(from, to, tokenId, asset.value, "");
        } else if (asset.assetType.assetClass == LibAsset.ERC721_BUNDLE_ASSET_CLASS) {
            (ERC721BundleItem[] memory erc721BundleItems) = abi.decode(asset.assetType.data, (ERC721BundleItem[]));
            require(asset.value > 1 && asset.value <= maxBundleSize, "erc721 value error");            
            for (uint256 i = 0; i < erc721BundleItems.length; i++) {
                for (uint256 j = 0; j < erc721BundleItems[i].tokenIds.length; j++){
                    IERC721Upgradeable(erc721BundleItems[i].tokenAddress).safeTransferFrom(from, to, erc721BundleItems[i].tokenIds[j]);
                } 
            }
        } else {
            ITransferProxy(proxies[asset.assetType.assetClass]).transfer(asset, from, to);
        }
        emit Transfer(asset, from, to, transferDirection, transferType);
    }

}
