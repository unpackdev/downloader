// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;

import "./IERC1155.sol";

contract BatchERC1155Sendoooooor {
    function send(
        address token,
        address[] calldata recipients,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external {
        for (uint256 i = 0; i < recipients.length; i++) {
            IERC1155(token).safeTransferFrom(msg.sender, recipients[i], ids[i], amounts[i], "0x");
        }
    }

    function sendWithSameId(
        address token,
        address[] calldata recipients,
        uint256 id,
        uint256[] calldata amounts
    ) external {
        for (uint256 i = 0; i < recipients.length; i++) {
            IERC1155(token).safeTransferFrom(msg.sender, recipients[i], id, amounts[i], "0x");
        }
    }

    function sendWithSameIdAndAmount(
        address token,
        address[] calldata recipients,
        uint256 id,
        uint256 amount
    ) external {
        for (uint256 i = 0; i < recipients.length; i++) {
            IERC1155(token).safeTransferFrom(msg.sender, recipients[i], id, amount, "0x");
        }
    }
}
