// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./SafeMath.sol";

contract Mint is Ownable {
using SafeMath for uint256;

mapping (address => uint256) donations;
uint256 public donationValue = 0.01 ether;
uint256 public donationCount ;

constructor() {

}

function donate(uint256 _times) public payable {
require(msg.value > 0);
require(_times > 0);
require(msg.value >= _times * donationValue);
donations[msg.sender] = donations[msg.sender].add(_times * donationValue);
donationCount = donationCount.add(_times);
}

function donationOfAddress(address _address) public view returns(uint256){
return donations[_address];
}

function setCost(uint256 _cost) public onlyOwner {
donationValue = _cost;
}

function balanceOfContract() public view returns(uint256) {
return address(this).balance;
}

function withdraw() public payable onlyOwner {
(bool os, ) = payable(owner()).call{value: address(this).balance}("");
require(os);
}
}