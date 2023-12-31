// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestContract{

  string public variable;

  function white() public {
    variable = 'white';
  }

  function black() public {
    variable = 'black';
  }
}