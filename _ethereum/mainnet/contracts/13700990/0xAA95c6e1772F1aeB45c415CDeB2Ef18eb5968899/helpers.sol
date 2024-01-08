// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./math.sol";
import "./basic.sol";
import "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    ListInterface internal constant listContract =
        ListInterface(0x81572F982F6a3E94119202d5bA1dBeAD1793d352);

    function checkAuthCount() internal view returns (uint256 count) {
        uint64 accountId = listContract.accountID(address(this));
        count = listContract.accountLink(accountId).count;
    }
}
