// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract Hello {
  string public message;

  function setMessage(string memory messageText) public {
    message = messageText;
  }
}