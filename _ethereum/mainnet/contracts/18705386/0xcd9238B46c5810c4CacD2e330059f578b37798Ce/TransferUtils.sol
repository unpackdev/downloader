// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.21;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./Constants.sol";
import "./Errors.sol";

error ERC20TransferFailed();
error ERC20FromTransferFailed();
error NativeTransferFailed();
error InvalidERC20Address();

library TransferUtils {
    using SafeERC20 for IERC20;

    function _transfer(address token, address to, uint256 amount) internal {
        if (token == Constants.NATIVE_ADDRESS) {
            _transferETH(to, amount);
        }
        else {
            _transferERC20(token, to, amount);
        }
    }

    function _transferFrom(address token, address from, address to, uint256 amount) internal {
        if (token == Constants.NATIVE_ADDRESS) {
            _transferETH(to, amount);
        }
        else {
            _transferFromERC20(token, from, to, amount);
        }
    }

    function _transferERC20(address token, address to, uint256 amount) internal {
        IERC20 erc20 = IERC20(token);
        if (erc20 == IERC20(address(0))) revert Errors.InvalidTokenAddress();
        uint256 initialBalance = erc20.balanceOf(to);
        erc20.safeTransfer(to, amount);
        uint256 balance = erc20.balanceOf(to);
        if (balance < (initialBalance + amount)) revert Errors.InvalidTokenBalance();
    }

    function _transferFromERC20(address token, address from, address to, uint256 amount) internal {
        IERC20 erc20 = IERC20(token);
        if (erc20 == IERC20(address(0))) revert Errors.InvalidTokenAddress();
        uint256 initialBalance = erc20.balanceOf(to);
        erc20.safeTransferFrom(from, to, amount);
        uint256 balance = erc20.balanceOf(to);
        if (balance < (initialBalance + amount)) revert Errors.InvalidTokenBalance();
    }

    function _transferETH(address to, uint256 amount) internal {
        (bool flag, ) = to.call{value: amount}("");
        if (!flag) revert Errors.NativeTransferFailed();
    }

}