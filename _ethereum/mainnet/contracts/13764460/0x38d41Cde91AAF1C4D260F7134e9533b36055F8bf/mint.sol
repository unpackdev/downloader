// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./SafeMath.sol";

contract MintContract is Ownable {
using SafeMath for uint256;

mapping (address => uint256) mints;
uint256 mintValue = 0.1 ether;
constructor() {

}

function mint(uint256 _times) public payable {
require(msg.value > 0);
require(_times > 0);
require(msg.value >= _times * mintValue);
mints[msg.sender] = mints[msg.sender].add(_times * mintValue);
}

function withdraw() public payable onlyOwner {
(bool os, ) = payable(owner()).call{value: address(this).balance}("");
require(os);
}
}