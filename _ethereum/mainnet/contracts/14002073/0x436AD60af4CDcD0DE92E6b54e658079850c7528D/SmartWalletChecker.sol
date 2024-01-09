//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract SmartWalletChecker is Ownable {
  mapping(address => bool) public check;

  event Set(address indexed addr);
  event Unset(address indexed addr);

  function set(address a) external onlyOwner {
    check[a] = true;
    emit Set(a);
  }

  function unset(address a) external onlyOwner {
    check[a] = false;
    emit Unset(a);
  }
}
