// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ERC20Upgradeable.sol";

contract Duet is Initializable, OwnableUpgradeable, ERC20Upgradeable {
  function initialize() public initializer {
    __Context_init_unchained();
    __Ownable_init_unchained();
    __ERC20_init_unchained("Duet Governance Token", "DUET");
  }

  function mint(address account, uint256 amount) public onlyOwner {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) public onlyOwner {
    _burn(account, amount);
  }

  function burnme(uint256 amount) public {
    _burn(msg.sender, amount);
  }
}