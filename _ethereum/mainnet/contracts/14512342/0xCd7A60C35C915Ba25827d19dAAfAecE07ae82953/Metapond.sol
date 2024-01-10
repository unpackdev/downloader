// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

error Unauthorized();

contract Metapond is ERC20, Ownable, ReentrancyGuard {
  mapping(address => bool) public chancellors;

  modifier onlyChancellors() {
    if (chancellors[msg.sender] == false) {
      revert Unauthorized();
    }
    _;
  }

  constructor() ERC20("Metapond", "M") {
    addChancellor(msg.sender);
  }

  function addChancellor(address _address) public onlyOwner nonReentrant {
    chancellors[_address] = true;
  }

  function revokeChancellor(address _address) public onlyOwner nonReentrant {
    delete chancellors[_address];
  }

  function mint(address _recipient, uint256 _amount) public onlyChancellors nonReentrant {
    _mint(_recipient, _amount);
  }

  function burn(address _from, uint256 _amount) public onlyChancellors nonReentrant {
    _burn(_from, _amount);
  }
}