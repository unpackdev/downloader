// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract CheeIZIToken is ERC20, ERC20Burnable {
  address public admin;

  event MinterChanged(address indexed from, address to);

  constructor(string memory _name, string memory _symbol) payable ERC20(_name, _symbol) {
    admin = msg.sender; //only initially
  }

  function passMinterRole(address _contract) public returns (bool) {
    require(msg.sender == admin, "Not admin");
    admin = _contract;

    emit MinterChanged(msg.sender, _contract);
    return true;
  }

  function mint(address account, uint256 amount) public {
    require(msg.sender == admin, "No minting role");
    _mint(account, amount);
  }
}
