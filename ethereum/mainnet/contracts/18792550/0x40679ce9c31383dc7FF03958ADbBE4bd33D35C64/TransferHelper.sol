// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import "./IERC20.sol";
import "./SafeERC20.sol";

library TransferHelper {
    using SafeERC20 for IERC20;

    function _safeTransferFromEnsureExactAmount(
        address token,
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        uint256 oldRecipientBalance = IERC20(token).balanceOf(recipient);
        IERC20(token).safeTransferFrom(sender, recipient, amount);
        uint256 newRecipientBalance = IERC20(token).balanceOf(recipient);
        require(
            newRecipientBalance - oldRecipientBalance == amount,
            "Not enough token was transfered"
        );
    }

    function safeTransfer(
        address token,
        address recipient,
        uint256 amount
    ) internal {
        IERC20(token).safeTransfer(recipient, amount);
    }

    function safeTransferFrom(
        address token,
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        IERC20(token).safeTransferFrom(sender, recipient, amount);
    }
}
