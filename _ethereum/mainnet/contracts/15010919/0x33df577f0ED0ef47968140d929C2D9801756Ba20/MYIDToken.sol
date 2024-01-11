// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



import "./ERC20.sol";
import "./Ownable.sol";

contract MYIDToken is ERC20, Ownable {
  constructor() ERC20("MYID", "MYID") {
    _mint(msg.sender, 2000000000 * 1e18);
  }
}