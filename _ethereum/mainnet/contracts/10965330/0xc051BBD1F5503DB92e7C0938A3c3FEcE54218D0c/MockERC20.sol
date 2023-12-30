// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
import "./ERC20.sol";

contract MockERC20 is ERC20 {
  constructor() ERC20("TEST", "Test") public {
    _setupDecimals(18);
  }
  function mint(uint256 amount) public returns (uint256) {
    _mint(msg.sender, amount);
    return amount;
   }
  function mintToAnyone(address wallet, uint256 amount) public {
    _mint(wallet, amount);
   }
}
  
