// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

contract TokenUtils {
    using SafeERC20 for IERC20;

    address public constant NATIVE_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function withdrawTokens(
        address token,
        address recipient,
        uint256 amount
    ) internal {
        if (token == NATIVE_ADDRESS) {
            if (amount == type(uint256).max) amount = address(this).balance;
            if (amount == 0) return;
            payable(recipient).transfer(amount);
        } else {
            if (amount == type(uint256).max)
                amount = IERC20(token).balanceOf(address(this));
            if (amount == 0) return;

            IERC20(token).safeTransfer(recipient, amount);
        }
    }
}
