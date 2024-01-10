pragma solidity >=0.8.9 <0.9.0;
//SPDX-License-Identifier: MIT

import "./ERC20.sol";
import "./Ownable.sol";

contract XToken is ERC20, Ownable {

  constructor(address shibaBurner, string memory name, string memory symbol)
  ERC20(name, symbol)
  Ownable()
  {
    transferOwnership(shibaBurner);
  }

  function mint(address account, uint256 amount) external onlyOwner {
    _mint(account, amount);
  }
}

