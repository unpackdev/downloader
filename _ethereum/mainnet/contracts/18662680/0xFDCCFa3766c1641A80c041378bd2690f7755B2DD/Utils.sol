// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";

library TransferUtil {
    using SafeERC20 for IERC20;
    function erc20TransferFrom(address token, address from, address to, uint amount) internal {
        if (from == address(this)) {
            IERC20(token).safeTransfer(to, amount);
        }
        else {
            IERC20(token).safeTransferFrom(from, to, amount);
        }
    }

    function erc721Transfer(address token, address to, uint tokenId) internal {
        address owner = IERC721(token).ownerOf(tokenId);
        IERC721(token).safeTransferFrom(owner, to, tokenId);
    }

    function erc20BalanceOf(address token, address account) internal view returns (uint) {
        return IERC20(token).balanceOf(account);
    }
}
