// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IBEP20.sol";

contract QTokenBulkTransfer {
    function bulkSend(
        address qToken,
        uint amount,
        address[] memory accounts
    ) external {
        require(IBEP20(qToken).balanceOf(address(this)) > 0, "no balance");

        for (uint i = 0; i < accounts.length; i++) {
            IBEP20(qToken).transfer(accounts[i], amount);
        }
    }
}
