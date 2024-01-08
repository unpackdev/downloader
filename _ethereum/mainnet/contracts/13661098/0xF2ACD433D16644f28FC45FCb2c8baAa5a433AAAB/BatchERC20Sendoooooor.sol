// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;

import "./IERC20.sol";
import "./SafeERC20.sol";

contract BatchERC20Sendoooooor {
    using SafeERC20 for IERC20;

    function send(
        address token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external {
        for (uint256 i = 0; i < recipients.length; i++) {
            IERC20(token).safeTransferFrom(msg.sender, recipients[i], amounts[i]);
        }
    }

    function sendWithSameAmount(
        address token,
        address[] calldata recipients,
        uint256 amount
    ) external {
        for (uint256 i = 0; i < recipients.length; i++) {
            IERC20(token).safeTransferFrom(msg.sender, recipients[i], amount);
        }
    }
}
