// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract SimpleContract {

  event LogString(string message);
  
  function broadcastString(string memory message) public {
    emit LogString(message);
  }

}