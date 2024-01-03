// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

contract LuaMakerTrigger {
    function execute(address target, bytes[] memory data) public {
        for (uint256 i; i < data.length; i++) {
            (bool success,) = target.call(data[i]);
            require(success, "LuaMakerTrigger::executeTransaction: Transaction execution reverted.");
        }
    }
}