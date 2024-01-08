//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./AbstractLocker.sol";

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

contract BalanceLocker is AbstractLocker {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function _receiveTokens(
        address _fromAddress,
        uint256 _amount
    ) internal override {
        // transfer in tokens
        IERC20Upgradeable(token).safeTransferFrom(
            address(_fromAddress),
            address(this),
            _amount
        );
    }

    function _sendTokens(
        address _toAddress,
        uint256 _amount
    ) internal override {
        require(IERC20Upgradeable(token).balanceOf(address(this)) > _amount,
            'sendTokens: insufficient funds');
        // transfer out tokens
        IERC20Upgradeable(token).safeTransfer(
            address(_toAddress),
            _amount
        );
    }

}