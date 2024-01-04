pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract TokenBase is ERC20, Ownable {

  constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable() {}

  function mint(address to, uint amount) external onlyOwner{
    _mint(to, amount);
  }

  function burn(address owner, uint amount) external onlyOwner{
    _burn(owner, amount);
  }
}