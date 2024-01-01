//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./AccessControlUpgradeable.sol";
import "./ERC20Upgradeable.sol";

contract Credit is AccessControlUpgradeable, ERC20Upgradeable {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  function initialize() initializer public {
    __ERC20_init("Credit", "CR");

    // Ensure deployer is initial admin for minting
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function mintTo(address recipient, uint256 amount) public onlyRole(MINTER_ROLE) {
    _mint(recipient, amount);
  }
}
