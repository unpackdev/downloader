// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./IERC721.sol";

contract Sender {
   function transferBatch(address token, address[] memory accounts, uint256[] memory tokenIds) public {
       require(accounts.length == tokenIds.length, "length error");
        for (uint256 i = 0; i < accounts.length; i++) {
            IERC721(token).transferFrom(msg.sender, accounts[i], tokenIds[i]);
        }
    }
}
