// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Initialisable {
  bool inited = false;

  modifier initialiser() {
    require(!inited, 'already inited');
    _;
    inited = true;
  }
}
