// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./ERC777.sol"; // copy of @openzeppelin/contracts/token/ERC777/ERC777.sol 
                               // with minor edit in _mint()
import "./MinterRoles.sol";

contract Token is ERC777, MinterRoles {
  using SafeMath for uint256;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;
  
  constructor(uint256 initialSupply)
      // public
      ERC777("Aureus", "ARS", new address[](0))
      MinterRoles(msg.sender)
  {
      _mint(msg.sender, initialSupply * 10 ** 18, "", "");
  }

  function mint(
    address account,
    uint256 amount,
    bytes memory userData,
    bytes memory operatorData
  ) public virtual onlyMinter {
    _mint(account, amount, userData, operatorData);
  }
}