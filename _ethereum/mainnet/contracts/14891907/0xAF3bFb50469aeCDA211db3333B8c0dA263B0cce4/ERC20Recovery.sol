// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./SafeERC20.sol";
import "./Ownable.sol";

abstract contract ERC20Recovery is Ownable {
    using SafeERC20 for IERC20;

    function recoverERC20(IERC20 token) external onlyOwner {
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }
}
