// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./SafeMath.sol";
import "./Ownable.sol";

contract YokaiRaffle is Ownable {
  using SafeMath for uint256;

  address public yohContract = 0x88a07dE49B1E97FdfeaCF76b42463453d48C17cD;
  uint public ticketPrice = 420 * (10 ** 18);

  uint public startTime;
  uint public endTime;

  address public creator;
  address[] public participants;
  address[] public winners;

  event JoinEvent(uint _length, uint _qty);
  event DrawEvent(address _winner, uint _prize);

  constructor(address _yoh, uint _price) {
    yohContract = _yoh;
    ticketPrice = _price;
  }

  function setTicketPrice(uint _price) external onlyOwner {
    ticketPrice = _price;
  }

  function createDrawEvent(uint _startTime, uint _endTime) external onlyOwner {
    startTime = _startTime;
    endTime = _endTime;
    delete participants;
  }

  function withdrawBalance() external onlyOwner {
    uint currentBalance = IYohToken(yohContract).balanceOf(address(this));
    IYohToken(yohContract).transfer(msg.sender, currentBalance);
  }

  // purchase tickets
  function joinraffle(uint _qty) public returns(bool) {
    require(block.timestamp > startTime, "YokaiRaffle::JoinRaffle: has not started");
    require(block.timestamp < endTime, "YokaiRaffle::JoinRaffle: has already ended");

    uint payAmount = ticketPrice * _qty;
    require(IYohToken(yohContract).transferFrom(msg.sender, address(this), payAmount), "YokaiRaffle::JoinRaffle: no funds?");


    for (uint i = 0; i < _qty; i++) {
      participants.push(msg.sender);
    }

    emit JoinEvent (participants.length, _qty);

    return true;
  }

  // award prize when all tickets are sold
  function draw() external returns (bool) {
    require(block.timestamp > startTime, "YokaiRaffle::Draw: has not started");
    require(block.timestamp > endTime, "YokaiRaffle::Draw: has not ended");

    uint seed = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants.length)));
    uint random = seed % participants.length;

    winners.push(participants[random]);
    uint pot = IYohToken(yohContract).balanceOf(address(this));
    emit DrawEvent (address(participants[random]), pot);

    return true;
  }
}

interface IYohToken {
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external returns (uint256);
}
