// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC721Enumerable.sol";

contract ERC721BulkTransfer {
    function bulkTransferAll(IERC721Enumerable tokenContract, address recipient) external {
        uint256 balance = tokenContract.balanceOf(msg.sender);
        for (uint256 index; index < balance; index++) {
            tokenContract.safeTransferFrom(msg.sender, recipient, tokenContract.tokenOfOwnerByIndex(msg.sender, 0));
        }
    }
}
