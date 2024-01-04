// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

interface DarknodePayment {
    function claim(address _darknode) external;
}

contract MultiClaim {
    DarknodePayment darknodePayment;
    
    constructor(DarknodePayment _darknodePayment) {
        darknodePayment = _darknodePayment;
    }
    
    function claim(address[] calldata darknodes) public {
        for (uint8 i = 0; i < darknodes.length; i++) {
            darknodePayment.claim(darknodes[i]);
        }
    }
}