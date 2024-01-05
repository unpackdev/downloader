// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./console.sol";
import "./IERC1155.sol";

contract NFTDisperser {
    function disperse(
        IERC1155 token,
        address[] calldata recipients,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes[] calldata data
    ) external {
        for (uint256 i = 0; i < recipients.length; i++) {
            token.safeTransferFrom(msg.sender, recipients[i], ids[i], amounts[i], data[i]);
        }
    }
}
