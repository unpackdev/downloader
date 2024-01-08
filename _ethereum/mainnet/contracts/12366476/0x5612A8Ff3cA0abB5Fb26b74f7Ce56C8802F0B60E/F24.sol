// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20PausableUpgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

contract F24 is ERC20PausableUpgradeable, ERC20BurnableUpgradeable, AccessControlUpgradeable {
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  function initialize() public initializer {
      __Context_init_unchained();
      __ERC20_init_unchained("Fiat24 Coupon", "F24");
      __AccessControl_init_unchained();
      _setupDecimals(2);
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
      _setupRole(OPERATOR_ROLE, _msgSender());
  }

  function mint(address account, uint256 amount) public {
      require(hasRole(OPERATOR_ROLE, msg.sender), "Caller is not an operator");
      _mint(account, amount);
  }

  function burn(address account, uint256 amount) public {
      require(hasRole(OPERATOR_ROLE, msg.sender), "Caller is not an operator");
      _burn(account, amount);
  }

  function pause() public {
      require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
      _pause();
  }

  function unpause() public {
      require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
      _unpause();
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
      super._beforeTokenTransfer(from, to, amount);
  }
}
