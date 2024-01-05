// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20Upgradeable.sol";
import "./Strings.sol";
import "./OwnableUpgradeable.sol";
import "./pCNFILib.sol";

contract pCNFI is ERC20Upgradeable, OwnableUpgradeable {
  using StringUtils for *;

  function initialize(uint256 cycle) public initializer {
    __ERC20_init_unchained(pCNFILib.toName(cycle), pCNFILib.toSymbol(cycle));
    __Ownable_init_unchained();
  }

  function mint(address target, uint256 amount) public onlyOwner {
    _mint(target, amount);
  }

  function burn(address target, uint256 amount) public onlyOwner {
    _burn(target, amount);
  }
}
