// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

contract SilkRoadPayment {
    address payable recipier =
        payable(0x47cEEac21D01547ff1f19d20c1684cAbE0E59DF7);

    function sendToken() external payable {
        (bool success, ) = recipier.call{value: msg.value}("");
        require(success, "Failed to send token");
    }
}