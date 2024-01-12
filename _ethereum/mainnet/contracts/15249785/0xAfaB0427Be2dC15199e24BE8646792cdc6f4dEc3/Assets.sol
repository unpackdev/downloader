// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Unit Protocol V2: Artem Zakharov (hello@unit.xyz).
 */
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC165Checker.sol";


library Assets {
    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    enum AssetType {Unknown, ERC20, ERC721}

    function getFrom(address _assetAddr, AssetType _assetType, address _from, address _to, uint _idOrAmount) internal {
        if (_assetType == AssetType.ERC20) {
            require(!_assetAddr.supportsInterface(type(IERC721).interfaceId), "UP borrow module: WRONG_ASSET_TYPE");
            IERC20(_assetAddr).safeTransferFrom(_from, _to, _idOrAmount);
        } else if (_assetType == AssetType.ERC721) {
            require(_assetAddr.supportsInterface(type(IERC721).interfaceId), "UP borrow module: WRONG_ASSET_TYPE");
            IERC721(_assetAddr).safeTransferFrom(_from, _to, _idOrAmount);
        } else {
            revert("UP borrow module: UNSUPPORTED_ASSET_TYPE");
        }
    }

    function sendTo(address _assetAddr, AssetType _assetType, address _to, uint _idOrAmount) internal {
        if (_assetType == AssetType.ERC20) {
            require(!_assetAddr.supportsInterface(type(IERC721).interfaceId), "UP borrow module: WRONG_ASSET_TYPE");
            IERC20(_assetAddr).safeTransfer(_to, _idOrAmount);
        } else if (_assetType == AssetType.ERC721) {
            require(_assetAddr.supportsInterface(type(IERC721).interfaceId), "UP borrow module: WRONG_ASSET_TYPE");
            IERC721(_assetAddr).safeTransferFrom(address(this), _to, _idOrAmount);
        } else {
            revert("UP borrow module: UNSUPPORTED_ASSET_TYPE");
        }
    }
}
