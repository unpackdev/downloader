// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./SafeMath.sol";
import "./Ownable.sol";

contract YokaiRaffle is Ownable {
    using SafeMath for uint256;

    address public yohContract = 0x88a07dE49B1E97FdfeaCF76b42463453d48C17cD;
    uint256 public ticketPrice = 420 * (10 ** 18);

    uint256 public startTime;
    uint256 public endTime;


    uint256 raffleCount = 0;
    uint256 currentRaffle = 0;

    event JoinEvent(address _acct, uint256 _qty, uint256 _raffleNumber, uint256 _payAmount);

    constructor() {}

    function setTicketPrice(uint256 _price) external onlyOwner {
        ticketPrice = _price;
    }

    function createDrawEvent(uint256 _startTime, uint256 _endTime) external onlyOwner {
        startTime = _startTime;
        endTime = _endTime;
        raffleCount = 0;
        currentRaffle++;
    }

    function changeCurrentRaffles(uint256 _currentRaffle) external onlyOwner {
        currentRaffle = _currentRaffle;
    }

    function withdrawBalance() external onlyOwner {
        uint256 currentBalance = IYohToken(yohContract).balanceOf(address(this));
        IYohToken(yohContract).transfer(msg.sender, currentBalance);
    }

    // purchase tickets
    function joinraffle(uint256 _qty) public returns(bool) {
        require(block.timestamp > startTime, "YokaiRaffle::JoinRaffle: has not started");
        require(block.timestamp < endTime, "YokaiRaffle::JoinRaffle: has already ended");

        uint256 payAmount = ticketPrice * _qty;
        require(IYohToken(yohContract).transferFrom(msg.sender, address(this), payAmount), "YokaiRaffle::JoinRaffle: no funds?");

        raffleCount += _qty;
        emit JoinEvent(msg.sender, _qty, currentRaffle, payAmount);
        return true;
    }

    /*
    function draw(uint256 _winners) external onlyOwner returns (bool) {
        require(block.timestamp > startTime, "YokaiRaffle::Draw: has not started");
        require(block.timestamp > endTime, "YokaiRaffle::Draw: has not ended");

        uint256 seed = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, raffleCount)));

        for(uint256 i = 0; i < _winners; i++){
          uint256 randomWinner = seed % raffleCount - i;
          uint256 currentCount = 0;
          for(uint256 j = 0; j < participants.length; j++){
            currentCount += participants[j].amount;
            if(currentCount > randomWinner){
              emit DrawEvent(address(participants[j].account), totalRaffles);
            }
          }
        }

        uint256 pot = IYohToken(yohContract).balanceOf(address(this));
        IYohToken(yohContract).transfer(owner(), pot);

        return true;
    }
    */
}

interface IYohToken {
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external returns (uint256);
}
