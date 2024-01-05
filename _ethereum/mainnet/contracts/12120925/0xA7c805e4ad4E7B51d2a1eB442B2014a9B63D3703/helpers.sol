pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./math.sol";
import "./basic.sol";
import "./interface.sol";

abstract contract Helpers is DSMath, Basic {
    ListInterface internal constant listContract = ListInterface(0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb);

    function checkAuthCount() internal view returns (uint count) {
        uint64 accountId = listContract.accountID(address(this));
        count = listContract.accountLink(accountId).count;
    }
}
