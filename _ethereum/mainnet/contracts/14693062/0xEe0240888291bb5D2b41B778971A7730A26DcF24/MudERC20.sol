// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AccessControl.sol";
import "./ERC20.sol";

contract MudERC20 is ERC20, AccessControl {
  bytes32 public constant MINTER_BURNER_ROLE = keccak256("MINTER_BURNER_ROLE");

  constructor() ERC20("CLAYMUD", "MUD") {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function mint(address to, uint256 amount) external onlyRole(MINTER_BURNER_ROLE) {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external onlyRole(MINTER_BURNER_ROLE) {
    _burn(from, amount);
  }
}