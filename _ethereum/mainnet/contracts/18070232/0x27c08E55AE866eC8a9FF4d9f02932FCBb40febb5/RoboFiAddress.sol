// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC165Checker.sol";
import "./SafeERC20.sol";
import "./ITreasuryAsset.sol";
import "./IDABotCertToken.sol";
import "./IDABotGovernToken.sol";

library RoboFiAddress {

    using ERC165Checker for address;
    using SafeERC20 for IERC20;

    function isTreasuryAsset(address account) internal view returns(bool) {
        return account.supportsInterface(type(ITreasuryAsset).interfaceId);
    } 

    function isCertToken(address account) internal view returns(bool) {
        bool res = account.supportsInterface(type(IDABotCertToken).interfaceId);
        if (res)
            return true;
        (bool success, bytes memory result) = 
            account.staticcall(abi.encodeWithSelector(IDABotCertToken.isCertToken.selector));
        if (!success)
            return false;
        (res) = abi.decode(result, (bool));
        return res;
    }

    function isGovernToken(address account) internal view returns(bool) {
        bool res = account.supportsInterface(type(IDABotGovernToken).interfaceId);
        if (res)
            return true;
        (bool success, bytes memory result) = 
            account.staticcall(abi.encodeWithSelector(IDABotGovernToken.isGovernToken.selector));
        if (!success)
            return false;
        (res) = abi.decode(result, (bool));
        return res;
    }

    function safeTransferFrom(IERC20 asset, address from, address to, uint amount) internal {
        if (isNativeAsset(address(asset))) {
            // cannot do this
        } else {
            asset.safeTransferFrom(from, to, amount);
        }
    }

    function safeTransfer(IERC20 asset, address to, uint amount) internal {
        if (isNativeAsset(address(asset))) {
            payable(to).transfer(amount);
        } else {
            asset.safeTransfer(to, amount);
        }
    }

    function isNativeAsset(address asset) internal pure returns(bool) {
        return asset == NATIVE_ASSET_ADDRESS;
    }
}