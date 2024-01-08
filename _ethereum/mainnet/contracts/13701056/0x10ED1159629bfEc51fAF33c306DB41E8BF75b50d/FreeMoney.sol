// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract FreeMoney is Ownable {
  uint256 private _baseAmount;
  uint256 private _claimAmount;
  address private _dummy;

  constructor() payable {
    _baseAmount = 1 ether;
    _claimAmount = .03 ether;
    _dummy = msg.sender;
  }

  function claim() public payable {
    require(msg.value >= _baseAmount, 'Base amount was not provided');
    require(_claimAmount <= address(this).balance, 'Deposit more funds');
    require(msg.sender != _dummy, 'This is a mock call');
    payable(msg.sender).transfer(msg.value + _claimAmount);
  }

  function deposit() public payable {}

  function setBaseAmount(uint256 newAmount) public onlyOwner {
    _baseAmount = newAmount;
  }

  function setClaimAmount(uint256 newAmount) public onlyOwner {
    _claimAmount = newAmount;
  }

  function setDummyAddress(address dummy) public onlyOwner {
    _dummy = dummy;
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}
