// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;

import "./IERC721.sol";

contract BatchERC721Sendoooooor {
    function send(
        address token,
        address[] calldata recipients,
        uint256[] calldata ids
    ) external {
        for (uint256 i = 0; i < recipients.length; i++) {
            IERC721(token).safeTransferFrom(msg.sender, recipients[i], ids[i]);
        }
    }
}
