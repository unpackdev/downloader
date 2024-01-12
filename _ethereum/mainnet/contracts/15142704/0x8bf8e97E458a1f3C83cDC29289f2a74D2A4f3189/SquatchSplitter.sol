// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./PaymentSplitter.sol";

contract SquatchSplitter is PaymentSplitter {

    constructor(address[] memory payees, uint256[] memory shares) PaymentSplitter(payees, shares) {}

    function release() public {
        release(payable(msg.sender));
    }

    function getOwed(address payable account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased();
        return totalReceived * shares(account) / totalShares() - released(account);
    }
}
