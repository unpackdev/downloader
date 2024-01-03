// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./TestToken.sol";

contract MockWETH is TestToken {
  constructor() TestToken("WETH", "WETH", 18) public {}
  function deposit() public {}
  function withdraw(uint256 amount) public {
    _burn(msg.sender, amount);
    msg.sender.transfer(amount);
  }
}
