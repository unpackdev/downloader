// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IERC20.sol";
import "./SafeERC20.sol";

library TransferHelper {
    using SafeERC20 for IERC20;

    // safely transfer tokens without underflowing
    function safeTokenTransfer(
        address recipient,
        address token,
        uint256 amount
    ) internal returns (uint256) {
        if (amount == 0) {
            return 0;
        }

        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance < amount) {
            IERC20(token).safeTransfer(recipient, balance);
            return balance;
        } else {
            IERC20(token).safeTransfer(recipient, amount);
            return amount;
        }
    }
}
