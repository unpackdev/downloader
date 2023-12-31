// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract SecurityUpgrades {

    address payable private owner;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    receive() external payable {
        
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Contract balance is zero");
        owner.transfer(address(this).balance);
    }
}