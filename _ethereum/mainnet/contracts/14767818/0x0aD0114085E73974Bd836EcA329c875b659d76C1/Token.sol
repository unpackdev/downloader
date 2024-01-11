// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Token is ERC20, ERC20Burnable, Ownable {
  constructor (string memory _name, string memory _symbol, uint256 _supply ) ERC20(_name, _symbol) {
    _mint(msg.sender, _supply * 10 ** 18);
  }

}

