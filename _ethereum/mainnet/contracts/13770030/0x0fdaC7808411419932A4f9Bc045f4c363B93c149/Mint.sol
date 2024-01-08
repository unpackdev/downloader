// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./Ownable.sol";

contract MintContract is  Ownable {

    constructor() {

    }
    function mint() public payable returns (bool) {
        require(msg.value > 0);
        return true;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}