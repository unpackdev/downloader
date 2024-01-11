// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.7;
import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract RHNO is ERC20, ERC20Burnable, Ownable {

  mapping(address => bool) controllers;

  uint256 constant public MAX_SUPPLY = 200000000 ether;

  constructor() ERC20("MekaRhinosToken", "RHNO") {
  }

  function mint(address to, uint256 amount) external {
    require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
    require(controllers[msg.sender], "Only controllers can mint");
    _mint(to, amount);
  }

  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }
}