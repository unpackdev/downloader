// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC1155.sol";

contract ERC1155Disperse {
    function batchTransfer(address token, address[] memory tos, uint256[] memory ids, uint256[] memory amounts) external {
        require(tos.length == ids.length);
        require(tos.length == amounts.length);

        for (uint i = 0; i < tos.length; i++) {
            IERC1155(token).safeTransferFrom(msg.sender, tos[i], ids[i], amounts[i], "");
        }
    }
}
