// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SafeERC20.sol";
import "./Ownable.sol";

contract TokenTransfer is Ownable {
    using SafeERC20 for IERC20;

    constructor() {
    }

    function transferBatchValue(
        address tokenAddress,
        address[] memory tos,
        uint256[] memory amounts
    ) public onlyOwner {
        require(tos.length == amounts.length, "length error");
        IERC20 token = IERC20(tokenAddress);
        for (uint256 i = 0; i < tos.length; i++) {
            token.safeTransferFrom(_msgSender(), tos[i], amounts[i]);
        }
    }

    function transferBatchValue(
        address tokenAddress,
        address[] memory tos,
        uint256 amount
    ) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        for (uint256 i = 0; i < tos.length; i++) {
            token.safeTransferFrom(_msgSender(), tos[i], amount);
        }
    }
}
