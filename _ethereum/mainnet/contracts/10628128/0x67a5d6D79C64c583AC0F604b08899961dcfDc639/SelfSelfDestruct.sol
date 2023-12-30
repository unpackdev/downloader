//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

contract SelfSelfDestruct {
    event Balance(uint256);
    constructor() public payable {
    }
    
    function kill() external payable {
        emit Balance(address(this).balance);
        address payable _recipient = address(uint160(address(this)));
        selfdestruct(_recipient);
        emit Balance(address(this).balance);
    }
}