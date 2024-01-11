//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";
// import "./console.sol";

contract Reception is Ownable {
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  event RoomCreated(uint256 roomId);

  struct PlayerStatus{
    uint256 deposits;
    bool withdraw;
  }

  struct Room {
    address player0;
    address player1;
    uint256 baseAmount;
    address winner;
    bool end;
  }

  mapping (uint256 => Room) public rooms;
  mapping (uint256 => mapping(address => PlayerStatus)) players;
  uint256 public roomCounts = 0;
  address public devAddr;
  IERC20 public token;
  uint256 public winnerRate = 80;
  uint256 public devFee = 10;
  uint256 public depositTime = 5 minutes;
  mapping(bytes => uint256) createdRooms;

  constructor(
    address _devAddr,
    address _token
  ) {
    devAddr = _devAddr;
    token = IERC20(_token);
  }

  // owner function
  function setWinnerRate (uint256 _rate) public onlyOwner {
    require(_rate > 50, "Wrong rate!");
    winnerRate = _rate;
  }

  function setDevAddr (address account) public onlyOwner {
    devAddr = account;
  }

  function setDevFee (uint256 _fee) public onlyOwner {
    devFee = _fee;
  }

  function setDepositTime (uint256 _depositTime) public onlyOwner {
    depositTime = _depositTime;
  }

  // withdraw
  function withdraw(uint256 _roomId) public {
    require(_roomId > 0 , "Wrong room number!");
    require(!players[_roomId][msg.sender].withdraw, "You already withdrawn!");
    require(rooms[_roomId].player0 == msg.sender || rooms[_roomId].player1 == msg.sender, "wrong user!");
    if(rooms[_roomId].winner == address(0)) {
      token.transfer(msg.sender, players[_roomId][msg.sender].deposits);
    } else {
      if(rooms[_roomId].winner == msg.sender) {
        token.transfer(msg.sender, players[_roomId][msg.sender].deposits.mul(2).mul(winnerRate).div(100));
      } else {
        token.transfer(msg.sender, players[_roomId][msg.sender].deposits.mul(2).mul(100 - winnerRate).div(100));
      }
    }
    players[_roomId][msg.sender].withdraw = true;
    players[_roomId][msg.sender].deposits = 0;
  }

  // user deposit
  function userDeposit(uint256 _roomId) public {
    require(_roomId > 0, "Invalid room!");
    require(players[_roomId][msg.sender].withdraw, "You must withdraw");
    
    if(rooms[_roomId].winner != address(0)) {
      rooms[_roomId].winner = address(0);
      rooms[_roomId].end = false;
    }
    uint256 realBaseAmount = rooms[_roomId].baseAmount;
    if(devFee > 0) {
      token.transferFrom(msg.sender, devAddr, realBaseAmount.mul(devFee).div(100));
      realBaseAmount -= realBaseAmount.mul(devFee).div(100);
    }
    // deposit token;
    token.transferFrom(msg.sender, address(this), realBaseAmount);
    players[_roomId][msg.sender].deposits = realBaseAmount;
    players[_roomId][msg.sender].withdraw = false;
  }

  function isWithdrawn(uint256 _roomId, address account) public view returns (bool) {
    if ( players[_roomId][account].deposits > 0 && !players[_roomId][account].withdraw) {
      return false;
    }
    return true;
  }

  // check created Room
  function isCreatedRoom (address player0, address player1) public view returns (uint256) {
    (address playerA, address playerB) = player0 < player1 ? (player0, player1) : (player1, player0);
    bytes memory roomBytes = abi.encode(playerA, playerB);
    return createdRooms[roomBytes];
  }
  // room joinable
  function isJoinable (uint256 _roomId) public view returns (bool) {
    return players[_roomId][rooms[_roomId].player0].deposits > 0 && players[_roomId][rooms[_roomId].player1].deposits > 0;
  }
  

  // call by challenger
  function createRoom (address player0, address player1, uint256 baseAmount) public {
    require(player0 != player1, 'IDENTICAL_ADDRESSES');
    (address playerA, address playerB) = player0 < player1 ? (player0, player1) : (player1, player0);
    // roomid
    uint256 roomId = roomCounts + 1;
    // register room
    rooms[roomId].player0 = playerA;
    rooms[roomId].player1 = playerB;
    rooms[roomId].baseAmount = baseAmount;
    // register room
    bytes memory roomBytes = abi.encode(playerA, playerB);
    createdRooms[roomBytes] = roomId;
    players[roomId][playerA].withdraw = true;
    players[roomId][playerB].withdraw = true;
    // console.log(roomId);
    roomCounts++;
    emit RoomCreated(roomId);
  }

  // decide winner
  function decideWinner (uint256 _roomId, address _winner) public onlyOwner {
    require(!players[_roomId][_winner].withdraw, "wrong winner!");
    require(rooms[_roomId].player0 == _winner || rooms[_roomId].player1 == _winner, "wrong winner!");
    rooms[_roomId].winner = _winner;
    rooms[_roomId].end = true;
  }
  function getWinner (uint256 _roomId) public view returns (address) {
    return rooms[_roomId].winner;
  }

  function emergencyWithdraw (address account, uint256 _roomId) public onlyOwner {
    require(rooms[_roomId].player0 == account || rooms[_roomId].player1 == account, "wrong user!");
    require(!players[_roomId][account].withdraw, "You already withdrawn!");
    if(rooms[_roomId].winner == account) {
      token.transfer(devAddr, players[_roomId][account].deposits.mul(2).mul(winnerRate).div(100));
    } else {
      token.transfer(devAddr, players[_roomId][account].deposits.mul(2).mul(100 - winnerRate).div(100));
    }
    players[_roomId][account].withdraw = true;
    players[_roomId][account].deposits = 0;
  }
}