// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

// OLA Token
//  * NOT mintable
//  * burnable
contract OLAToken is ERC20, ERC20Burnable, Ownable {
  string public _name = "OLA Token";
  string public _symbol = "OLA";

  constructor(uint256 initialSupply) ERC20(_name, _symbol) {
    _mint(msg.sender, initialSupply * 10 ** decimals());
  }

  function burn(uint256 amount) public override {
    require(amount <= totalSupply() / 100, "OLAToken: Amount exceeds one time burn limit");
    _burn(_msgSender(), amount);
  }
}
