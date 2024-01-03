// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "./ERC20PresetMinterPauser.sol";
import "./Initializable.sol";

contract ERC20Token is Initializable, ERC20PresetMinterPauserUpgradeSafe {
  function initialize(string memory name, string memory symbol, uint8 decimals, uint256 initialSupply) public initializer {
    ERC20PresetMinterPauserUpgradeSafe.initialize(name, symbol);

    _setupDecimals(decimals);

    if (initialSupply > 0) {
      _mint(msg.sender, initialSupply);
    }
  }

  function addMinter(address addr) public {
    require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to add a minter");
    _setupRole(MINTER_ROLE, addr);
  }
}