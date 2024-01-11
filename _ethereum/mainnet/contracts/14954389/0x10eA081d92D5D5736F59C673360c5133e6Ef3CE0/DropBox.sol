// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface MistCoinInt {
    function balanceOf(address owner) external returns (uint256 balance);
    function transfer(address to, uint256 value) external;
}

contract DropBox {

    address public wrapAddr;

    MistCoinInt mistContract = MistCoinInt(0xf4eCEd2f682CE333f96f2D8966C613DeD8fC95DD);
    
    constructor(address addr) {
        wrapAddr = addr;
    }

    function deposit(uint256 value) public {
        require(msg.sender == wrapAddr, "Only the wrapper contract has permission to deposit.");

        mistContract.transfer(wrapAddr, value);
    }
}