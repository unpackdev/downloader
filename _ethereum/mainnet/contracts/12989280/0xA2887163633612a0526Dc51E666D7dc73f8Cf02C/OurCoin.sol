// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
import "./Context.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./SafeMath.sol";

contract OurCoin is Context, Ownable, ERC20Burnable {
  constructor(string memory name_, string memory symbol_, uint256 initialSupply_) public ERC20(name_, symbol_) {
    _mint(_msgSender(), initialSupply_);
  }
}
