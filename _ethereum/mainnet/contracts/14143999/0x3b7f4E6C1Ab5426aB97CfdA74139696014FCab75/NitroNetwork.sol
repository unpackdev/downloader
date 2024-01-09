// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./ERC20CappedUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";

contract NitroNetwork is
  Initializable,
  ERC20Upgradeable,
  ERC20BurnableUpgradeable,
  ERC20CappedUpgradeable,
  AccessControlUpgradeable
{
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  function initialize() public initializer {
    __ERC20_init("NitroNetwork", "ncash");
    __ERC20Burnable_init();
    __ERC20Capped_init(250 * 10**9 * 10**18);
    __AccessControl_init();
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
  }

  function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
    _mint(to, amount);
  }

  function _mint(address to, uint256 amount)
    internal
    override(ERC20Upgradeable, ERC20CappedUpgradeable)
  {
    super._mint(to, amount);
  }

  function _burn(address account, uint256 amount)
    internal
    override(ERC20Upgradeable)
  {
    super._burn(account, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20Upgradeable) {
    super._beforeTokenTransfer(from, to, amount);
  }
}
